// quick look: a game page, a few screenshots while keys are held (KEYS: a list of key:frames, e.g. "39:20,38:5")
//   node d0.mjs [out prefix]       env: PORT (DevTools), HPORT (harness), KEYS
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = process.argv[2] || gameDir('razor', 'shots') + '/d0'
const b = await launch(+(process.env.PORT || 9931))
const K = { 37: 'ArrowLeft', 38: 'ArrowUp', 39: 'ArrowRight', 40: 'ArrowDown', 32: ' ' }
const key = (t, c) => b.send('Input.dispatchKeyEvent', { type: t, windowsVirtualKeyCode: c, nativeVirtualKeyCode: c, key: K[c], code: c == 32 ? 'Space' : K[c] })
try {
  await b.goto(HOST + '/game.html?game=razor&cls=GameRazor&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(1500)
  await b.screenshot(out + '_0.png', { x: 8, y: 8, width: 600, height: 640 })
  let i = 1
  for (const kf of (process.env.KEYS || '').split(',').filter(Boolean)) {
    const [c, n] = kf.split(':').map(Number)
    await key('keyDown', c)
    await b.sleep(n * 1000 / 40)
    await key('keyUp', c)
    await b.sleep(+(process.env.WAIT || 400))
    await b.screenshot(out + '_' + (i++) + '.png', { x: 8, y: 8, width: 600, height: 640 })
  }
  console.log(await b.eval('JSON.stringify(window.__state)'))
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|unknown/i.test(l)).slice(0, 8).join('\n').slice(0, 3000))
  await b.close()
}
