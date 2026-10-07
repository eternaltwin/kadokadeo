// Cereal Punk: cost of a game step (physics) and of a render, on a page whose loop is stopped (measure only)
// usage: node cpperf.mjs     env: PORT, HPORT, EXTRA
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9876))
try {
  await b.goto(HOST + '/game.html?game=cerealpunk&cls=GameCerealPunk&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  console.log(await b.eval(`(() => { kk.ff.onTick = () => {}; const t0 = performance.now(); for (let i = 0; i < 400; i++) kk.updatePhysics(1000 / 32)
    const t1 = performance.now(); for (let i = 0; i < 20; i++) kk.renderer.render(kk.stage); const t2 = performance.now()
    return JSON.stringify({ stepMs: ((t1 - t0) / 400).toFixed(3), renderMs: ((t2 - t1) / 20).toFixed(2), frame: window.__state.frame, clips: kk.game.dmanager ? 0 : 0 }) })()`))
} finally { await b.close() }
