// Linea on a touch screen: the floating joystick (left half) moves the lines up, down, right and left (8 directions);
// then the replay of that game on a desktop browser must give the same end state.
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('linea', 'check', 'touch')
const URL0 = HOST + '/game.html?game=linea&cls=GameLinea&seed=123'
const PORT = +(process.env.PORT || 9545)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const HEAD = 'JSON.stringify((d => [d.x, d.y])(kk.game.dotter.dots[0]))'
const stick = async (name, dx, dy, ms, check) => {
  const [x0, y0] = JSON.parse(await b.eval(HEAD))
  await touch('touchStart', [P(150, 420, 1)])
  await b.sleep(60)
  await touch('touchMove', [P(150 + dx, 420 + dy, 1)])
  await b.sleep(ms)
  const [x1, y1] = JSON.parse(await b.eval(HEAD))
  await b.screenshot(out + '/t_' + name + '.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  console.log('joystick ' + name + ': head', [x0, y0], '->', [x1, y1], check(x1 - x0, y1 - y0) ? 'OK' : 'FAIL')
  await b.sleep(150)
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.step == 2)', 60000)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  await stick('up', 0, -70, 350, (dx, dy) => dy < -15)
  await stick('down', 0, 70, 350, (dx, dy) => dy > 15)
  await stick('right', 70, 0, 300, (dx, dy) => dx > 10)
  await stick('left', -70, 0, 300, (dx, dy) => dx < -10)
  // a diagonal: Dotter.moveDot only moves x on a purely horizontal step (like the original): the lines go up
  await stick('up-right', 60, -60, 300, (dx, dy) => dx == 0 && dy < -10)
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
  await b.waitFor('!!(window.kk && kk.game && kk.game.dotter)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
