// The original in Ruffle (ruffle/ruffle_site.sh) slowed down: a ref swf of ref_swf.py (ref_pa.swf: the designed board
// a of the test mode), up held for one frame (the slice), then screenshots as fast as possible: every frame of what
// follows, to compare with the port's frames (step.mjs with the same test mode). Duplicates are left to the caller.
// usage: node rburst.mjs <swf> <out prefix> [ms] [fr]   fr: frame rate of Ruffle (default 4); env: RPORT (default 8794),
//        PORT (default 9940), KEY (default 38: up), WAIT (frames before the key, default 3), GPU=1
import { launch } from '../../harness/cdp.mjs'
const [swf, out, ms = '6000', fr = '4'] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9940))
const NAMES = { 37: 'ArrowLeft', 38: 'ArrowUp', 39: 'ArrowRight' }
const key = +(process.env.KEY || 38)
const ev = (type) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: key, nativeVirtualKeyCode: key, key: NAMES[key], code: NAMES[key] })
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8794) + '/ref.html?swf=' + swf + '&fr=' + fr)
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  // the player gets the keyboard focus with a click (on the bottom of the background: the game reads no mouse)
  for (const type of ['mousePressed', 'mouseReleased']) await b.send('Input.dispatchMouseEvent', { type, x: 300, y: 590, button: 'left', clickCount: 1 })
  await b.sleep(1000 * +(process.env.WAIT || 3) / +fr)
  let n = 0
  const shot = () => b.screenshot(out + String(n++).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
  await shot()
  await ev('keyDown')
  await b.sleep(1000 / +fr)
  await ev('keyUp')
  const t0 = Date.now()
  while (Date.now() - t0 < +ms) await shot()
  console.log(n, 'shots')
} finally {
  await b.close()
}
