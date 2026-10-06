// The original in Ruffle (ref_swf.py, served with rufflesite/ by RPORT): screenshots of a game, the pointer moved by
// a script. usage: node ruf.mjs <swf> <out prefix> [moves]   moves: "x,y,ms;x,y,ms;..." (stage pixels, wait after),
// "p" / "r" for press / release, "s" for a screenshot   env: RPORT (default 8782), PORT
import { launch } from '../../harness/cdp.mjs'
const swf = process.argv[2] || 'ref.swf'
const out = process.argv[3]
const moves = (process.argv[4] || 's').split(';')
const b = await launch(+(process.env.PORT || 9864))
let n = 0, x = 150, y = 150, down = false
const ev = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8782) + '/ref.html?swf=' + swf)
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  await b.sleep(1500)
  for (const m of moves) {
    if (m === 's') { await b.screenshot(out + '_' + (n++) + '.png', { x: 8, y: 8, width: 600, height: 600 }); continue }
    if (m === 'p') { down = true; await ev('mousePressed'); continue }
    if (m === 'r') { down = false; await ev('mouseReleased'); continue }
    const [mx, my, ms] = m.split(',').map(Number)
    const sx = x, sy = y
    for (let i = 1; i <= 4; i++) { x = sx + (mx - sx) * i / 4; y = sy + (my - sy) * i / 4; await ev('mouseMoved'); await b.sleep(15) }
    await b.sleep(ms || 0)
  }
} finally {
  await b.close()
}
