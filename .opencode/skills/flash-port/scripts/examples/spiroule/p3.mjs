// Spiroule: a bot plays a whole game with real mouse events (the pointer glides to its target and clicks; now and then
// it clicks while no ball is ready, shoots at random or aims elsewhere first), then its replay is played and the end
// states compared. Its shots: the ball of the launcher's colour with the most neighbours of that colour that the shot
// reaches first (the first ball of the chains along the line of fire), the black balls (kicked out), or anywhere.
// usage: node p3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, HPORT, SEED,
//        MODE=good (mostly the best shot: long games) | bad (mostly random: short games) | mix, TOUCH=1 (taps on an
//        emulated touch screen), MAXT (shots)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=spiroule&cls=GameSpiroule&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9971)
const TOUCH = !!process.env.TOUCH
const MODE = process.env.MODE || 'mix'
const MAXT = +(process.env.MAXT || 100000)
const OX = 8, OY = 8   // the canvas in the page
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let px = 300, py = 300
const glide = async (x, y) => {
  const n = 2 + rnd(5)
  for (let i = 1; i <= n; i++) {
    await mouse('mouseMoved', OX + px + (x - px) * i / n, OY + py + (y - py) * i / n, false)
    await sleep(10 + rnd(30))
  }
  px = x; py = y
}
const tap = async (x, y) => {
  await touch('touchStart', [{ x: OX + x, y: OY + y }])
  await sleep(30 + rnd(90))
  await touch('touchEnd', [])
  px = x; py = y
}
const click = async (x, y) => {
  if (TOUCH) return tap(x, y)
  await glide(x, y)
  await sleep(10 + rnd(60))
  await mouse('mousePressed', OX + x, OY + y, true)
  await sleep(30 + rnd(90))
  await mouse('mouseReleased', OX + x, OY + y, false)
}
// the balls of the chains (Flash pixels), the launcher's ball
const STATE = `(() => { const g = kk.game; if (!g || !g.chains) return { over: !!window.__over }
  const out = []
  g.chains.forEach((c, ci) => c.list.forEach((bl, i) => {
    const l = c.list
    out.push({ x: bl.x, y: bl.y, c: bl.col, ci, i, n: (l[i - 1] && l[i - 1].col === bl.col ? 1 : 0) + (l[i + 1] && l[i + 1].col === bl.col ? 1 : 0) +
      (l[i - 2] && l[i - 1] && l[i - 1].col === bl.col && l[i - 2].col === bl.col ? 1 : 0) + (l[i + 2] && l[i + 1] && l[i + 1].col === bl.col && l[i + 2].col === bl.col ? 1 : 0) })
  }))
  const lb = g.launcher.ball
  return { over: !!window.__over, step: g.step._hx_index, col: lb ? lb.col : -1, balls: out } })()`
// the first ball a shot towards (x, y) hits (the launcher at (145, 125), a ball of radius 12 against the balls)
const firstHit = (balls, x, y) => {
  const dx = x - 145, dy = y - 125, L = Math.hypot(dx, dy) || 1
  const ux = dx / L, uy = dy / L
  let best = null, bt = 1e9
  for (const o of balls) {
    if (o.x < -12 || o.x > 312 || o.y < -12 || o.y > 312) continue
    const ox = o.x - 145, oy = o.y - 125
    const t = ox * ux + oy * uy
    if (t < 8) continue
    const d = Math.abs(ox * uy - oy * ux)
    if (d < 24 && t - Math.sqrt(24 * 24 - d * d) < bt) { bt = t - Math.sqrt(24 * 24 - d * d); best = o }
  }
  return best
}
const stats = { aimed: 0, black: 0, random: 0, idle: 0, feint: 0 }
// BURST=<dir>: 5 screenshots after each shot, kept when the game's stats changed (combo, split, join, black)
const BURST = process.env.BURST   // (5 screenshots, the first ones right after the shot)
let burstN = 0
let live, data, liveOver, t = 0
try {
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.chains)', 60000)
  let snap = 0
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (s.step !== 0) { await sleep(100); continue }
    if (shots && t % 5 === 0 && snap < 80) await b.screenshot(shots + '/p' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    const vis = s.balls.filter((o) => o.x > 14 && o.x < 286 && o.y > 14 && o.y < 286)
    if (s.col < 0 || !vis.length) {
      // no ball ready: the pointer wanders, a click now and then (nothing happens)
      if (rnd(3) === 0) { const x = 40 + rnd(520), y = 40 + rnd(520); if (rnd(2)) { await click(x, y); stats.idle++ } else if (!TOUCH) await glide(x, y) }
      await sleep(40)
      continue
    }
    const good = MODE === 'good' ? rnd(10) > 0 : MODE === 'bad' ? rnd(5) === 0 : rnd(3) > 0
    let target = null
    if (good) {
      const reach = vis.filter((o) => { const h = firstHit(s.balls, o.x, o.y); return h && h.ci === o.ci && h.i === o.i })
      const blacks = reach.filter((o) => o.c === 4)
      const same = reach.filter((o) => o.c === s.col).sort((a, b) => b.n - a.n)
      if (blacks.length && rnd(2)) { target = blacks[0]; stats.black++ }
      else if (same.length) { target = same[0]; stats.aimed++ }
    }
    let x, y
    if (target) { x = target.x * 2 + rnd(7) - 3; y = target.y * 2 + rnd(7) - 3 }
    else { x = 20 + rnd(560); y = 20 + rnd(560); stats.random++ }
    if (!TOUCH && rnd(6) === 0) { await glide(20 + rnd(560), 20 + rnd(560)); stats.feint++; await sleep(30 + rnd(100)) }
    await click(x, y)
    if (BURST && burstN < 40) {
      const st0 = await b.eval('JSON.stringify(kk.game.stats)')
      const files = []
      for (let k = 0; k < 5; k++) { const f = BURST + '/b' + String(t).padStart(3, '0') + '_' + k + '.png'; await b.screenshot(f, { x: 8, y: 8, width: 600, height: 600 }); files.push(f); await sleep(40) }
      const st1 = await b.eval('JSON.stringify(kk.game.stats)')
      const a = JSON.parse(st0), c = JSON.parse(st1)
      const keep = ['combos', 'splits', 'joins', 'blackOut', 'blackKick'].filter((k) => c[k] !== a[k])
      if (keep.length) { burstN++; console.log('burst', t, keep.join(',')) } else for (const f of files) (await import('node:fs')).unlinkSync(f)
    }
    await sleep(120 + rnd(250))
  }
  await b.waitFor('!!window.__over', 900000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('spiroule', 'replays') + '/p_replay_' + process.argv[2] + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.chains)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
