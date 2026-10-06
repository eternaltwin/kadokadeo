// screenshots of a recorded game (a replay file of c3.mjs) at chosen steps, or every N steps between two steps
// usage: node cshots.mjs <replay file> <out dir> <from step> <to step> [every]      env: PORT (default 9926), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync, mkdirSync } from 'node:fs'
const [file, out] = [process.argv[2], process.argv[3]]
const from = +process.argv[4], to = +process.argv[5], every = +(process.argv[6] || 10)
mkdirSync(out, { recursive: true })
const data = readFileSync(file, 'utf8').split('\n')[0].trim()
const b = await launch(+(process.env.PORT || 9926))
try {
  await b.goto(HOST + '/game.html?game=cosmocrash&cls=GameCosmoCrash&seed=123&replay=' + encodeURIComponent(data) + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.setReplayPaused(true)')
  for (let f = from; f <= to; f += every) {
    await b.eval(`kk.seekReplay(${f})`)
    await b.sleep(150)
    await b.screenshot(out + '/f' + String(f).padStart(5, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
  }
  console.log(await b.eval('JSON.stringify(window.__state)'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
