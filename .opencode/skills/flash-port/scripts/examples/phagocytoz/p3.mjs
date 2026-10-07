// Phagocytoz bot + replay: plays a real game with the mouse (the hero swims towards the mouse while the button is
// held): goes for the nearest cell it can eat (10 % smaller), flees the bigger ones (a bigger cell eats the hero),
// releases the button now and then, until the game over (eaten, or shrunk by the timer); then plays the replay and
// compares the end state (MATCH expected).
// usage: node p3.mjs [bot seed] [replay speed] [shots dir]
// env: PORT (DevTools, default 9863; the replay uses PORT + 1), HPORT, EXTRA (url params, test modes), MAXT (bot
//      ticks), LAZY=1 (the bot stops steering after a while: the timer shrinks the hero)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9863)
const MAXT = +(process.env.MAXT || 40000)
let b = await launch(PORT)
let mx = 150, my = 150, mdown = false
const mouse = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + mx * 2, y: 8 + my * 2, button: type === 'mouseMoved' && !mdown ? 'none' : 'left', buttons: mdown ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
// the hero and the cells near it (wrapped positions relative to the hero, map of 1600)
const STATE = `(() => { const g = kk.game; if (!g || !g.cells || !g.hero) return { over: !!window.__over, step: g && g.step ? g.step._hx_index : -1 }
  const h = g.hero, W = 1600, w = (d) => { while (d > W / 2) d -= W; while (d < -W / 2) d += W; return d }
  const cs = []
  for (const c of g.cells) if (c !== h) { const dx = w(c.x - h.x), dy = w(c.y - h.y); if (Math.abs(dx) < 400 && Math.abs(dy) < 400) cs.push([dx, dy, c.ray, c.consume ? 1 : 0, c.vx, c.vy]) }
  return { over: !!window.__over, step: g.step._hx_index, frame: window.__state && window.__state.frame, hr: h.ray, hv: [h.vx, h.vy],
    sc: g.lvl.scale, dead: h.dead, cs, n: g.cells.length } })()`
const stats = { ticks: 0, presses: 0 }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let wander = rnd(8) * Math.PI / 4, pauseT = 0, lazyFrom = process.env.LAZY ? 300 + rnd(400) : 1e9
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 60 === 0) await b.screenshot(shots + '/p' + String(t / 60).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (!s.cs) { await b.sleep(30); continue }
    // forces: towards the nearest edible cell, away from the bigger ones
    let fx = Math.cos(wander) * 0.3, fy = Math.sin(wander) * 0.3
    if (t % 150 === 0) wander += (rnd(3) - 1) * 1.2
    let best = null, bd = 1e9
    for (const [dx, dy, r, cons] of s.cs) {
      const d = Math.hypot(dx, dy) || 1
      const gap = d - r - s.hr
      if (r < s.hr * 0.88) {
        if (gap < bd) { bd = gap; best = [dx, dy] }
      } else if (Math.abs(1 - s.hr / r) >= 0.1) {
        // bigger: run away (more when it hunts)
        const k = (cons ? 6 : 3) * Math.max(0, 1 - gap / (60 + r))
        fx -= dx / d * k; fy -= dy / d * k
      }
    }
    if (best) { const d = Math.hypot(best[0], best[1]) || 1; fx += best[0] / d * 1.5; fy += best[1] / d * 1.5 }
    const a = Math.atan2(fy, fx) + (rnd(7) - 3) * 0.05
    const r = 40 + rnd(80)
    mx = Math.max(1, Math.min(299, 150 + Math.cos(a) * r)); my = Math.max(1, Math.min(299, 150 + Math.sin(a) * r))
    if (pauseT > 0) pauseT--
    else if (rnd(60) === 0) pauseT = 3 + rnd(15)
    const want = pauseT === 0 && t < lazyFrom && Math.hypot(fx, fy) > 0.25
    if (want !== mdown) { mdown = want; if (want) stats.presses++; await mouse(want ? 'mousePressed' : 'mouseReleased') } else await mouse('mouseMoved')
    if (process.env.LOG && t % 50 === 0) console.log(t, JSON.stringify({ f: s.frame, hr: s.hr, n: s.n, sc: s.sc }))
    await b.sleep(15 + rnd(25))
  }
  if (mdown) { mdown = false; await mouse('mouseReleased') }
  await b.waitFor('!!window.__over', 900000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, 'ticks', t, 'presses', stats.presses, 'replay chars', data.length)
  writeFileSync(gameDir('phagocytoz', 'replays') + '/p3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 1)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
