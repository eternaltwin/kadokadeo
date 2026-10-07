// Punch-In on a touch screen: the square buttons dodge left / right (held), the round one punches; then the replay of
// that game on a desktop browser must give the same end state (test mode pi: the game ends at Flash frame 900).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('punchin', 'check', 'touch')
const URL0 = HOST + '/game.html?game=punchin&cls=GamePunchIn&seed=123&test=pi&frames=900'
const PORT = +(process.env.PORT || 9972)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const down = (id) => touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
const up = () => touch('touchEnd', [])
const st = async () => JSON.parse(await b.eval('JSON.stringify(window.__state)'))
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await b.sleep(500)
  for (const id of ['right', 'left']) {
    // (the player moves when he is not punching or hurt)
    let s0 = await st()
    while (s0.bstep !== 'Stand' || s0.bmove !== 'Center') { await b.sleep(30); s0 = await st() }
    await down(id)
    const t0 = Date.now()
    let s = s0
    while (Date.now() - t0 < 1500) { await b.sleep(30); s = await st(); if (s.bmove !== 'Center') break }
    await b.screenshot(out + '/t_' + id + '.png', { x: 8, y: 8, width: 600, height: 640 })
    await up()
    console.log('button ' + id + ': player', s0.bmove, '->', s.bmove, s.bmove.toLowerCase() === id ? 'OK' : 'FAIL')
    await b.sleep(400)
  }
  {
    let s0 = await st()
    while (s0.bstep !== 'Stand' || s0.bmove !== 'Center') { await b.sleep(30); s0 = await st() }
    const h0 = JSON.parse(s0.stats)
    await down('punch'); await b.sleep(120); await up()
    await b.sleep(700)
    await b.screenshot(out + '/t_punch.png', { x: 8, y: 8, width: 600, height: 640 })
    const h = JSON.parse((await st()).stats)
    const n0 = h0.hits + h0.misses, n = h.hits + h.misses
    console.log('button punch: punches landed or blocked', n0, '->', n, n > n0 ? 'OK' : 'FAIL')
  }
  // two fingers: a side held while punching (the punch waits for the hand on the side to come back)
  await touch('touchStart', [{ x: BTN.left.x, y: BTN.left.y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
  await b.sleep(300)
  await touch('touchStart', [{ x: BTN.left.x, y: BTN.left.y, id: 1, radiusX: 4, radiusY: 4, force: 1 }, { x: BTN.punch.x, y: BTN.punch.y, id: 2, radiusX: 4, radiusY: 4, force: 1 }])
  await b.sleep(200)
  await touch('touchEnd', [])
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
