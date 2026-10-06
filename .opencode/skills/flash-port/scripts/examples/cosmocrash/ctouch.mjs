// Cosmo Crash on a touch screen: the round button is up (take off, thrust), the square buttons turn the ship left /
// right; then the replay of that game on a desktop browser must give the same end state (test mode cc: the game ends
// at Flash frame 700).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('cosmocrash', 'check', 'touch')
const URL0 = HOST + '/game.html?game=cosmocrash&cls=GameCosmoCrash&seed=123&test=cc&frames=700'
const PORT = +(process.env.PORT || 9929)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const down = (id) => touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
const up = () => touch('touchEnd', [])
const ST = 'JSON.stringify({ step: kk.game.hero.step, a: kk.game.hero.angle, y: kk.game.hero.y, vy: kk.game.hero.vy, fuel: kk.game.fuel })'
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await b.sleep(300)
  await down('up')
  await b.sleep(600)
  const s0 = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_up.png', { x: 8, y: 8, width: 600, height: 640 })
  await up()
  console.log('up: took off and thrusts', s0.step === 0 && s0.fuel < 100 ? 'OK' : 'FAIL', JSON.stringify(s0))
  for (const [id, sign] of [['left', -1], ['right', 1]]) {
    await b.sleep(250)
    await down(id)
    await b.sleep(220)
    const s = JSON.parse(await b.eval(ST))
    await b.screenshot(out + '/t_' + id + '.png', { x: 8, y: 8, width: 600, height: 640 })
    await up()
    const turned = (s.a + 1.57) * sign
    console.log('button ' + id + ': angle', s.a.toFixed(3), turned > 0.2 ? 'OK' : 'FAIL')
    await b.sleep(200)
    await down('up')
    await b.sleep(250)
    await up()
  }
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
