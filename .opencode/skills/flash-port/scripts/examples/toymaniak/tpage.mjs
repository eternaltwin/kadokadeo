// Toy Maniak: screenshots of the comparison pages drawn by the game (test=show&page=N, Game.debugShow):
// $KKP_WORK/toymaniak/check/run<N>.png (ref.py draws ref<N>.png from the SWF, tools/cmp_pages.py compares them).
// usage: node tpage.mjs        env: PORT (DevTools, default 9965), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9965))
try {
  for (const page of [0, 1]) {
    await b.goto(HOST + '/game.html?game=toymaniak&cls=GameToyManiak&seed=123&test=show&page=' + page)
    await b.waitFor('!!(window.kk && kk.game && kk.game.__shown)', 60000)
    await b.sleep(1500)
    await b.screenshot(gameDir('toymaniak', 'check') + '/run' + page + '.png', { x: 8, y: 8, width: 600, height: 600 })
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
