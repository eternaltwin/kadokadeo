// Smoothness of what is shown: every rendered picture, the simulated time on screen (frames + alpha - 1) and the hero on
// screen; hitches = jumps of the shown time, or of the hero against the shown time.
//   node stutter.mjs <game> <Class> <hero expr> [ms]      (hero expr: JS giving the hero sprite, e.g. kk.game.hero.root)
//   env SCREEN_ONLY=1: only the renders of the screen are recorded (a game that draws into textures every frame)
import { launch } from './cdp.mjs'
const [pkg, cls, heroExpr, ms = '20000'] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9401))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(`http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&seed=123&js=${process.env.JS || pkg}${process.env.EXTRA || ''}`)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.sleep(1500)
  await b.eval(`(() => {
    window.__rec = []
    const r = kk.renderer.render.bind(kk.renderer)
    kk.renderer.render = function (...a) {
      r(...a)
      // SCREEN_ONLY: the renders into a texture (bitmaps drawn by the game on the GPU) are not pictures of the screen
      if (${process.env.SCREEN_ONLY ? 'true' : 'false'} && a[1] && a[1].renderTexture) return
      let hx = null, hy = null
      try { const h = ${heroExpr}; if (h && h.worldTransform) { hx = h.worldTransform.tx; hy = h.worldTransform.ty } } catch (e) {}
      __rec.push([performance.now(), kk.replay.getCurrentFrame(), kk.ff.alpha, hx, hy])
    }
  })()`)
  await key('keyDown', 39, 'ArrowRight')
  const t0 = Date.now()
  while (Date.now() - t0 < +ms) {
    await key('keyDown', 38, 'ArrowUp'); await b.sleep(250); await key('keyUp', 38, 'ArrowUp'); await b.sleep(900)
  }
  await key('keyUp', 39, 'ArrowRight')
  const rec = JSON.parse(await b.eval('JSON.stringify(__rec)'))
  // shown time (in steps) and its increments
  const STEP = 1000 / 32
  let bad = 0, back = 0, stall = 0, big = 0
  const ex = []
  for (let i = 2; i < rec.length; i++) {
    const [t, f, a] = rec[i], [t1, f1, a1] = rec[i - 1]
    const shown = f + a, shown1 = f1 + a1
    const d = shown - shown1, want = (t - t1) / STEP
    if (d < -1e-6) back++
    else if (d < want * 0.25 && want > 0.2) stall++
    else if (d > want * 1.75 + 0.1) big++
    if (d < -1e-6 || (d < want * 0.25 && want > 0.2) || d > want * 1.75 + 0.1) { bad++; if (ex.length < 12) ex.push({ i, dt: +(t - t1).toFixed(1), want: +want.toFixed(2), d: +d.toFixed(2), f, a: +a.toFixed(2), f1, a1: +a1.toFixed(2) }) }
  }
  const dts = rec.slice(1).map((r, i) => r[0] - rec[i][0]).sort((x, y) => x - y)
  console.log(pkg, 'frames', rec.length, '| median interval', dts[dts.length >> 1].toFixed(1), 'ms, max', dts[dts.length - 1].toFixed(1),
    '| shown time: back', back, 'stalls', stall, 'jumps', big)
  for (const e of ex) console.log('  ', JSON.stringify(e))
  // hero against the shown time: speed in px per step on screen, outliers
  const hs = []
  for (let i = 1; i < rec.length; i++) {
    const ds = (rec[i][1] + rec[i][2]) - (rec[i - 1][1] + rec[i - 1][2])
    if (rec[i][3] == null || rec[i - 1][3] == null || ds <= 0.05) continue
    hs.push({ i, v: (rec[i][3] - rec[i - 1][3]) / ds, vy: (rec[i][4] - rec[i - 1][4]) / ds, ds })
  }
  let jumps = 0
  const hx = []
  for (let k = 2; k < hs.length - 2; k++) {
    const around = [hs[k - 2].v, hs[k - 1].v, hs[k + 1].v, hs[k + 2].v].sort((x, y) => x - y)
    const med = (around[1] + around[2]) / 2
    if (Math.abs(hs[k].v - med) > Math.max(6, Math.abs(med) * 0.8)) { jumps++; if (hx.length < 12) hx.push({ i: hs[k].i, v: +hs[k].v.toFixed(1), med: +med.toFixed(1), ds: +hs[k].ds.toFixed(2) }) }
  }
  console.log('  hero: frames with a horizontal jerk', jumps, 'of', hs.length)
  for (const e of hx) console.log('    ', JSON.stringify(e))
  if (process.env.DUMP) (await import('fs')).writeFileSync(process.env.DUMP, JSON.stringify(rec))
} finally { await b.close() }
