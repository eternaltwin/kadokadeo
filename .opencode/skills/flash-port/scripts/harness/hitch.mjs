// Long browser frames during a live game: time in the physics ticker, in the render, GPU texture uploads (first use of a
// texture) and garbage collections.   node hitch.mjs <game> <Class> [ms]
import { launch } from './cdp.mjs'
const [pkg, cls, ms = '30000'] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9403))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(`http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&seed=123&js=${process.env.JS || pkg}${process.env.EXTRA || ''}`)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.eval(`(() => {
    const sys = PIXI.Ticker.system, app = kk.ticker, R = kk.renderer
    window.__fr = []
    let cur = null
    sys.add(() => { cur = { t: performance.now(), phys: 0, rend: 0, up: [], f0: kk.replay.getCurrentFrame() }; cur.ps = performance.now() }, null, 1000)
    sys.add(() => { if (cur) cur.phys = performance.now() - cur.ps }, null, -1000)
    const render = R.render.bind(R)
    R.render = function (...a) { const t = performance.now(); render(...a); if (cur) cur.rend += performance.now() - t }
    const init = R.texture.initTexture.bind(R.texture)
    R.texture.initTexture = function (tex) { const t = performance.now(); const r = init(tex); if (cur) cur.up.push([tex.width + 'x' + tex.height, +(performance.now() - t).toFixed(1), (tex.resource && tex.resource.url || tex.resource && tex.resource.constructor.name || '').toString().split('/').pop()]); return r }
    app.add(() => { if (cur) { cur.steps = kk.replay.getCurrentFrame() - cur.f0; cur.total = performance.now() - cur.t; __fr.push(cur); cur = null } }, null, -1000)
  })()`)
  await b.send('HeapProfiler.enable').catch(() => {})
  await key('keyDown', 39, 'ArrowRight')
  const t0 = Date.now()
  let i = 0
  while (Date.now() - t0 < +ms) {
    i++
    await key('keyDown', 38, 'ArrowUp'); await b.sleep(200); await key('keyUp', 38, 'ArrowUp')
    if (i % 2) { await key('keyDown', 32, 'Space'); await b.sleep(50); await key('keyUp', 32, 'Space') }
    await b.sleep(700)
  }
  await key('keyUp', 39, 'ArrowRight')
  const fr = JSON.parse(await b.eval('JSON.stringify(__fr)'))
  const tot = fr.map(f => f.total).sort((a, c) => a - c)
  console.log(pkg, 'frames', fr.length, '| median duration', tot[tot.length >> 1].toFixed(2), 'ms, 99th percentile', tot[Math.floor(tot.length * 0.99)].toFixed(1), 'max', tot[tot.length - 1].toFixed(1))
  const ups = fr.flatMap(f => f.up)
  console.log('  textures uploaded to the GPU during the game:', ups.length, ups.slice(0, 15).map(u => u.join(' ')).join(' | '))
  const longs = fr.map((f, i) => ({ i, ...f })).filter(f => f.total > 12)
  for (const f of longs.slice(0, 20)) console.log('  frame', f.i, 'total', f.total.toFixed(1), 'ms: simulation', f.phys.toFixed(1), '(' + f.steps + ' steps) render', f.rend.toFixed(1), f.up.length ? 'textures ' + f.up.map(u => u.join(' ')).join(', ') : '')
} finally { await b.close() }
