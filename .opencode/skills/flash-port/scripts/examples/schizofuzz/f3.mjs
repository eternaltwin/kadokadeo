// Schizo Fuzz: a bot plays a whole game with real key presses (Space or Enter to start, charge and launch the
// catapult, then in the air: dives towards the windmills, springboards, acorns and shields, glides over the stumps;
// arrows and their ZQSD-WASD aliases), then its replay is played and the end states compared.
// usage: node f3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, SEED, STUMP (1: dives
//        into the stumps too)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync, mkdirSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=schizofuzz&cls=GameSchizoFuzz&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9620)
const STUMP = process.env.STUMP === '1'
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'], space: [32, ' ', 'Space'] }
const ALT = { left: [65, 'a', 'KeyA'], right: [68, 'd', 'KeyD'], up: [87, 'w', 'KeyW'], down: [83, 's', 'KeyS'], space: [13, 'Enter', 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, k, c]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c || k })
const held = new Map()
const hold = async (name, on) => {
  if (on && !held.has(name)) { const kk = rnd(4) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held.set(name, kk) }
  if (!on && held.has(name)) { await send('keyUp', held.get(name)); held.delete(name) }
}
const tap = async (name, ms) => { await hold(name, true); await b.sleep(ms); await hold(name, false) }
// State: 0 Wait, 1 Start, 2 WaitSpace, 3 WaitFrames, 4 Angle, 5 Run
const STATE = `(() => { const g = kk.game; if (!g || !g.pos) return null
  return { over: !!window.__over, st: g.state._hx_index, x: g.pos.x, y: g.pos.y, dx: g.pos.dx, dy: g.pos.dy, sc: g.scroll,
    speed: g.speed, bonus: g.bonus, it: g.items.filter(o => !o.active).map(o => ({ x: o.mc.get__x(), k: o.k })) } })()`
const stats = { up: 0, down: 0, free: 0, launches: 0 }
let data, liveOver, t = 0
try {
  if (shots) mkdirSync(shots, { recursive: true })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  // start: Space, then charge (held, sometimes until the catapult is full), release, aim, launch
  await b.sleep(300 + rnd(1500))
  await tap('space', 60 + rnd(300))
  await b.sleep(100 + rnd(300))
  await hold('space', true)
  await b.sleep(rnd(3) === 0 ? 2500 : 200 + rnd(1500))
  await hold('space', false)
  await b.sleep(150 + rnd(1500))
  await tap('space', 60 + rnd(200))
  stats.launches++
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % (+process.env.SHOT_EVERY || 25) === 0 && snap < 60) await b.screenshot(shots + '/f' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    let up = false, down = false
    if (s.st === 5) {
      const hx = s.x - s.sc
      const ahead = s.it.map(o => ({ d: o.x - hx, k: o.k })).filter(o => o.d > -10 && o.d < 260).sort((a, c) => a.d - c.d)
      const next = ahead[0]
      // STUMP=1: the stumps are targets too (with or without the shield: coverage of the crash and of the lost shield)
      const good = (k) => k === 0 || k === 2 || k === 5 || (k === 4 && !s.bonus) || (k === 3 && STUMP)
      if (next && next.k === 3 && !STUMP && !s.bonus && s.y > 150) { up = true; stats.up++ }          // a stump: glide over it
      else if (next && good(next.k) && s.y < 255 && next.d < 120 + s.y / 3) { down = true; stats.down++ }
      else if (rnd(6) === 0) { up = rnd(2) === 0; down = !up && rnd(3) === 0; stats.free++ }
    }
    // up: Up or Left, down: Down or Right (the original reads both)
    const ul = rnd(5) === 0 ? 'left' : 'up', dr = rnd(5) === 0 ? 'right' : 'down'
    await hold('up', up && ul === 'up'); await hold('left', up && ul === 'left')
    await hold('down', down && dr === 'down'); await hold('right', down && dr === 'right')
    await b.sleep(20 + rnd(40))
  }
  for (const name of [...held.keys()]) await hold(name, false)
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  mkdirSync(gameDir('schizofuzz', 'replays'), { recursive: true })
  writeFileSync(gameDir('schizofuzz', 'replays') + '/f_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
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
