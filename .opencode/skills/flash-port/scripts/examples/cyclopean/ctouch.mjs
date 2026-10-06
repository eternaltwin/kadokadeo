// Cyclopean on a touch screen: the two arrow buttons (bottom left / bottom right) turn the cave; then the replay of
// that game on a desktop browser must give the same end state. A short game: test=cy&time=300.
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('cyclopean', 'check', 'touch')
const URL0 = HOST + '/game.html?game=cyclopean&cls=GameCyclopean&seed=123&test=cy&time=300'
const PORT = +(process.env.PORT || 9877)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const press = async (name, x, ms, check) => {
  const a0 = await b.eval('kk.game.angle')
  await touch('touchStart', [P(x, 580, 1)])
  await b.sleep(ms)
  const a1 = await b.eval('kk.game.angle')
  await b.screenshot(out + '/t_' + name + '.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  // (the angle of the cave is kept in -PI..PI)
  let d = a1 - a0
  while (d > Math.PI) d -= 2 * Math.PI
  while (d < -Math.PI) d += 2 * Math.PI
  console.log('button ' + name + ': angle', a0.toFixed(3), '->', a1.toFixed(3), check(d) ? 'OK' : 'FAIL')
  await b.sleep(400)
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.step == 1)', 60000)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  await press('left', 60, 400, (d) => d < -0.1)
  await press('right', 540, 400, (d) => d > 0.1)
  await press('left2', 60, 250, (d) => d < -0.05)
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
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
