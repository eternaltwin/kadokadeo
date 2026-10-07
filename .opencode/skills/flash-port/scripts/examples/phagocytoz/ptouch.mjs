// Phagocytoz on a touch screen: no touch controls, a finger is the mouse (the hero swims towards it while it stays on
// the screen, the arrow points at it); then the replay of that game on a desktop browser must give the same end state
// (test mode ph: the hero is not eaten and dies at frame N).
// usage: node ptouch.mjs      env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('phagocytoz', 'check', 'touch')
const URL0 = HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123&test=ph&inv=1&frames=400'
const PORT = +(process.env.PORT || 9880)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map((p) => ({ radiusX: 4, radiusY: 4, force: 1, ...p })) })
const ST = `(() => { const g = kk.game, h = g.hero; if (!h) return 'null'
  return JSON.stringify({ x: h.x, y: h.y, vx: h.vx, vy: h.vy, click: g.click, step: g.step._hx_index }) })()`
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero && kk.game.step._hx_index === 0)', 60000)
  const r = JSON.parse(await b.eval(`JSON.stringify(document.getElementById('c').getBoundingClientRect())`))
  // (page pixels of a point of the 300 x 300 stage)
  const P = (x, y) => ({ x: r.left + x * r.width / 300, y: r.top + y * r.width / 300 })
  await b.sleep(300)
  const s0 = JSON.parse(await b.eval(ST))
  // a finger on the right of the hero: it swims right
  await touch('touchStart', [{ ...P(260, 150), id: 1 }])
  await b.sleep(900)
  const s1 = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_right.png', { x: 8, y: 8, width: 600, height: 640 })
  console.log('finger right: pressed', s1.click ? 'OK' : 'FAIL', 'vx', s1.vx.toFixed(2), s1.vx > 0.5 ? 'OK' : 'FAIL')
  // dragged above the hero: it turns up
  await touch('touchMove', [{ ...P(150, 30), id: 1 }])
  await b.sleep(900)
  const s2 = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_up.png', { x: 8, y: 8, width: 600, height: 640 })
  console.log('finger dragged up: vy', s2.vy.toFixed(2), s2.vy < -0.5 ? 'OK' : 'FAIL')
  // lifted: the push stops (MOUSE_UP over the game)
  await touch('touchEnd', [])
  await b.sleep(500)
  const s3 = JSON.parse(await b.eval(ST))
  console.log('finger lifted: released', !s3.click ? 'OK' : 'FAIL')
  // a tap on the left
  await touch('touchStart', [{ ...P(40, 150), id: 2 }])
  await b.sleep(600)
  await touch('touchEnd', [])
  const s4 = JSON.parse(await b.eval(ST))
  console.log('tap left: vx', s4.vx.toFixed(2), s4.vx < s3.vx ? 'OK' : 'FAIL')
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
