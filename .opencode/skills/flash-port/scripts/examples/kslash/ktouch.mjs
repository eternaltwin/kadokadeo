// K-Slash on a touch screen: floating joystick (left half), jump button, shuriken button; then the replay of that
// game on a desktop browser must give the same end state.
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { mkdirSync } from 'node:fs'
const out = gameDir('kslash', 'check', 'touch')
mkdirSync(out, { recursive: true })
const URL0 = HOST + '/game.html?game=kslash&cls=GameKSlash&seed=123&test=ks&frames=900&inv=1'
const PORT = +(process.env.PORT || 9545)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const HX = 'kk.game.hero.root.get__x()', HY = 'kk.game.hero.root.get__y()'
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.sleep(1500)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  await b.eval(`(() => { const P = Object.getPrototypeOf(kk.game.hero); const o = P.shoot; window.__shots = 0; P.shoot = function () { window.__shots++; return o.call(this) } })()`)
  const x0 = await b.eval(HX)
  // joystick: thumb down on the left half, then pushed to the right
  await touch('touchStart', [P(110, 450, 1)])
  await b.sleep(80)
  await touch('touchMove', [P(170, 452, 1)])
  await b.sleep(700)
  const x1 = await b.eval(HX)
  console.log('joystick right: hero x', Math.round(x0), '->', Math.round(x1), x1 > x0 + 30 ? 'OK' : 'FAIL')
  await b.screenshot(out + '/t_joy.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  await b.sleep(300)
  // jump button
  const y0 = await b.eval(HY)
  await touch('touchStart', [P(600 - 112 - 36, 640 - 44 - 36, 2)])
  await b.sleep(250)
  const y1 = await b.eval(HY)
  console.log('jump button: hero y', Math.round(y0), '->', Math.round(y1), y1 < y0 - 10 ? 'OK' : 'FAIL')
  await b.screenshot(out + '/t_jump.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  await b.sleep(800)
  // joystick to the left
  const x2 = await b.eval(HX)
  await touch('touchStart', [P(150, 450, 1)])
  await b.sleep(80)
  await touch('touchMove', [P(80, 452, 1)])
  await b.sleep(600)
  const x3 = await b.eval(HX)
  console.log('joystick left: hero x', Math.round(x2), '->', Math.round(x3), x3 < x2 - 20 ? 'OK' : 'FAIL')
  await touch('touchEnd', [])
  // shuriken button: 3 taps
  for (let i = 0; i < 3; i++) {
    await touch('touchStart', [P(600 - 14 - 42, 640 - 14 - 42, 3)])
    await b.sleep(100)
    await touch('touchEnd', [])
    await b.sleep(250)
  }
  const sh = await b.eval('window.__shots')
  console.log('shuriken button: shots', sh, sh === 3 ? 'OK' : 'FAIL')
  // joystick down: through the platform
  const y2 = await b.eval('kk.game.hero.y')
  await touch('touchStart', [P(110, 450, 1)])
  await b.sleep(80)
  await touch('touchMove', [P(110, 530, 1)])
  await b.sleep(500)
  await touch('touchEnd', [])
  const y3 = await b.eval('kk.game.hero.y')
  console.log('joystick down: hero square y', y2, '->', y3, y3 > y2 ? 'OK' : '(no platform below?)')
  await b.screenshot(out + '/t_end.png', { x: 8, y: 8, width: 600, height: 640 })
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, 'replay chars', data.length)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
// replay on a desktop browser (no touch)
b = await launch(PORT)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
