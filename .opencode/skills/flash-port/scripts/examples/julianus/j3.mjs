// Julianus: a bot plays a whole game with real mouse and keyboard events, then its replay is played and the end
// states compared. The bot goes behind a bubble (the mouse glides there, or the arrows / WASD keys move the target)
// and blows (mouse button held, or SPACE / Enter): first it keeps the bubbles away from the pics, pushes them
// together and into the bonuses; after ATTACK frames it pushes them into the pics until none
// is left (game over).
// usage: node j3.mjs <rng seed> [replay speed] [shots dir]
// env: EXTRA (url params, e.g. '&test=ju&frames=2000&pcount=60'), PORT (devtools, +50 for the replay), HPORT,
//      ATTACK (frame of the attack phase, default 1600)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=julianus&cls=GameJulianus&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9871)
const ATTACK = +(process.env.ATTACK || 1600)
const OX = 8, OY = 8   // the canvas in the page
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
let down = false
const mouse = (type, x, y) => b.send('Input.dispatchMouseEvent', { type, x: OX + x, y: OY + y, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const KEYS = {
  left: [37, 'ArrowLeft', 'ArrowLeft'], right: [39, 'ArrowRight', 'ArrowRight'], up: [38, 'ArrowUp', 'ArrowUp'], down: [40, 'ArrowDown', 'ArrowDown'],
  a: [65, 'a', 'KeyA'], d: [68, 'd', 'KeyD'], w: [87, 'w', 'KeyW'], s: [83, 's', 'KeyS'],
  space: [32, ' ', 'Space'], enter: [13, 'Enter', 'Enter'],
}
const held = new Set()
const key = async (name, isDown) => {
  if (isDown === held.has(name)) return
  const [c, k, code] = KEYS[name]
  await b.send('Input.dispatchKeyEvent', { type: isDown ? 'keyDown' : 'keyUp', windowsVirtualKeyCode: c, nativeVirtualKeyCode: c, key: k, code })
  if (isDown) held.add(name); else held.delete(name)
}
// the pointer glides to (x, y) (canvas pixels) in a few moves
let px = 300, py = 300
const glide = async (x, y) => {
  x = Math.max(0, Math.min(598, x)); y = Math.max(0, Math.min(598, y))
  const n = 1 + rnd(3)
  for (let i = 1; i <= n; i++) {
    const mx = px + (x - px) * i / n, my = py + (y - py) * i / n
    await mouse('mouseMoved', mx, my)
    await sleep(8 + rnd(15))
  }
  px = x; py = y
}
const STATE = `(() => { const g = kk.game; if (!g || !g.hero || g.hero.px === undefined) return null
  return { over: !!window.__over, f: g.frameCount, cy: g.mc._y, hx: g.hero.px, hy: g.hero.py, tx: g.hero.tx, ty: g.hero.ty,
    bl: g.bulles.map(b => [b.px, b.py, b.size, b.vx, b.vy]), pics: g.pics.map(p => [p.px, p.py, p.id]) } })()`
const stats = { mouse: 0, keys: 0, pressM: 0, pressK: 0, attack: 0, bonus: 0, merge: 0, guard: 0 }
let live, data, liveOver, t = 0
let mode = 'guard', modeT = 0, tgt = null, keyMode = false, keyT = 0, blowKey = null
try {
  await b.goto(URL0)
  await mouse('mouseMoved', 300, 300)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s) { await sleep(30); continue }
    if (s.over) break
    if (shots && t % 25 === 0 && snap < 60) await b.screenshot(shots + '/j' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    // choose what to do now and then
    if (--modeT <= 0 || !s.bl.length) {
      const r = rnd(10)
      mode = s.f > ATTACK ? 'attack' : r < 4 ? 'merge' : r < 6 && s.pics.some(p => p[2] >= 3) ? 'bonus' : 'guard'
      modeT = 20 + rnd(40)
      tgt = s.bl.length ? rnd(s.bl.length) : 0
      // the keyboard steers for a while now and then
      keyMode = rnd(4) === 0
      blowKey = rnd(3) === 0 ? 'enter' : rnd(2) ? 'space' : null
      stats[mode]++
    }
    if (!s.bl.length) { await sleep(30); continue }
    const bb = s.bl[tgt % s.bl.length]
    // where to push the bubble: dir
    let gx, gy
    const pics = s.pics.filter(p => p[0] > -20 && p[0] < 320)
    const near = (arr) => arr.reduce((m, p) => (!m || Math.hypot(p[0] - bb[0], p[1] - bb[1]) < Math.hypot(m[0] - bb[0], m[1] - bb[1])) ? p : m, null)
    if (mode === 'attack') {
      const p = near(pics.filter(p => p[2] < 3)) || near(pics)
      if (p) { gx = p[0]; gy = p[1] } else { gx = bb[0] + 50; gy = bb[1] }
    } else if (mode === 'bonus') {
      const p = near(pics.filter(p => p[2] >= 3))
      if (p) { gx = p[0]; gy = p[1] } else { gx = 150; gy = 120 }
    } else if (mode === 'merge' && s.bl.length > 1) {
      const o = s.bl[(tgt + 1) % s.bl.length]
      gx = o[0]; gy = o[1]
    } else {
      // away from the nearest dangerous pic, towards the middle
      const p = near(pics.filter(p => p[2] < 3))
      if (p && Math.hypot(p[0] - bb[0], p[1] - bb[1]) < 90) { gx = bb[0] * 2 - p[0]; gy = bb[1] * 2 - p[1] } else { gx = 110; gy = 150 }
    }
    let dx = gx - bb[0], dy = gy - bb[1]
    const dl = Math.hypot(dx, dy) || 1
    dx /= dl; dy /= dl
    // stand behind it (world coordinates of the game: the screen is world - camera)
    const back = bb[2] / 2 + 22
    const wx = bb[0] - dx * back, wy = bb[1] - dy * back
    const sx = wx * 2, sy = (wy + s.cy) * 2
    if (keyMode) {
      // the target (tx, ty) moves 4 px per Flash frame with the keys
      const alt = (t >> 4) & 1
      await key(alt ? 'left' : 'a', s.tx > wx + 4); await key(alt ? 'right' : 'd', s.tx < wx - 4)
      await key(alt ? 'up' : 'w', s.ty > wy + 4); await key(alt ? 'down' : 's', s.ty < wy - 4)
      stats.keys++
    } else {
      for (const k of ['left', 'right', 'up', 'down', 'a', 'd', 'w', 's']) await key(k, false)
      await glide(sx + rnd(9) - 4, sy + rnd(9) - 4)
      stats.mouse++
    }
    // blow once close enough (not always: the bubble also floats)
    const close = Math.hypot(s.hx - wx, s.hy - wy) < 18
    const blow = close && rnd(6) !== 0
    if (blowKey) {
      if (down) { down = false; await mouse('mouseReleased', px, py) }
      await key(blowKey, blow); if (blow) stats.pressK++
    } else {
      for (const k of ['space', 'enter']) await key(k, false)
      if (blow !== down) { down = blow; await mouse(blow ? 'mousePressed' : 'mouseReleased', px, py); if (blow) stats.pressM++ }
    }
    await sleep(25 + rnd(25))
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('julianus', 'replays') + '/j_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
