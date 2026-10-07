// Happy Pti Tank: plays a replay saved by h3.mjs (replays/h3_<seed>.txt: data, then the live end state) and compares.
// usage: node hrep.mjs <replay file> [speed]     env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data, liveOver] = readFileSync(process.argv[2], 'utf8').split('\n')
const b = await launch(+(process.env.PORT || 9938))
try {
  await b.goto(HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123' + (process.env.EXTRA || '') + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval(`kk.setReplaySpeed(${+(process.argv[3] || 8)})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('live  ', liveOver)
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
