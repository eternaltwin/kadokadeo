// Aqua Splash: opens a game and takes screenshots (start, after a few seconds), prints the page errors.
// usage: node a0.mjs [seed] [out prefix]     env: HPORT (harness server), PORT (DevTools), EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const seed = process.argv[2] || '123'
const out = process.argv[3] || gameDir('aquasplash', 'shots') + '/a0'
const b = await launch(+(process.env.PORT || 9960))
try {
  await b.goto(HOST + '/game.html?game=aquasplash&cls=GameAquaSplash&seed=' + seed + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.mcTime)', 60000)
  await b.sleep(1500)
  await b.screenshot(out + '_a.png', { x: 8, y: 8, width: 600, height: 640 })
  // hover a slime, then click it
  await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + 140, y: 8 + 140, button: 'none', buttons: 0, pointerType: 'mouse' })
  await b.sleep(300)
  await b.screenshot(out + '_b.png', { x: 8, y: 8, width: 600, height: 640 })
  await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + 140, y: 8 + 140, button: 'left', buttons: 1, clickCount: 1, pointerType: 'mouse' })
  await b.sleep(60)
  await b.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 8 + 140, y: 8 + 140, button: 'left', buttons: 0, clickCount: 1, pointerType: 'mouse' })
  await b.sleep(250)
  await b.screenshot(out + '_c.png', { x: 8, y: 8, width: 600, height: 640 })
  await b.sleep(4000)
  await b.screenshot(out + '_d.png', { x: 8, y: 8, width: 600, height: 640 })
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
