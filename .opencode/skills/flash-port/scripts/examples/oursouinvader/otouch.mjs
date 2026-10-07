// Oursouinvader on a touch screen: the square buttons move the urchin left / right, the round one shoots (Space);
// then the replay of that game on a desktop browser must give the same end state (test mode oi: the game ends at Flash
// frame 900).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('oursouinvader', 'check', 'touch')
const URL0 = HOST + '/game.html?game=oursouinvader&cls=GameOursouinvader&seed=123&test=oi&frames=900'
const PORT = +(process.env.PORT || 9968)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const down = (id) => touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
const up = () => touch('touchEnd', [])
const ST = 'JSON.stringify({ step: kk.game.step, x: kk.game.hero.x, shots: kk.game.shotList.filter(s => !s.badShot).length, fired: JSON.parse(window.__state.stats).shots })'
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  // the wave comes in (the urchin shoots once the monsters are in place)
  await b.waitFor('kk.game.step === 1', 60000)
  for (const [id, sign] of [['left', -1], ['right', 1]]) {
    const s0 = JSON.parse(await b.eval(ST))
    await down(id)
    await b.sleep(300)
    const s = JSON.parse(await b.eval(ST))
    await b.screenshot(out + '/t_' + id + '.png', { x: 8, y: 8, width: 600, height: 640 })
    await up()
    console.log('button ' + id + ': x', s0.x, '->', s.x, (s.x - s0.x) * sign > 10 ? 'OK' : 'FAIL')
    await b.sleep(200)
  }
  const f0 = JSON.parse(await b.eval(ST)).fired
  await down('fire')
  await b.sleep(700)
  const s = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_fire.png', { x: 8, y: 8, width: 600, height: 640 })
  await up()
  console.log('button fire: shots fired', s.fired - f0, s.fired - f0 >= 2 ? 'OK' : 'FAIL')
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
