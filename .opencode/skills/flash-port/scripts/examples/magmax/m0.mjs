// Magmax smoke test: loads the game, moves and shoots with real key presses, screenshots every second.
// usage: node m0.mjs [seconds] [shots prefix]     env: PORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 6)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9700))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(HOST + '/game.html?game=magmax&cls=GameMagmax&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  const seq = [[39, 'ArrowRight'], [40, 'ArrowDown'], [37, 'ArrowLeft'], [38, 'ArrowUp']]
  await key('keyDown', 32, ' ')
  for (let s = 0; s < secs; s++) {
    const [c, k] = seq[s % 4]
    await key('keyDown', c, k)
    await b.sleep(500)
    await b.screenshot(gameDir('magmax', 'shots') + `/${pre}${String(s).padStart(2, '0')}.png`, { x: 8, y: 8, width: 600, height: 600 })
    await b.sleep(500)
    await key('keyUp', c, k)
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
