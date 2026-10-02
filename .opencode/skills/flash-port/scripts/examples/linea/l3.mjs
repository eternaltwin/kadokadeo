// Linea: a bot plays a whole game with real key presses (up / down to dodge the squares and catch the line bonuses
// and stars, left / right now and then, the aliases ZQSD-WASD too), then its replay is played and the end states
// compared.
// usage: node l3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, MAXT (actions before
//        the bot stops dodging), SEED
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=linea&cls=GameLinea&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9610)
const MAXT = +(process.env.MAXT || 1500)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'] }
const ALT = { left: [81, 'KeyA'], right: [68, 'KeyD'], up: [87, 'KeyW'], down: [83, 'KeyS'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = new Map()
const hold = async (name, on) => {
  if (on && !held.has(name)) { const kk = rnd(4) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held.set(name, kk) }
  if (!on && held.has(name)) { await send('keyUp', held.get(name)); held.delete(name) }
}
const STATE = `(() => { const g = kk.game; if (!g || !g.dotter) return null
  const d = g.dotter.dots.filter(d => d.started); if (!d.length) return { over: !!window.__over, dead: true }
  const f = d[0], ys = d.map(x => x.y)
  return { over: !!window.__over, x: f.x, top: Math.min(...ys), bot: Math.max(...ys), n: d.length, step: g.step,
    obj: g.objects.filter(o => o).map(o => ({ x: o.x, y: o.y, w: o.get__width(), h: o.get__height(), line: o.line })),
    bon: g.abonus.filter(o => o && !o.hit).map(o => ({ x: o.x, y: o.y })) } })()`
const stats = { up: 0, down: 0, left: 0, right: 0, aims: 0 }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.dotter)', 60000)
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % (+process.env.SHOT_EVERY || 40) === 0 && snap < 40) await b.screenshot(shots + '/l' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    let vy = 0
    if (!s.dead && t < MAXT) {
      // a line bonus or stars ahead: go for them; a square ahead on the way: dodge it
      const mid = (s.top + s.bot) / 2
      const aim = [...s.obj.filter(o => o.line).map(o => ({ x: o.x, y: o.y })), ...s.bon.map(o => ({ x: o.x, y: o.y + 18 }))]
        .filter(o => o.x > s.x && o.x - s.x < 140).sort((a, c) => a.x - c.x)[0]
      let target = aim ? aim.y : null
      if (aim) stats.aims++
      for (const o of s.obj) {
        if (o.line || o.x + o.w < s.x - 4 || o.x - s.x > 130) continue
        if (s.bot + 6 > o.y && s.top - 6 < o.y + o.h) target = (o.y + o.h / 2 > mid && o.y > 60) || o.y + o.h > 270 ? o.y - 20 - (s.bot - s.top) : o.y + o.h + 20
      }
      if (target === null && rnd(30) === 0) target = 40 + rnd(220)
      if (target !== null) vy = target > mid + 4 ? 1 : target < mid - 4 ? -1 : 0
    }
    if (vy < 0 && !held.has('up')) stats.up++
    if (vy > 0 && !held.has('down')) stats.down++
    await hold('up', vy < 0)
    await hold('down', vy > 0)
    // left / right now and then, mostly while moving up or down (a diagonal resets the anti-camping counter)
    const hx = rnd(vy !== 0 ? 6 : 40) === 0 ? (s.x > 120 ? 'left' : s.x < 60 ? 'right' : rnd(2) ? 'left' : 'right') : null
    if (hx) { stats[hx]++; await hold(hx, true); await b.sleep(30 + rnd(120)); await hold(hx, false) }
    await b.sleep(10 + rnd(20))
  }
  for (const name of [...held.keys()]) await hold(name, false)
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('linea', 'replays') + '/l_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.dotter)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
