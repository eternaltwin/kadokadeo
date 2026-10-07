// Phagocytoz smoke test: loads the game, waits for the title, then steers the hero with the mouse (pressed and
// released), screenshots every half second.
// usage: node p0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9861))
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const shot = (n) => b.screenshot(gameDir('phagocytoz', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
try {
  await b.goto(HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await shot('00')
  for (let i = 1; i <= 6; i++) {
    await b.sleep(350)
    await shot('0' + i)
  }
  console.log(await b.eval('JSON.stringify(window.__state)'))
  await mouse('mouseMoved', 220, 80, false)
  for (let s = 0; s < secs * 2; s++) {
    const down = (s % 4) < 2
    const x = 150 + 100 * Math.cos(s * 0.7), y = 150 + 100 * Math.sin(s * 0.7)
    await mouse(down ? 'mousePressed' : 'mouseReleased', x, y, down)
    await mouse('mouseMoved', x, y, down)
    await b.sleep(500)
    await shot(String(s + 10))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 8).join('\n').slice(0, 4000))
  await b.close()
}
