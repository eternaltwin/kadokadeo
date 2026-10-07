// Pacifik: debug helper: plays a saved replay, seeks to a frame, prints exceptions with their stack.
// usage: HPORT=8811 PORT=9938 node dbg.mjs <replay file> <frame>...
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'fs'
const data = readFileSync(process.argv[2], 'utf8').split('\n')[0]
const b = await launch(+(process.env.PORT || 9938))
try {
  await b.goto(HOST + '/game.html?game=pacifik&cls=GamePacifik&seed=123&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser)', 60000)
  for (const f of process.argv.slice(3)) {
    console.log(f, await b.eval(`(() => { try { kk.seekReplay(${+f}); return 'ok ' + kk.game.frameCount } catch (e) { return e.stack } })()`))
    await b.sleep(500)
  }
  console.log(b.consoleLines.filter((l) => /EXCEPTION|rror/.test(l)).slice(0, 5).join('\n'))
} finally { await b.close() }
