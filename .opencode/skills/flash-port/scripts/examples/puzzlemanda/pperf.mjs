// Puzzle-Manda with the real GPU (GPU=1) while a simple bot plays (click on the first fruit, the mouse over the next
// ones; a bonus in every sequence): shader programs compiled and big textures uploaded during the game (each blocks a
// frame the first time: warmShaders must have made them), long browser frames, cost of a game step.
// usage: GPU=1 node pperf.mjs [ms]   env: PORT (default 9993), HPORT, EXTRA (default '&test=pm&lv=8&bonus=3')
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const ms = +(process.argv[2] || 40000)
const b = await launch(+(process.env.PORT || 9993))
const EXTRA = process.env.EXTRA || '&test=pm&lv=8&bonus=3'
let mx = 150, my = 290
const ev = (type, down) => b.send('Input.dispatchMouseEvent', { type, x: 8 + mx * 2, y: 8 + my * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
async function move(x, y) { const x0 = mx, y0 = my; for (let i = 1; i <= 4; i++) { mx = x0 + (x - x0) * i / 4; my = y0 + (y - y0) * i / 4; await ev('mouseMoved', false); await b.sleep(15) } }
const ST = `(() => { const G = GamePuzzleManda; const H = G.grid.length, W = G.grid[0].length;
  return JSON.stringify({ locked: G.locked(), eaten: G.suite.tmpList.length, over: !!window.__over,
    path: G.suite.list.map(c => ({ x: c.x * 30 + (300 - W * 30) / 2 + 15, y: c.y * 30 + 60 + (240 - H * 30) / 2 + 15 })) }) })()`
try {
  await b.goto(HOST + '/game.html?game=puzzlemanda&cls=GamePuzzleManda&seed=123' + EXTRA)
  await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  await b.eval(`(() => {
    const S = kk.renderer.shader
    window.__progs = []
    const gen = S.generateShader.bind(S)
    S.generateShader = function (shader) {
      const t = performance.now(); const r = gen(shader)
      const src = shader.program.fragmentSrc || ''
      __progs.push({ ms: +(performance.now() - t).toFixed(1), frame: kk.replay.getCurrentFrame(), uni: (src.match(/uniform [^;]+;/g) || []).slice(0, 4).join(' ').slice(0, 160) })
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
        if (w * h >= 64 * 64) __ups.push({ fn, ms: +d.toFixed(1), frame: kk.replay.getCurrentFrame(), size: w + 'x' + h })
        return r
      }
    }
    window.__long = []; window.__nf = 0
    let last = performance.now()
    const loop = (t) => { const d = t - last; last = t; __nf++; if (d > 40) __long.push(+d.toFixed(1)); requestAnimationFrame(loop) }
    requestAnimationFrame(loop)
    window.__step = []
    const up = kk.game.update.bind(kk.game)
    kk.game.update = function (dt) { const t = performance.now(); up(dt); __step.push(performance.now() - t) }
    return 0
  })()`)
  const t0 = Date.now()
  let levels = 0
  while (Date.now() - t0 < ms) {
    let s = JSON.parse(await b.eval(ST))
    if (s.over) break
    if (s.locked) { await b.sleep(40); continue }
    const p = s.path
    const k = s.eaten
    await move(p[k].x, p[k].y)
    if (k == 0) { await ev('mousePressed', true); await b.sleep(60); await ev('mouseReleased', false); await b.sleep(150) }
    else await b.sleep(80)
    if (k == p.length - 1) levels++
  }
  const p = JSON.parse(await b.eval('JSON.stringify(__progs)'))
  console.log('levels played', levels, '| shaders compiled during the game:', p.length)
  for (const x of p) console.log('  ', x.ms, 'ms  frame', x.frame, '|', x.uni)
  const u = JSON.parse(await b.eval('JSON.stringify(__ups)'))
  console.log('textures uploaded during the game (64x64 and more):', u.length)
  for (const x of u.slice(0, 10)) console.log('    ', x.ms, 'ms  frame', x.frame, x.fn, x.size)
  const st = JSON.parse(await b.eval('JSON.stringify(__step)')).sort((a, b) => a - b)
  const nf = await b.eval('__nf')
  const lg = JSON.parse(await b.eval('JSON.stringify(__long)'))
  console.log('browser frames', nf, 'in', ms / 1000, 's | longer than 40 ms:', lg.length, lg.slice(0, 20).join(' '))
  console.log('game step ms: median', st[st.length >> 1].toFixed(3), 'p99', st[Math.floor(st.length * 0.99)].toFixed(3), 'max', st[st.length - 1].toFixed(3))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
