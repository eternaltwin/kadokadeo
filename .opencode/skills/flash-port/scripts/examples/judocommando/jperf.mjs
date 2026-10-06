// cost of a physics step on a crowded level (lvl=10: 42 monsters), measured with the loop stopped
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9899))
try {
  await b.goto(HOST + '/game.html?game=judocommando&cls=GameJudoCommando&seed=123&test=jc&inv=1&lvl=' + (process.env.LVL || 10))
  await b.waitFor('!!(window.kk && kk.game && window.__state && window.__state.step == "Play")', 90000)
  await b.sleep(2000)
  console.log(await b.eval(`(() => { kk.ff.onTick = () => {}; const n = 320; const t0 = performance.now()
    for (let i = 0; i < n; i++) kk.updatePhysics(1000 / 32)
    const dt = (performance.now() - t0) / n
    const r0 = performance.now(); for (let i = 0; i < 60; i++) { kk.updateGraphics(1); kk.renderer.render(kk.stage) }
    return 'monsters ' + kk.game.monsters.length + ', ents ' + kk.game.ents.length + ': ' + dt.toFixed(3) + ' ms per step, render ' + ((performance.now() - r0) / 60).toFixed(2) + ' ms' })()`))
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
