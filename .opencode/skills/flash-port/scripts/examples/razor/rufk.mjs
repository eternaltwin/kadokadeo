// The original in Ruffle, driven with the keyboard: a browser stays open and runs the commands appended to a file (one
// per line): "k <keyCode> <ms>" holds a key (37 left, 38 up, 39 right, 40 down, 32 space), "w <ms>" waits,
// "s <png>" takes a screenshot (600 x 600), "q" quits. The original's random cannot be seeded: one game per session.
// usage: node rufk.mjs <commands file> [swf]   env: RPORT (default 8794), PORT (default 9939), GPU=1 (Ruffle is slow without)
import { launch } from '../../harness/cdp.mjs'
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
const file = process.argv[2]
const swf = process.argv[3] || 'ref.swf'
writeFileSync(file, '')
const b = await launch(+(process.env.PORT || 9939))
const NAMES = { 37: 'ArrowLeft', 38: 'ArrowUp', 39: 'ArrowRight', 40: 'ArrowDown', 32: 'Space' }
const ev = (type, c) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: c, nativeVirtualKeyCode: c, key: c === 32 ? ' ' : NAMES[c], code: NAMES[c] })
let done = 0
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8794) + '/ref.html?swf=' + swf)
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  // the player gets the keyboard focus with a click (on the ground, where the game does nothing)
  for (const type of ['mousePressed', 'mouseReleased']) await b.send('Input.dispatchMouseEvent', { type, x: 300, y: 590, button: 'left', clickCount: 1 })
  console.log('ready', await b.eval('window.__err || "ok"'))
  for (; ;) {
    const lines = existsSync(file) ? readFileSync(file, 'utf8').split('\n').filter((l) => l.trim()) : []
    if (lines.length <= done) { await b.sleep(100); continue }
    const c = lines[done++].trim().split(/\s+/)
    if (c[0] === 'q') break
    if (c[0] === 's') { await b.screenshot(c[1], { x: 8, y: 8, width: 600, height: 600 }); console.log('shot', c[1]); continue }
    if (c[0] === 'w') { await b.sleep(+c[1]); continue }
    if (c[0] === 'k') { await ev('keyDown', +c[1]); await b.sleep(+c[2]); await ev('keyUp', +c[1]); continue }
  }
} finally {
  await b.close()
}
