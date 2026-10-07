// debug: evaluates a JS expression in a running game page (after `wait` ms)
// usage: HPORT=8786 PORT=9862 node dbg.mjs '<expr>' [wait ms] [extra url]
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9862))
await b.goto(HOST + '/game.html?game=chakrebouddha&cls=GameChakreBouddha&seed=123' + (process.argv[4] || ''))
await b.waitFor('!!(window.kk && kk.game && kk.game.chakras)', 60000)
await new Promise(r => setTimeout(r, +(process.argv[3] || 1000)))
console.log(await b.eval(process.argv[2]))
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH/.test(l)).slice(0, 5).join('\n').slice(0, 2000))
await b.close()
