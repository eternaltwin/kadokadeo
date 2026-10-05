// Hexile: opens a game and takes screenshots (start, after a few seconds), prints the page errors.
// usage: node h0.mjs [seed] [out prefix]     env: HPORT (harness server), PORT (DevTools), EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const seed = process.argv[2] || '123'
const out = process.argv[3] || gameDir('hexile', 'shots') + '/h0'
const b = await launch(+(process.env.PORT || 9910))
try {
  await b.goto(HOST + '/game.html?game=hexile&cls=GameHexile&seed=' + seed + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.castle)', 60000)
  await b.sleep(1500)
  await b.screenshot(out + '_a.png', { x: 8, y: 8, width: 600, height: 640 })
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
