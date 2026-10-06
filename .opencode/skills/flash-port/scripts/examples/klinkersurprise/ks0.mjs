// Klinker Surprise: opens a game, takes screenshots (start, after a mouse move, after a few clicks), prints the page
// errors. usage: node ks0.mjs [seed] [out prefix]     env: HPORT (harness server), PORT (DevTools), EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const seed = process.argv[2] || '123'
const out = process.argv[3] || gameDir('klinkersurprise', 'shots') + '/ks0'
const b = await launch(+(process.env.PORT || 9861))
const clip = { x: 8, y: 8, width: 600, height: 640 }
try {
  await b.goto(HOST + '/game.html?game=klinkersurprise&cls=GameKlinkerSurprise&seed=' + seed + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.map)', 60000)
  await b.sleep(1000)
  await b.screenshot(out + '_a.png', clip)
  // the canvas is at (8, 8): a point of the stage (Flash pixels) on the page
  const P = (x, y) => [8 + x * 2, 8 + y * 2]
  await b.move(...P(220, 150))
  await b.sleep(1200)
  await b.move(...P(150, 150))
  await b.sleep(600)
  await b.screenshot(out + '_b.png', clip)
  console.log(await b.eval(`JSON.stringify({sx: kk.game.selector.x, mx: kk.game.map._x, level: kk.game.level, gens: kk.game.generators.map(g => [g.px, g.py, g.type])})`))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
