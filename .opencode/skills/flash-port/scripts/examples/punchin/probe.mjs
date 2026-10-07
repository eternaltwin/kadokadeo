// evaluates a JS expression in a running game page: node probe.mjs '<js>' [extra url]   env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9964))
try {
  await b.goto(HOST + '/game.html?game=punchin&cls=GamePunchIn&seed=123' + (process.argv[3] || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  console.log(await b.eval(process.argv[2]))
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)).slice(0, 8).join('\n'))
  await b.close()
}
