// Cereal Punk smoke test: loads the game, moves, takes and throws a few times, screenshots every half second.
// usage: node cp0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9861))
const KEYS = { up: [38, 'ArrowUp'], down: [40, 'ArrowDown'], left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][1] })
const tap = async (k, ms = 90) => { await key('keyDown', k); await b.sleep(ms); await key('keyUp', k) }
const shot = (n) => b.screenshot(gameDir('cerealpunk', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
try {
  await b.goto(HOST + '/game.html?game=cerealpunk&cls=GameCerealPunk&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(1500)
  await shot('00start')
  console.log(await b.eval('JSON.stringify(window.__state)'))
  const seq = ['up', 'left', 'down', 'right', 'up', 'right', 'down', 'left', 'up', 'down']
  for (let s = 0; s < secs * 2; s++) {
    await tap(seq[s % seq.length])
    await b.sleep(400)
    await shot(String(s + 10))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
