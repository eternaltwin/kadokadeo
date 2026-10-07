// Razor on the real GPU (GPU=1): shader programs compiled and big textures uploaded during a live game, and the time
// of every displayed frame (requestAnimationFrame) and physics step, on the heaviest scene: the 24 fruits combo of the
// test board a (the trail, about 70 pieces, the splashes, the comment and its filters), then a few more slices.
// usage: node rperf.mjs [ms]      env: PORT (default 9944), HPORT, GPU=1
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const ms = +(process.argv[2] || 20000)
const b = await launch(+(process.env.PORT || 9944))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(HOST + '/game.html?game=razor&cls=GameRazor&seed=123&test=rz&pat=a')
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(500)
  await b.eval(`(() => {
    const S = kk.renderer.shader
    window.__progs = []
    const gen = S.generateShader.bind(S)
    S.generateShader = function (shader) {
      const t = performance.now(); const r = gen(shader)
      __progs.push({ ms: +(performance.now() - t).toFixed(1), frame: kk.game.frameCount })
      return r
    }
    window.__ups = []
    const gl = kk.renderer.gl
    for (const fn of ['texImage2D', 'texSubImage2D']) {
      const o = gl[fn].bind(gl)
      gl[fn] = function (...a) {
        const t = performance.now(); const r = o(...a)
        const src = a[a.length - 1]
        const w = src && src.width != null ? src.width : a[3], h = src && src.height != null ? src.height : a[4]
        if (w * h >= 64 * 64) __ups.push({ ms: +(performance.now() - t).toFixed(1), frame: kk.game.frameCount, size: w + 'x' + h })
        return r
      }
    }
    window.__dt = []; window.__phys = []
    let last = performance.now()
    const raf = () => { const t = performance.now(); __dt.push(t - last); last = t; requestAnimationFrame(raf) }
    requestAnimationFrame(raf)
    const up = kk.game.update.bind(kk.game)
    kk.game.update = function (d) { const t = performance.now(); up(d); __phys.push(performance.now() - t) }
    return 0
  })()`)
  const t0 = Date.now()
  while (Date.now() - t0 < ms) {
    await key('keyDown', 38, 'ArrowUp'); await b.sleep(120); await key('keyUp', 38, 'ArrowUp')
    await b.sleep(2500)
    await key('keyDown', 37, 'ArrowLeft'); await b.sleep(120); await key('keyUp', 37, 'ArrowLeft')
    await b.sleep(600)
  }
  const r = JSON.parse(await b.eval(`JSON.stringify({ progs: __progs, ups: __ups, dt: __dt.slice(5), phys: __phys, st: window.__state })`))
  const dt = r.dt.slice().sort((a, c) => a - c), ph = r.phys.slice().sort((a, c) => a - c)
  const q = (a, p) => a[Math.min(a.length - 1, Math.floor(a.length * p))].toFixed(1)
  console.log('shaders compiled during the game:', r.progs.length, JSON.stringify(r.progs))
  console.log('textures uploaded (64x64+):', r.ups.length, JSON.stringify(r.ups.slice(0, 10)))
  console.log('frames', dt.length, 'median', q(dt, 0.5), 'p99', q(dt, 0.99), 'max', dt[dt.length - 1].toFixed(1), 'ms; over 50 ms:', dt.filter((x) => x > 50).length)
  console.log('physics steps', ph.length, 'median', q(ph, 0.5), 'p99', q(ph, 0.99), 'max', ph[ph.length - 1].toFixed(1), 'ms')
  console.log('state', JSON.stringify(r.st).slice(0, 200))
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
