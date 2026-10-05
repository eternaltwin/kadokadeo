// Paradice on a touch screen: the buttons (bottom left: move the row left / right; bottom right: validate) press the
// keys of the original; then the game goes on by the timer alone until its end, and its replay on a desktop browser
// must give the same end state.
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('paradice', 'check', 'touch')
const URL0 = HOST + '/game.html?game=paradice&cls=GameParadice&seed=123'
const PORT = +(process.env.PORT || 9545)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const BTN = { left: [52, 584], right: [140, 584], up: [536, 576] }
const ST = 'JSON.stringify({dx: kk.game.ground.dx, play: kk.game.play, step: kk.game.step, gstep: kk.game.ground.step})'
const ready = () => b.waitFor('kk.game.step == 3 && kk.game.ground.step == 0', 20000)
const tap = async (name, ms, check) => {
  await ready()
  const s0 = JSON.parse(await b.eval(ST))
  await touch('touchStart', [P(BTN[name][0], BTN[name][1], 1)])
  await b.sleep(ms)
  await touch('touchEnd', [])
  await b.sleep(500)
  await b.screenshot(out + '/t_' + name + '.png', { x: 8, y: 8, width: 600, height: 640 })
  const s1 = JSON.parse(await b.eval(ST))
  console.log(name.padEnd(6), JSON.stringify(s0), '->', JSON.stringify(s1), check(s0, s1) ? 'OK' : 'FAIL')
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.ground)', 60000)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  await tap('right', 120, (a, c) => c.dx === (a.dx + 1) % 10)
  await tap('left', 120, (a, c) => c.dx === (a.dx + 9) % 10)
  await tap('left', 120, (a, c) => c.dx === (a.dx + 9) % 10)
  await tap('up', 120, (a, c) => c.play > a.play || c.step !== 3 || c.gstep !== 0)
  await tap('right', 400, (a, c) => (c.dx - a.dx + 10) % 10 >= 2)
  await tap('up', 120, (a, c) => c.play > a.play || c.step !== 3 || c.gstep !== 0)
  await b.waitFor('!!window.__over', 400000)
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
  await b.waitFor('!!(window.kk && kk.game && kk.game.ground)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
