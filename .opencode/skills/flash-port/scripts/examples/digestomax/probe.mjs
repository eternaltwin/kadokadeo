// evaluates JS expressions in a game page (argv: expressions, run in order; the result of the last one printed)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9862))
try {
  await b.goto(HOST + '/game.html?game=digestomax&cls=GameDigestomax&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  for (const e of process.argv.slice(2)) console.log(await b.eval(e))
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|unknown/i.test(l)).slice(0, 8).join('\n').slice(0, 3000))
  await b.close()
}
