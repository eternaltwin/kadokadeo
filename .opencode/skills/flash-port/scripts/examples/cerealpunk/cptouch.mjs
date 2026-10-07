// Cereal Punk on a touch screen: the square buttons move the cook one column left / right, ▲ takes, ▼ throws (scenario
// a of the test mode: the cook takes the two 0 of his column, throws them on the next one); then the replay of that game
// on a desktop browser must give the same end state (the game ends at Flash frame 500).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('cerealpunk', 'check', 'touch')
const URL0 = HOST + '/game.html?game=cerealpunk&cls=GameCerealPunk&seed=123&test=cp&setup=a&hold=500&frames=500'
const PORT = +(process.env.PORT || 9883)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const tap = async (id) => {
  await touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
  await b.sleep(120)
  await touch('touchEnd', [])
  await b.sleep(700)
}
const ST = 'JSON.stringify({ px: kk.game.hero.px, held: kk.game.hero.legumes.length, score: window.__state.score })'
const check = async (name, ok) => {
  const s = JSON.parse(await b.eval(ST))
  await b.screenshot(out + '/t_' + name + '.png', { x: 8, y: 8, width: 600, height: 640 })
  console.log('button ' + name, ok(s) ? 'OK' : 'FAIL', JSON.stringify(s))
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await b.sleep(500)
  await tap('up'); await check('up', (s) => s.held === 2)
  await tap('right'); await check('right', (s) => s.px === 4)
  await tap('down'); await check('down', (s) => s.held === 0)
  await tap('left'); await check('left', (s) => s.px === 3)
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver.replace(/"grid":"[^"]*",/, ''), 'replay chars', data.length)
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
