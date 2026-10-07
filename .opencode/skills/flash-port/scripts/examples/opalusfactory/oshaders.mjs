// Opalus Factory: shader programs compiled during a live game (harness/shaders.mjs; the game played by the page: the
// case next to the hero that climbs, collects nuts or completes the goal, every 300 ms, so that holes glow, lines
// fade, coins and the hero fall)
//   node oshaders.mjs [ms]     env: GPU=1, PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
const pkg = 'opalusfactory', cls = 'GameOpalusFactory'
const [ms = '30000'] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9405))
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
  const t0 = Date.now()
  while (Date.now() - t0 < +ms && !(await b.eval('!!window.__over'))) {
    await b.eval(`(() => { const g = kk.game; if (g.step._hx_index !== 1) return
      let best = null, bs = -1e9
      for (const l of g.roll) for (const c of l.line) if (g.canBePlayed(c)) {
        const n = c.links ? c.links.length : 0, id = c.coin ? c.coin.id : -1
        const sc = (l.index - g.heroY) * 12 + (id === 0 ? 14 * n : 0) + (id === g.goal.id ? (n >= g.goal.goal - g.goal.count ? 40 : 6 * n) : 0) + n
        if (sc > bs) { bs = sc; best = c } }
      if (best) g.play(best) })()`)
    await b.sleep(300)
  }
  const p = JSON.parse(await b.eval('JSON.stringify(__progs)'))
  console.log(pkg, 'shaders compiled during the game:', p.length)
  for (const x of p) console.log('  ', x.ms, 'ms  frame', x.frame, x.name, '|', x.uni)
  const u = JSON.parse(await b.eval('JSON.stringify(__ups)'))
  console.log('  textures uploaded to the GPU during the game (64x64 and more):', u.length)
  for (const x of u.slice(0, 25)) console.log('    ', x.ms, 'ms  frame', x.frame, x.fn, x.size, x.src)
} finally { await b.close() }
