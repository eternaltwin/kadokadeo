// Happy Pti Tank bot + replay: plays a real game with key events (arrows, sometimes the ZQSD / WASD aliases) and
// the mouse (aims at the nearest enemy, holds the button to fire, releases it now and then): drives away from the
// centre to cross the circles, picks the options, dodges the enemies, their shots and the falling missiles, until the
// game over (armor or time); then plays the replay and compares the end state (MATCH expected).
// usage: node h3.mjs [bot seed] [replay speed] [shots dir]
// env: PORT (DevTools, default 9933; the replay uses PORT + 1), HPORT, EXTRA (url params, test modes), MAXT (bot ticks)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9933)
const MAXT = +(process.env.MAXT || 20000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'] }
// (physical keys: ZQSD on AZERTY = WASD on QWERTY)
const ALT = { left: [65, 'KeyA'], up: [87, 'KeyW'], right: [68, 'KeyD'], down: [83, 'KeyS'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = {}
const set = async (name, on) => {
  if (on && !held[name]) { const kk = rnd(6) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held[name] = kk }
  else if (!on && held[name]) { await send('keyUp', held[name]); held[name] = null }
}
let mx = 150, my = 150, mdown = false
const mouse = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + mx * 2, y: 8 + my * 2, button: type === 'mouseMoved' && !mdown ? 'none' : 'left', buttons: mdown ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
// the state the bot reads (game coordinates: the game layer; screen = game + layer)
const STATE = `(() => { const g = kk.game; if (!g || !g.tank) return null
  const L = (l, f) => { const out = []; for (let n = l.h; n; n = n.next) out.push(f(n.item)); return out }
  const p = (o) => [o.get_x(), o.get_y()]
  return { over: !!window.__over, frame: window.__state && window.__state.frame, t: p(g.tank), ta: g.tank.angle,
    lx: g.gameLayer.get_x(), ly: g.gameLayer.get_y(), zone: g.warZone.visible,
    z: g.warZone.visible ? [g.warZone.minX, g.warZone.maxX, g.warZone.minY, g.warZone.maxY] : null,
    foes: L(g.foes, p), es: L(g.foesShots, p), mines: L(g.foesMines, p),
    ms: L(g.missiles, (m) => [m.cross.get_x(), m.cross.get_y(), m.state ? m.state._hx_index : 0]),
    opts: L(g.options, p), armor: window.__state.armor } })()`
const clamp = (v, a, c) => Math.max(a, Math.min(c, v))
const stats = { ticks: 0, alias: 0 }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let heading = rnd(8) * Math.PI / 4, fireOff = 0
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 80 === 0) await b.screenshot(shots + '/h' + String(t / 80).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    const [tx, ty] = s.t
    // forces: away from the centre (circles), towards options, away from dangers, inside the zone
    let fx = Math.cos(heading) * 0.6, fy = Math.sin(heading) * 0.6
    if (!s.zone && t % 200 === 0) heading = Math.atan2(ty, tx) + (rnd(3) - 1) * 0.7
    const push = (x, y, k, r) => { const dx = tx - x, dy = ty - y, d = Math.hypot(dx, dy) || 1; if (d < r) { fx += dx / d * k * (r - d) / r; fy += dy / d * k * (r - d) / r } }
    for (const [x, y] of s.foes) push(x, y, 3, 90)
    for (const [x, y] of s.es) push(x, y, 2, 45)
    for (const [x, y] of s.mines) push(x, y, 2, 40)
    for (const [x, y, st] of s.ms) if (st <= 1) push(x, y, 4, 60)
    for (const [x, y] of s.opts) { const dx = x - tx, dy = y - ty, d = Math.hypot(dx, dy) || 1; if (d < 220) { fx += dx / d * 1.5; fy += dy / d * 1.5 } }
    if (s.z) {
      const [x0, x1, y0, y1] = s.z
      if (tx < x0 + 60) fx += 1.5; if (tx > x1 - 60) fx -= 1.5
      if (ty < y0 + 60) fy += 1.5; if (ty > y1 - 60) fy -= 1.5
      if (s.foes.length === 0 && t % 120 === 0) heading = rnd(8) * Math.PI / 4
    }
    const a = Math.atan2(fy, fx), m = Math.hypot(fx, fy)
    const sec = Math.round(a / (Math.PI / 4))   // 8 directions
    const dirs = m < 0.2 ? [] : [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]][((sec % 8) + 8) % 8]
    await set('right', dirs[0] === 1); await set('left', dirs[0] === -1)
    await set('down', dirs[1] === 1); await set('up', dirs[1] === -1)
    // aim: the nearest enemy (its position on the screen), else ahead
    let best = null, bd = 1e9
    for (const [x, y] of s.foes) { const d = Math.hypot(x - tx, y - ty); if (d < bd) { bd = d; best = [x, y] } }
    const [ax, ay] = best ? best : [tx + Math.cos(s.ta) * 80, ty + Math.sin(s.ta) * 80]
    mx = clamp(ax + s.lx + (rnd(9) - 4), 0, 299); my = clamp(ay + s.ly + (rnd(9) - 4), 0, 299)
    if (fireOff > 0) fireOff--
    else if (rnd(40) === 0) fireOff = 5 + rnd(20)
    const want = fireOff === 0
    if (want !== mdown) { mdown = want; await mouse(want ? 'mousePressed' : 'mouseReleased') } else await mouse('mouseMoved')
    if (process.env.LOG && t % 50 === 0) console.log(t, JSON.stringify({ f: s.frame, t: s.t, zone: s.zone, foes: s.foes.length, armor: s.armor }))
    await b.sleep(15 + rnd(25))
  }
  for (const k of Object.keys(K)) await set(k, false)
  if (mdown) { mdown = false; await mouse('mouseReleased') }
  await b.waitFor('!!window.__over', 600000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('happyptitank', 'replays') + '/h3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
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
