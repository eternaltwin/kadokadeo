// Opalus Factory: a bot plays a whole game with real mouse events (the pointer glides over the roll, hovers groups,
// presses dragged out of their case and released elsewhere now and then, clicks on cases that cannot be played and
// clicks during the moves of the roll; its moves: the biggest group, the goal's colour, the lowest case (towards the
// end) or any case next to the hero), then its replay is played and the end states compared.
// usage: node o3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, HPORT, SEED,
//        MODE=down (mostly the lowest case: short games) | smart (up, nuts, goals: long games), TOUCH=1 (taps on an emulated touch screen), MAXT (actions)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=opalusfactory&cls=GameOpalusFactory&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9871)
const TOUCH = !!process.env.TOUCH
const MODE = process.env.MODE || 'mix'
const MAXT = +(process.env.MAXT || 100000)
const OX = 8, OY = 8   // the canvas in the page
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let px = 300, py = 300
const glide = async (x, y, down = false) => {
  const n = 2 + rnd(5)
  for (let i = 1; i <= n; i++) {
    await mouse('mouseMoved', OX + px + (x - px) * i / n, OY + py + (y - py) * i / n, down)
    await sleep(15 + rnd(40))
  }
  px = x; py = y
}
const tap = async (x, y) => {
  await touch('touchStart', [{ x: OX + x, y: OY + y }])
  await sleep(30 + rnd(90))
  await touch('touchEnd', [])
}
const click = async (x, y) => {
  if (TOUCH) return tap(x, y)
  await glide(x, y)
  await sleep(20 + rnd(80))
  await mouse('mousePressed', OX + x, OY + y, true)
  await sleep(30 + rnd(120))
  await mouse('mouseReleased', OX + x, OY + y, false)
}
// step: 0 Door, 1 Play, 2 Move, 3 Roll, 4 GameOver
const STATE = `(() => { const g = kk.game; if (!g || !g.roll) return null
  const cs = [], all = []
  for (const l of g.roll) for (const c of l.line) {
    if (l.index < 0 || l.index >= g.roll.length) continue
    const p = g.getCasePos(c)
    const it = { x: p.x, y: p.y, id: c.coin ? c.coin.id : -1, n: c.links ? c.links.length : 0, li: l.index }
    if (l.index >= 3 && l.index <= 18) all.push(it)
    if (g.canBePlayed(c)) cs.push(it)
  }
  return { over: !!window.__over, step: g.step._hx_index, goal: g.goal ? g.goal.id : null, left: g.goal ? g.goal.goal - g.goal.count : 0,
    hy: g.heroY, nuts: g.holes[0].count, cs, all } })()`
const stats = { moves: 0, drags: 0, hovers: 0, wrong: 0, busy: 0, big: 0, goal: 0, low: 0 }
let live, data, liveOver, t = 0
try {
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.roll)', 60000)
  let snap = 0
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 10 === 0 && snap < 60) await b.screenshot(shots + '/o' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    if (s.step !== 1 || !s.cs.length) {
      // the roll moves: the pointer wanders, a click now and then (ignored by the game)
      if (rnd(4) === 0 && s.all.length) {
        const o = s.all[rnd(s.all.length)]
        if (rnd(3) === 0) { await click(o.x * 2, o.y * 2); stats.busy++ } else if (!TOUCH) await glide(o.x * 2, o.y * 2)
      }
      await sleep(40)
      continue
    }
    // a click on a case that cannot be played now and then
    if (rnd(8) === 0 && s.all.length) {
      const o = s.all[rnd(s.all.length)]
      await click(o.x * 2 + rnd(9) - 4, o.y * 2 + rnd(9) - 4)
      stats.wrong++
      await sleep(100)
      continue
    }
    let c
    if (MODE === 'smart' && rnd(6)) {
      // the hero climbs, collects nuts (the roll moves less) and completes goals (the roll goes up)
      const sc = (x) => (x.li - s.hy) * 12 + (x.id === 0 ? 14 * x.n : 0) + (x.id === s.goal ? (x.n >= s.left ? 40 : 6 * x.n) : 0) +
        (x.id === -1 && s.nuts > 0 ? 8 : 0) + (x.id === 8 ? 30 : 0) + x.n + rnd(5)
      c = s.cs.slice().sort((a, b) => sc(b) - sc(a))[0]
      stats.smart = (stats.smart || 0) + 1
    }
    const k = MODE === 'down' ? (rnd(5) ? 2 : rnd(4)) : rnd(4)
    if (c) { }
    else if (k === 0) { c = s.cs.slice().sort((a, b) => b.n - a.n)[0]; stats.big++ }
    else if (k === 1 && s.cs.some((x) => x.id === s.goal)) { c = s.cs.filter((x) => x.id === s.goal)[0]; stats.goal++ }
    else if (k === 2) { c = s.cs.slice().sort((a, b) => b.y - a.y)[0]; stats.low++ }
    else c = s.cs[rnd(s.cs.length)]
    const x = c.x * 2 + rnd(13) - 6, y = c.y * 2 + rnd(11) - 5
    if (!TOUCH) {
      // hover another case of the hero first now and then
      if (rnd(3) === 0) { const o = s.cs[rnd(s.cs.length)]; await glide(o.x * 2, o.y * 2); stats.hovers++; await sleep(60 + rnd(200)) }
      if (rnd(6) === 0) {
        // pressed, dragged out of the case and released elsewhere: no move
        await glide(x, y)
        await mouse('mousePressed', OX + x, OY + y, true)
        await sleep(40 + rnd(60))
        await glide(x + 60 + rnd(40), y - 40 - rnd(30), true)
        await mouse('mouseReleased', OX + px, OY + py, false)
        stats.drags++
        await sleep(100)
        continue
      }
    }
    await click(x, y)
    stats.moves++
    await sleep(150)
  }
  if (t >= MAXT) await b.eval('kk.game.heroFall()')
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('opalusfactory', 'replays') + '/o_replay_' + process.argv[2] + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.roll)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
