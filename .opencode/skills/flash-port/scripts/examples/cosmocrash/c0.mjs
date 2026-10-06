// Cosmo Crash smoke test: loads the game, takes off (up), turns, thrusts, screenshots every half second.
// usage: node c0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9921))
const KEYS = { up: [38, 'ArrowUp'], left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][1] })
const shot = (n) => b.screenshot(gameDir('cosmocrash', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
try {
  await b.goto(HOST + '/game.html?game=cosmocrash&cls=GameCosmoCrash&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(600)
  await shot('00start')
  console.log(await b.eval('JSON.stringify(window.__state)'))
  await key('keyDown', 'up')
  await b.sleep(900)
  await shot('01up')
  await key('keyDown', 'left')
  await b.sleep(400)
  await key('keyUp', 'left')
  await b.sleep(700)
  await shot('02left')
  await key('keyUp', 'up')
  for (let s = 0; s < secs * 2; s++) {
    if (s % 4 === 1) await key('keyDown', 'up')
    if (s % 4 === 2) await key('keyUp', 'up')
    await b.sleep(500)
    await shot(String(s + 10))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
