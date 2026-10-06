// Judo Commando smoke test: loads the game, waits for the first level, runs right and jumps, screenshots.
// usage: node j0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 'j'
const b = await launch(+(process.env.PORT || 9891))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const shot = (n) => b.screenshot(gameDir('judocommando', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 600 })
try {
  await b.goto(HOST + '/game.html?game=judocommando&cls=GameJudoCommando&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  for (let s = 0; s < 6; s++) {
    await b.sleep(400)
    await shot('0' + s)
  }
  await b.waitFor('window.__state.step == "Play"', 20000)
  await shot('10play')
  await key('keyDown', 39, 'ArrowRight')
  for (let s = 0; s < secs * 2; s++) {
    await b.sleep(500)
    if (s == 3) { await key('keyDown', 32, ' '); await b.sleep(150); await key('keyUp', 32, ' ') }
    await shot(String(20 + s))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
  await key('keyUp', 39, 'ArrowRight')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
