// Schizo Fuzz on a touch screen: the round button is Space (start, charge, launch), the square buttons up / down
// steer the squirrel (hero frame 3 gliding, 4 diving); then the replay of that game on a desktop browser must give
// the same end state.
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('schizofuzz', 'check', 'touch')
const URL0 = HOST + '/game.html?game=schizofuzz&cls=GameSchizoFuzz&seed=123'
const PORT = +(process.env.PORT || 9545)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const press = async (id, ms) => {
  const p = BTN[id]
  await touch('touchStart', [{ x: p.x, y: p.y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
  await b.sleep(ms)
  await touch('touchEnd', [])
}
const ST = 'JSON.stringify({ st: kk.game.state._hx_index, f: kk.game.hero ? kk.game.hero.clip.frame : 0, y: kk.game.pos.y, dy: kk.game.pos.dy })'
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await press('space', 120)
  await b.sleep(200)
  console.log('after tap: state', JSON.parse(await b.eval(ST)).st, '(2 WaitSpace / 1 Start expected)')
  await press('space', 900)
  await b.sleep(300)
  const s1 = JSON.parse(await b.eval(ST))
  console.log('charge released: state', s1.st, s1.st === 4 ? 'OK (Angle)' : 'FAIL')
  await b.sleep(400)
  await press('space', 100)
  await b.sleep(400)
  const s2 = JSON.parse(await b.eval(ST))
  console.log('launch: state', s2.st, s2.st === 5 || s2.st === 3 ? 'OK (Run)' : 'FAIL')
  for (const [id, frame] of [['down', 4], ['up', 3], ['down', 4]]) {
    const p = BTN[id]
    await touch('touchStart', [{ x: p.x, y: p.y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
    await b.sleep(300)
    const s = JSON.parse(await b.eval(ST))
    await b.screenshot(out + '/t_' + id + '.png', { x: 8, y: 8, width: 600, height: 640 })
    await touch('touchEnd', [])
    console.log('button ' + id + ': hero frame', s.f, s.f === frame ? 'OK' : s.y > 260 ? '(on the ground)' : 'FAIL', JSON.stringify(s))
    await b.sleep(300)
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
