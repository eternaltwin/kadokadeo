// Digestomax on a touch screen: the square buttons walk left / right, swallow the fruit below (▼) and above or poop the
// stomach (▲); then the replay of that game on a desktop browser must give the same end state (test mode dx: the game
// ends at Flash frame 900).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('digestomax', 'check', 'touch')
const URL0 = HOST + '/game.html?game=digestomax&cls=GameDigestomax&seed=123&test=dx&frames=900'
const PORT = +(process.env.PORT || 9877)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const down = (id) => touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
const up = () => touch('touchEnd', [])
const ST = 'JSON.stringify(kk.game.debugBot())'
const st = async () => JSON.parse(await b.eval(ST))
const idle = async () => { const t0 = Date.now(); while (!(await st()).idle && Date.now() - t0 < 5000) await b.sleep(40) }
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await idle()
  for (const id of ['right', 'left']) {
    const s0 = await st()
    await down(id)
    const t0 = Date.now()
    let s = s0
    while (Date.now() - t0 < 1500) { await b.sleep(30); s = await st(); if (s.hx !== s0.hx || !s.idle) break }
    await b.screenshot(out + '/t_' + id + '.png', { x: 8, y: 8, width: 600, height: 640 })
    await up()
    console.log('button ' + id + ': hero', s0.hx, '->', s.hx, (s.hx - s0.hx) * (id === 'left' ? -1 : 1) > 0 || s.stomach.length > s0.stomach.length ? 'OK' : 'FAIL')
    await idle()
  }
  {
    const s0 = await st()
    await down('down'); await b.sleep(80); await up()
    await b.sleep(300)
    await b.screenshot(out + '/t_down.png', { x: 8, y: 8, width: 600, height: 640 })
    await idle()
    const s = await st()
    console.log('button down: stomach', s0.stomach.join(''), '->', s.stomach.join(''), 'hero y', s0.hy, '->', s.hy, s.hy > s0.hy ? 'OK' : 'FAIL')
  }
  {
    const s0 = await st()
    await down('up'); await b.sleep(80); await up()
    await b.sleep(300)
    await b.screenshot(out + '/t_up.png', { x: 8, y: 8, width: 600, height: 640 })
    await idle()
    const s = await st()
    console.log('button up: stomach', s0.stomach.join(''), '->', s.stomach.join(''), 'hero y', s0.hy, '->', s.hy, s.stomach.length !== s0.stomach.length ? 'OK' : 'FAIL')
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
