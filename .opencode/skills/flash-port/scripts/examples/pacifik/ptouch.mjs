// Pacifik on a touch screen: a finger dragged moves the laser without changing its colour, a tap on a corner button
// changes the colour, a long press on it puts the black laser back, a finger put down far away makes the laser jump
// (black: more than 37 pixels in a Flash frame, the original's rule); then the replay of that game on a desktop browser
// must give the same end state.
// usage: HPORT=8811 PORT=9939 node ptouch.mjs
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { mkdirSync } from 'node:fs'
const out = gameDir('pacifik', 'check', 'touch')
mkdirSync(out, { recursive: true })
const URL0 = HOST + '/game.html?game=pacifik&cls=GamePacifik&seed=123&test=pk&frames=500'
const PORT = +(process.env.PORT || 9939)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const L = '(() => { const l = kk.game.laser; return [Math.round(l.mc.x), l.curtype] })()'
const ok = (c) => (c ? 'OK' : 'FAIL')
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser)', 60000)
  await b.sleep(800)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  // a finger down near the laser (x 150), dragged to the right
  await touch('touchStart', [P(300, 300, 1)])
  for (let x = 300; x <= 420; x += 20) { await touch('touchMove', [P(x, 300, 1)]); await b.sleep(40) }
  await b.sleep(200)
  let s = await b.eval(L)
  console.log('drag: laser', s, ok(s[0] === 210 && s[1] === 0))
  await touch('touchEnd', [])
  await b.sleep(150)
  // (separate gestures: CDP's touchEnd lifts every finger, one finger cannot be lifted alone)
  const tap = async (x, ms = 100) => { await touch('touchStart', [P(x, 640 - 10 - 32, 2)]); await b.sleep(ms); await touch('touchEnd', []); await b.sleep(150) }
  // left button (bottom left): next colour
  await tap(10 + 32)
  s = await b.eval(L)
  console.log('tap button L: laser', s, ok(s[0] === 210 && s[1] === 1))
  await tap(600 - 10 - 32)
  s = await b.eval(L)
  console.log('tap button R: laser', s, ok(s[1] === 2))
  await b.screenshot(out + '/t_pink.png', { x: 8, y: 8, width: 600, height: 640 })
  // long press: black
  await tap(600 - 10 - 32, 800)
  s = await b.eval(L)
  console.log('long press: laser', s, ok(s[1] === 0))
  // two taps, then a finger far away: the laser jumps and turns black
  await tap(10 + 32)
  await tap(10 + 32)
  s = await b.eval(L)
  console.log('two taps: laser', s, ok(s[1] === 2))
  await touch('touchStart', [P(120, 200, 1)])
  await b.sleep(200)
  s = await b.eval(L)
  console.log('finger far away: laser', s, ok(s[0] === 60 && s[1] === 0))
  await touch('touchEnd', [])
  await b.screenshot(out + '/t_end.png', { x: 8, y: 8, width: 600, height: 640 })
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 120000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  await b.close()
}
