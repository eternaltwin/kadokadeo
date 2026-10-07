// Phagocytoz performance with the real GPU (GPU=1): the bot of p3.mjs plays (mouse), while the page records the shader
// programs compiled and the textures uploaded during the game (harness/shaders.mjs), the duration of every browser
// frame with its simulation and render time (harness/hitch.mjs), and the cost of one game step.
// usage: GPU=1 node pperf.mjs [seconds] [bot seed]      env: PORT (default 9952), HPORT, EXTRA
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 40)
let rs = +(process.argv[3] || 1)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const b = await launch(+(process.env.PORT || 9952))
let mx = 150, my = 150, mdown = false
const mouse = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + mx * 2, y: 8 + my * 2, button: type === 'mouseMoved' && !mdown ? 'none' : 'left', buttons: mdown ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const STATE = `(() => { const g = kk.game; if (!g || !g.cells || !g.hero) return { over: !!window.__over }
  const h = g.hero, W = 1600, w = (d) => { while (d > W / 2) d -= W; while (d < -W / 2) d += W; return d }
  const cs = []
  for (const c of g.cells) if (c !== h) { const dx = w(c.x - h.x), dy = w(c.y - h.y); if (Math.abs(dx) < 400 && Math.abs(dy) < 400) cs.push([dx, dy, c.ray, c.consume ? 1 : 0]) }
  return { over: !!window.__over, hr: h.ray, cs, n: g.cells.length } })()`
try {
  await b.goto(HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval(`(() => {
    const S = kk.renderer.shader, R = kk.renderer, sys = PIXI.Ticker.system, app = kk.ticker
    window.__progs = []
    const gen = S.generateShader.bind(S)
    S.generateShader = function (shader) {
      const t = performance.now(); const r = gen(shader)
      const src = shader.program.fragmentSrc || ''
      __progs.push({ ms: +(performance.now() - t).toFixed(1), frame: kk.replay.getCurrentFrame(), uni: (src.match(/uniform [^;]+;/g) || []).slice(0, 4).join(' ').slice(0, 160) })
      return r
    }
    window.__fr = []
    let cur = null
    sys.add(() => { cur = { t: performance.now(), phys: 0, rend: 0, up: [], f0: kk.replay.getCurrentFrame() }; cur.ps = performance.now() }, null, 1000)
    sys.add(() => { if (cur) cur.phys = performance.now() - cur.ps }, null, -1000)
    const render = R.render.bind(R)
    R.render = function (...a) { const t = performance.now(); render(...a); if (cur) cur.rend += performance.now() - t }
    const init = R.texture.initTexture.bind(R.texture)
    R.texture.initTexture = function (tex) { const t = performance.now(); const r = init(tex); if (cur) cur.up.push([tex.width + 'x' + tex.height, +(performance.now() - t).toFixed(1)]); return r }
    app.add(() => { if (cur) { cur.steps = kk.replay.getCurrentFrame() - cur.f0; cur.total = performance.now() - cur.t; __fr.push(cur); cur = null } }, null, -1000)
  })()`)
  const t0 = Date.now()
  let pauseT = 0
  while (Date.now() - t0 < secs * 1000) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (!s.cs) { await b.sleep(30); continue }
    let fx = 0.2, fy = 0, best = null, bd = 1e9
    for (const [dx, dy, r, cons] of s.cs) {
      const d = Math.hypot(dx, dy) || 1, gap = d - r - s.hr
      if (r < s.hr * 0.88) { if (gap < bd) { bd = gap; best = [dx, dy] } }
      else if (Math.abs(1 - s.hr / r) >= 0.1) { const k = (cons ? 6 : 3) * Math.max(0, 1 - gap / (60 + r)); fx -= dx / d * k; fy -= dy / d * k }
    }
    if (best) { const d = Math.hypot(best[0], best[1]) || 1; fx += best[0] / d * 1.5; fy += best[1] / d * 1.5 }
    const a = Math.atan2(fy, fx)
    mx = 150 + Math.cos(a) * 80; my = 150 + Math.sin(a) * 80
    if (pauseT > 0) pauseT--; else if (rnd(60) === 0) pauseT = 3 + rnd(15)
    const want = pauseT === 0
    if (want !== mdown) { mdown = want; await mouse(want ? 'mousePressed' : 'mouseReleased') } else await mouse('mouseMoved')
    await b.sleep(20 + rnd(20))
  }
  if (mdown) { mdown = false; await mouse('mouseReleased') }
  const p = JSON.parse(await b.eval('JSON.stringify(__progs)'))
  console.log('shaders compiled during the game:', p.length)
  for (const x of p) console.log('  ', x.ms, 'ms  frame', x.frame, '|', x.uni)
  const fr = JSON.parse(await b.eval('JSON.stringify(__fr)'))
  const tot = fr.map((f) => f.total).sort((a, c) => a - c)
  const ph = fr.filter((f) => f.steps > 0).map((f) => f.phys / f.steps).sort((a, c) => a - c)
  console.log('browser frames', fr.length, '| median', tot[tot.length >> 1].toFixed(2), 'ms, 99th percentile', tot[Math.floor(tot.length * 0.99)].toFixed(1), 'max', tot[tot.length - 1].toFixed(1),
    '| one game step: median', ph[ph.length >> 1].toFixed(2), 'ms, max', ph[ph.length - 1].toFixed(1))
  const ups = fr.flatMap((f) => f.up)
  console.log('textures uploaded during the game:', ups.length, ups.slice(0, 10).map((u) => u.join(' ')).join(' | '))
  const longs = fr.map((f, i) => ({ i, ...f })).filter((f) => f.total > 20)
  for (const f of longs.slice(0, 12)) console.log('  frame', f.i, 'total', f.total.toFixed(1), 'ms: simulation', f.phys.toFixed(1), '(' + f.steps + ' steps) render', f.rend.toFixed(1), f.up.length ? 'textures ' + f.up.map((u) => u.join(' ')).join(', ') : '')
  console.log('state', await b.eval('JSON.stringify(window.__state)'))
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
