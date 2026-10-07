// K-Train heavy scene: full speed (all the smoke), then the cost of a physics step (stepped by hand) and the browser
// frames of the live game for a few seconds (real GPU with GPU=1).
// usage: node tperf.mjs      env: PORT, HPORT, GPU
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9899))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(HOST + '/game.html?game=ktrain&cls=GameKTrain&seed=123&test=kt&frames=99999')
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  if (process.env.NOBLUR) await b.eval('window.__noSmokeBlur = true')
  for (let i = 0; i < 3; i++) { await key('keyDown', 38, 'ArrowUp'); await b.sleep(80); await key('keyUp', 38, 'ArrowUp'); await b.sleep(200) }
  await b.sleep(8000)
  const frames = JSON.parse(await b.eval(`new Promise((res) => { const t = []; let last = performance.now(), n = 0
    const f = (now) => { t.push(now - last); last = now; if (++n < 300) requestAnimationFrame(f); else res(JSON.stringify(t)) }
    requestAnimationFrame(f) })`))
  frames.sort((a, c) => a - c)
  console.log('browser frames (ms): median', frames[150].toFixed(1), 'p99', frames[296].toFixed(1), 'max', frames[299].toFixed(1))
  const r = JSON.parse(await b.eval(`(() => { kk.ff.onTick = () => {}; const s = kk.game.debugBot()
    const t0 = performance.now(); for (let i = 0; i < 200; i++) kk.updatePhysics(1000 / 32); const t1 = performance.now()
    const t2 = performance.now(); for (let i = 0; i < 50; i++) kk.renderer.render(kk.stage); kk.renderer.gl.finish(); const t3 = performance.now()
    return JSON.stringify({ speed: s.speed, step: (t1 - t0) / 200, render: (t3 - t2) / 50, sprites: kk.game.stageRoot().children.length }) })()`))
  console.log('physics step', r.step.toFixed(3), 'ms, render', r.render.toFixed(2), 'ms, speed', r.speed.toFixed(2), 'clips', r.sprites)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
