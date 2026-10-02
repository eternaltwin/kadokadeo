// K-Slash performance: cost of a physics step (simulation only) and real frame rate on a heavy scene (high
// difficulty, the 18 flyers of the voodoo doll, super hero with afterimages and flashing monsters).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9547))
try {
  await b.goto(HOST + '/game.html?game=kslash&cls=GameKSlash&seed=123&test=ks&frames=100000&dif=6000&inv=1&ids=9,10,9,10&every=60')
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  console.log('renderer', await b.eval(`(() => { const gl = document.createElement('canvas').getContext('webgl'); const d = gl && gl.getExtension('WEBGL_debug_renderer_info'); return d ? gl.getParameter(d.UNMASKED_RENDERER_WEBGL) : 'n/a' })()`))
  const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
  await key('keyDown', 32, ' ')
  await b.sleep(6000)
  const fps = await b.eval(`new Promise(res => { let n = 0, t0 = 0, worst = 0, last = 0; const f = (t) => { if (!t0) { t0 = t; last = t } else { worst = Math.max(worst, t - last); last = t; n++ } if (t - t0 < 4000) requestAnimationFrame(f); else res({ fps: n / ((t - t0) / 1000), worstMs: worst }) }; requestAnimationFrame(f) })`)
  console.log('render', JSON.stringify(fps))
  console.log('scene', await b.eval(`JSON.stringify({ monsters: kk.game.mList.length, shots: kk.game.sList.length, parts: kk.game.pList.length, supa: kk.game.hero.sTimer, nodes: (() => { let n = 0; const w = (o) => { n++; for (const c of o.children) w(c) }; w(kk.stage); return n })() })`))
  await b.screenshot(gameDir('kslash', 'check') + '/perf.png', { x: 8, y: 8, width: 600, height: 640 })
  // simulation only (no rendering): 300 steps
  const ms = await b.eval(`(() => { const t0 = performance.now(); for (let i = 0; i < 300; i++) kk.updatePhysics(31.25); return (performance.now() - t0) / 300 })()`)
  console.log('ms per physics step', ms.toFixed(3))
  await key('keyUp', 32, ' ')
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l))
  console.log('errors', errs.length, errs.slice(0, 3).join('\n').slice(0, 1000))
  await b.close()
}
