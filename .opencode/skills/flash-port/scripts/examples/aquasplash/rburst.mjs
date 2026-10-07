// The original in Ruffle (ruffle_site.sh): screenshots as fast as possible from the load of a ref swf (ref_next.swf:
// the level transition from the start), to compare an animation the port plays frame by frame.
// usage: node rburst.mjs <swf> <out prefix> [ms] [fr]   fr: frame rate of Ruffle (ref.html); env: RPORT (default 8783),
//        PORT, PRESS=x,y[,n] (n mouse presses (1) at that stage point once loaded: ref_swf.py press:<method>)
import { launch } from '../../harness/cdp.mjs'
const [swf, out, ms = '2500', fr = ''] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9964))
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8783) + '/ref.html?swf=' + swf + (fr ? '&fr=' + fr : ''))
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  await b.sleep(1000)
  if (process.env.PRESS) {
    const [x, y, n = 1] = process.env.PRESS.split(',').map(Number)
    const ev = (type, buttons) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: 'left', buttons, clickCount: 1, pointerType: 'mouse' })
    for (let i = 0; i < n; i++) {
      await ev('mousePressed', 1)
      await ev('mouseReleased', 0)
    }
  }
  const t0 = Date.now()
  let n = 0
  while (Date.now() - t0 < +ms) await b.screenshot(out + String(n++).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
  console.log(n, 'shots')
} finally {
  await b.close()
}
