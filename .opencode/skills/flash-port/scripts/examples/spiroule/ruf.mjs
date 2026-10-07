// The same mouse scenario on the original in Ruffle and on the port, screenshots at the same times (side by side
// pictures: the original's random cannot be seeded, the chains differ, the pictures and effects can be compared):
// the start (sparks running down the spiral, the chain coming in), then shots aimed at fixed points, a screenshot while
// the ball flies and after it hit.
// usage: node ruf.mjs ruffle|port <out prefix> [shots]   env: RPORT (Ruffle site, 8808), HPORT (harness, 8807),
//        PORT (DevTools, 9977), GPU=1 (Ruffle is very slow on the software renderer), EXTRA (port url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const which = process.argv[2] || 'ruffle'
const pre = process.argv[3] || '/tmp/r'
const n = +(process.argv[4] || 8)
const b = await launch(+(process.env.PORT || 9977))
const OX = 8, OY = 8
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x: OX + x * 2, y: OY + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const shot = (s) => b.screenshot(pre + s + '.png', { x: OX, y: OY, width: 600, height: 600 })
// targets in Flash pixels: on the rings of the spiral, around the launcher
const T = [[250, 120], [60, 140], [150, 30], [240, 230], [40, 200], [200, 45], [110, 260], [270, 170], [70, 70], [230, 80]]
try {
  if (which === 'ruffle') {
    await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8808) + '/ref.html?swf=ref.swf')
    await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  } else {
    await b.goto(HOST + '/game.html?game=spiroule&cls=GameSpiroule&seed=123' + (process.env.EXTRA || ''))
    await b.waitFor('!!(window.kk && kk.game && kk.game.chains)', 60000)
  }
  await mouse('mouseMoved', 260, 150)
  await sleep(500)
  await shot('00')
  await sleep(700)
  await shot('01')
  await sleep(1500)
  await shot('02')
  for (let i = 0; i < n; i++) {
    const [x, y] = T[i % T.length]
    await mouse('mouseMoved', x, y)
    await sleep(120)
    await mouse('mousePressed', x, y, true)
    await sleep(60)
    await mouse('mouseReleased', x, y, false)
    await sleep(90)
    await shot('1' + i + 'a')
    await sleep(250)
    await shot('1' + i + 'b')
    await sleep(500)
  }
  await sleep(3000)
  await shot('20')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 2000))
  await b.close()
}
