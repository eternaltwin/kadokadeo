// The original in Ruffle, driven by hand: a browser stays open and runs the commands appended to a file (one per
// line): "m x y [ms]" moves the pointer to (x, y) stage pixels in 4 steps then waits, "p" / "r" press / release,
// "w ms" waits, "s <png>" takes a screenshot (600 x 600), "q" quits. The original's random cannot be seeded: one map
// per session, explored with screenshots.
// usage: node ruf_live.mjs <commands file> [swf | url]   env: RPORT (default 8782), PORT, GPU=1 (Ruffle is slow without)
// (an url: the same commands on another page, the port in the harness: the canvas at (8, 8) too)
import { launch } from '../../harness/cdp.mjs'
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
const file = process.argv[2]
const swf = process.argv[3] || 'ref.swf'
writeFileSync(file, '')
const b = await launch(+(process.env.PORT || 9867))
let x = 150, y = 150, down = false, done = 0
const ev = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
try {
  if (swf.startsWith('http')) {
    await b.goto(swf)
    await b.waitFor('!!(window.kk && kk.game)', 60000)
  } else {
    await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8782) + '/ref.html?swf=' + swf)
    await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  }
  console.log('ready')
  for (; ;) {
    const lines = existsSync(file) ? readFileSync(file, 'utf8').split('\n').filter((l) => l.trim()) : []
    if (lines.length <= done) { await b.sleep(150); continue }
    const c = lines[done++].trim().split(/\s+/)
    if (c[0] === 'q') break
    if (c[0] === 's') { await b.screenshot(c[1], { x: 8, y: 8, width: 600, height: 600 }); console.log('shot', c[1]); continue }
    if (c[0] === 'p') { down = true; await ev('mousePressed'); continue }
    if (c[0] === 'r') { down = false; await ev('mouseReleased'); continue }
    if (c[0] === 'w') { await b.sleep(+c[1]); continue }
    if (c[0] === 'm') {
      const sx = x, sy = y, mx = +c[1], my = +c[2]
      for (let i = 1; i <= 4; i++) { x = sx + (mx - sx) * i / 4; y = sy + (my - sy) * i / 4; await ev('mouseMoved'); await b.sleep(15) }
      if (c[3]) await b.sleep(+c[3])
    }
  }
} finally {
  await b.close()
}
