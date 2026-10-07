// Hypercube: screenshot of the comparison page drawn by the game (test=show, Game.debugShow):
// $KKP_WORK/hypercube/check/run0.png (ref.py draws ref0.png from the SWF, tools/cmp_pages.py compares them).
// usage: node hshow.mjs        env: PORT (DevTools, default 9939), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9939))
try {
  await b.goto(HOST + '/game.html?game=hypercube&cls=GameHypercube&seed=123&test=show')
  await b.waitFor('!!(window.kk && kk.game && kk.game.__shown)', 60000)
  await b.sleep(1500)
  await b.screenshot(gameDir('hypercube', 'check') + '/run0.png', { x: 8, y: 8, width: 600, height: 600 })
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
