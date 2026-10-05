// Schizo Fuzz smoke test: loads the game, charges the catapult (Space held), aims, launches, steers, screenshots.
// usage: node s0.mjs [seconds] [shots prefix]     env: PORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9710))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const shot = (n) => b.screenshot(gameDir('schizofuzz', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 600 })
try {
  await b.goto(HOST + '/game.html?game=schizofuzz&cls=GameSchizoFuzz&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(500)
  await shot('00wait')
  await key('keyDown', 32, ' ')
  await b.sleep(300)
  await key('keyUp', 32, ' ')
  await b.sleep(200)
  await key('keyDown', 32, ' ')
  await b.sleep(400)
  await shot('01charge')
  await key('keyUp', 32, ' ')
  await b.sleep(700)
  await shot('02aim')
  await key('keyDown', 32, ' ')
  await b.sleep(100)
  await key('keyUp', 32, ' ')
  for (let s = 0; s < secs * 2; s++) {
    await b.sleep(500)
    await shot(String(s + 10))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
