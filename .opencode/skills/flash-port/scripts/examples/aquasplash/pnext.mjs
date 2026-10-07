// Aqua Splash: the level transition of the port frame by frame (Flash frames played by hand, shown without the lagged
// display), to compare with the original's (rburst.mjs on ref_next.swf).
// usage: node pnext.mjs <out prefix> [frames]     env: HPORT, PORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const [out, n = '60'] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9965))
try {
  await b.goto(HOST + '/game.html?game=aquasplash&cls=GameAquaSplash&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.mcTime)', 60000)
  await b.sleep(500)
  await b.eval('kk.ff.onTick = function () {}; kk.game.initNextLevel()')
  await b.eval('kk.game.debugFrames(0); kk.ff.alpha = 1')
  for (let i = 1; i <= +n; i++) {
    await b.sleep(100)
    await b.screenshot(out + String(i).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    await b.eval('kk.game.debugFrames(1); kk.ff.alpha = 1')
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
