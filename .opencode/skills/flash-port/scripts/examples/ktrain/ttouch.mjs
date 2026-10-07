// K-Train on a touch screen: ▲ / ▼ change the speed asked (taps: the key presses of the original's listener), ■ brakes,
// ◀ / ▶ send the driver out, then the arrows walk him; then the replay of that game on a desktop browser must give the
// same end state (test mode kt: the game ends at Flash frame 900).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('ktrain', 'check', 'touch')
const URL0 = HOST + '/game.html?game=ktrain&cls=GameKTrain&seed=123&test=kt&frames=900'
const PORT = +(process.env.PORT || 9896)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const down = (id) => touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
const up = () => touch('touchEnd', [])
const tapB = async (id) => { await down(id); await b.sleep(90); await up(); await b.sleep(150) }
const ST = 'JSON.stringify(kk.game.debugBot())'
const st = async () => JSON.parse(await b.eval(ST))
const check = (name, ok, s) => console.log(name, ok ? 'OK' : 'FAIL', JSON.stringify({ step: s.step, speed: s.speed, out: s.out, mx: s.mx, my: s.my }))
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await b.sleep(300)
  await tapB('up')
  await tapB('up')
  let s = await st()
  check('up x2: step 3', s.step === 3, s)
  await tapB('down')
  s = await st()
  check('down: step 2', s.step === 2, s)
  await b.screenshot(out + '/t_speed.png', { x: 8, y: 8, width: 600, height: 640 })
  await down('brake')
  for (let i = 0; i < 200 && (await st()).speed > 0; i++) await b.sleep(30)
  s = await st()
  await up()
  check('brake: stopped', s.speed === 0 && s.step === 0, s)
  await b.sleep(200)
  await tapB('left')
  s = await st()
  check('left: the driver is out', s.out && s.mx < 150, s)
  const y0 = s.my
  await down('down')
  await b.sleep(400)
  await up()
  s = await st()
  await b.screenshot(out + '/t_walk.png', { x: 8, y: 8, width: 600, height: 640 })
  check('down: he walks down', s.my > y0, s)
  // back into the locomotive: right, then up to its cabin
  await down('right'); await b.sleep(350); await up()
  await down('up'); await b.sleep(400); await up()
  s = await st()
  check('back in the locomotive', !s.out, s)
  await b.waitFor('!!window.__over', 300000)
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
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
