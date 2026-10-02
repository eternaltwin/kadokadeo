// shader programs compiled during a live game (each one blocks a frame the first time): time, game frame, what
//   node shaders.mjs <game> <Class> [ms]
import { launch } from './cdp.mjs'
const [pkg, cls, ms = '30000'] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9405))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(`http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&seed=${process.env.SEED || 123}&js=${process.env.JS || pkg}${process.env.EXTRA || ''}`)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  if (process.env.INIT) { await b.waitFor('!!(kk.game && kk.game.hero)', 60000); await b.eval(process.env.INIT) }
  const before = await b.eval(`(() => {
    const S = kk.renderer.shader
    window.__progs = []
    const gen = S.generateShader.bind(S)
    S.generateShader = function (shader) {
      const t = performance.now(); const r = gen(shader)
      const src = shader.program.fragmentSrc || ''
      const m = src.match(/uniform [^;]+;/g) || []
      __progs.push({ ms: +(performance.now() - t).toFixed(1), frame: kk.replay.getCurrentFrame(), name: shader.program.name || '', uni: m.slice(0, 4).join(' ').slice(0, 160) })
      return r
    }
    window.__ups = []
    const gl = kk.renderer.gl
    for (const fn of ['texImage2D', 'texSubImage2D']) {
      const o = gl[fn].bind(gl)
      gl[fn] = function (...a) {
        const t = performance.now(); const r = o(...a); const d = performance.now() - t
        const src = a[a.length - 1]
        const w = src && src.width != null ? src.width : a[3], h = src && src.height != null ? src.height : a[4]
        if (w * h >= 64 * 64) __ups.push({ fn, ms: +d.toFixed(1), frame: kk.replay.getCurrentFrame(), size: w + 'x' + h, src: src && src.constructor ? src.constructor.name : typeof src })
        return r
      }
    }
    return 0
  })()`)
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
  const p = JSON.parse(await b.eval('JSON.stringify(__progs)'))
  console.log(pkg, 'shaders compiled during the game:', p.length)
  for (const x of p) console.log('  ', x.ms, 'ms  frame', x.frame, x.name, '|', x.uni)
  const u = JSON.parse(await b.eval('JSON.stringify(__ups)'))
  console.log('  textures uploaded to the GPU during the game (64x64 and more):', u.length)
  for (const x of u.slice(0, 25)) console.log('    ', x.ms, 'ms  frame', x.frame, x.fn, x.size, x.src)
} finally { await b.close() }
