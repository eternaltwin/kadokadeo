// Kanji Gaiden game over: nobody throws, a monkey of the front plane jumps onto the player (the copy at 100 %, "_land"
// then "_stand"): screenshots every 120 ms from the game over.
// usage: node g5.mjs [shots prefix]     env: PORT, HPORT, EXTRA (url params, default: difficulty 4)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const pre = process.argv[2] || 'end'
const b = await launch(+(process.env.PORT || 9861))
try {
  await b.goto(HOST + '/game.html?game=kanjigaiden&cls=GameKanjiGaiden&seed=123' + (process.env.EXTRA || '&test=kg&diff=4'))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.waitFor('!!window.__over', 600000)
  for (let i = 0; i < 12; i++) {
    await b.screenshot(gameDir('kanjigaiden', 'shots') + `/${pre}${String(i).padStart(2, '0')}.png`, { x: 8, y: 8, width: 600, height: 640 })
    await b.sleep(120)
  }
  console.log(await b.eval('JSON.stringify(window.__over)'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
