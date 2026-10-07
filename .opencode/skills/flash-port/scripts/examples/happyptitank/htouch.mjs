// Happy Pti Tank on a touch screen: a finger on the left half is a floating joystick (the arrows: the tank drives),
// a second finger on the right half is the mouse (the target follows it, the tank fires while it stays); then the
// replay of that game on a desktop browser must give the same end state (test mode ht: the tank destroyed at frame N).
// usage: node htouch.mjs      env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('happyptitank', 'check', 'touch')
const URL0 = HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123&test=ht&frames=500'
const PORT = +(process.env.PORT || 9936)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map((p) => ({ radiusX: 4, radiusY: 4, force: 1, ...p })) })
const ST = `(() => { const g = kk.game, t = g.tank; let n = 0; for (let s = g.shots.h; s; s = s.next) n++
  return JSON.stringify({ x: t.get_x(), y: t.get_y(), shots: n, tgx: g.target.get_x(), tgy: g.target.get_y(), fired: JSON.parse(window.__state.stats).shots }) })()`
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  const r = JSON.parse(await b.eval(`JSON.stringify(document.getElementById('c').getBoundingClientRect())`))
  // (page pixels of a point of the 300 x 300 stage)
  const P = (x, y) => ({ x: r.left + x * r.width / 300, y: r.top + y * r.width / 300 })
  await b.sleep(300)
  const s0 = JSON.parse(await b.eval(ST))
  // joystick: down at (60, 200), dragged right
  const j0 = P(60, 200), j1 = P(100, 200)
  await touch('touchStart', [{ ...j0, id: 1 }])
  await b.sleep(80)
  await touch('touchMove', [{ ...j1, id: 1 }])
  await b.sleep(900)
  const s1 = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_joy.png', { x: 8, y: 8, width: 600, height: 640 })
  console.log('joystick right: the tank drove', s1.x - s0.x > 20 ? 'OK' : 'FAIL', (s1.x - s0.x).toFixed(1))
  // second finger: aims at (230, 70) and fires
  const f = P(230, 70)
  await touch('touchMove', [{ ...j1, id: 1 }, { ...f, id: 2 }])
  await touch('touchStart', [{ ...j1, id: 1 }, { ...f, id: 2 }])
  await b.sleep(900)
  const s2 = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_fire.png', { x: 8, y: 8, width: 600, height: 640 })
  console.log('finger on the right: target', s2.tgx.toFixed(0), s2.tgy.toFixed(0), Math.abs(s2.tgx - 230) < 6 && Math.abs(s2.tgy - 70) < 6 ? 'OK' : 'FAIL',
    'fired', s2.fired - s1.fired, s2.fired - s1.fired > 0 ? 'OK' : 'FAIL')
  // the joystick released, the finger stays: the tank stops, still firing
  await touch('touchEnd', [{ ...f, id: 2 }])
  await b.sleep(700)
  const s3 = JSON.parse(await b.eval(ST))
  console.log('joystick released, firing', s3.fired - s2.fired > 0 ? 'OK' : 'FAIL')
  await touch('touchEnd', [])
  await b.sleep(400)
  const s4 = JSON.parse(await b.eval(ST))
  await b.sleep(700)
  const s5 = JSON.parse(await b.eval(ST))
  console.log('all fingers up: no more shots', s5.fired === s4.fired ? 'OK' : 'FAIL')
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
