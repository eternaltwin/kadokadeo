// Razor on a touch screen: the buttons move the razor right / left around the board and slice (▲), each held until
// the game reacts; then the replay of that game on a desktop browser must give the same end state (test mode rz: the
// game ends at Flash frame 700).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('razor', 'check', 'touch')
const URL0 = HOST + '/game.html?game=razor&cls=GameRazor&seed=123&test=rz&frames=700'
const PORT = +(process.env.PORT || 9943)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let BTN
const down = (id) => touch('touchStart', [{ x: BTN[id].x, y: BTN[id].y, id: 1, radiusX: 4, radiusY: 4, force: 1 }])
const up = () => touch('touchEnd', [])
const ST = 'JSON.stringify(kk.game.debugBot())'
const st = async () => JSON.parse(await b.eval(ST))
const idle = async () => { const t0 = Date.now(); while (!(await st()).idle && Date.now() - t0 < 8000) await b.sleep(40) }
// held until the razor leaves its place or the slice starts
const hold = async (id) => {
  const s0 = await st()
  await down(id)
  const t0 = Date.now()
  let s = s0
  while (Date.now() - t0 < 2000) { await b.sleep(20); s = await st(); if (s.rx !== s0.rx || s.ry !== s0.ry || !s.idle) break }
  await up()
  await b.screenshot(out + '/t_' + id + '.png', { x: 8, y: 8, width: 600, height: 640 })
  await idle()
  return [s0, await st()]
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.touchOverlay)', 60000)
  BTN = JSON.parse(await b.eval(`(() => { const r = document.querySelector('.kk-touch-controls-canvas').getBoundingClientRect()
    const o = {}; for (const s of kk.touchOverlay.buttonStates) o[s.cfg.id] = { x: r.left + s.x + s.size / 2, y: r.top + s.y + s.size / 2 }
    return JSON.stringify(o) })()`))
  console.log('buttons', JSON.stringify(BTN))
  await idle()
  for (const id of ['right', 'left', 'left']) {
    const [s0, s] = await hold(id)
    // (the bottom side: right is +x, left is -x)
    const dx = s.rx - s0.rx
    console.log('button ' + id + ': razor', s0.rx, s0.ry, '->', s.rx, s.ry, (id === 'right' ? dx > 0 : dx < 0) ? 'OK' : 'FAIL')
  }
  {
    const [s0, s] = await hold('slice')
    const n0 = s0.limits.reduce((a, c) => a + c, 0), n = s.limits.reduce((a, c) => a + c, 0)
    console.log('button slice: icons', s0.limits.join(','), '->', s.limits.join(','), n === n0 + 1 ? 'OK' : 'FAIL')
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
