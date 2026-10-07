// Happy Pti Tank smoke test: loads the game, drives the tank with the arrows, aims and fires with the mouse,
// screenshots every half second.
// usage: node h0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9931))
const KEYS = { up: [38, 'ArrowUp'], down: [40, 'ArrowDown'], left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][1] })
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const shot = (n) => b.screenshot(gameDir('happyptitank', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
try {
  await b.goto(HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(600)
  await shot('00start')
  console.log(await b.eval('JSON.stringify(window.__state)'))
  await mouse('mouseMoved', 220, 80, false)
  await key('keyDown', 'right')
  await b.sleep(900)
  await shot('01right')
  await mouse('mousePressed', 220, 80, true)
  await key('keyDown', 'up')
  await b.sleep(500)
  await key('keyUp', 'right')
  await shot('02up')
  for (let s = 0; s < secs * 2; s++) {
    const k = ['up', 'left', 'down', 'right'][Math.floor(s / 3) % 4]
    if (s % 3 === 0) { for (const kk of Object.keys(KEYS)) await key('keyUp', kk); await key('keyDown', k) }
    await mouse('mouseMoved', 150 + 100 * Math.cos(s), 150 + 100 * Math.sin(s), true)
    await b.sleep(500)
    await shot(String(s + 10))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 8).join('\n').slice(0, 4000))
  await b.close()
}
