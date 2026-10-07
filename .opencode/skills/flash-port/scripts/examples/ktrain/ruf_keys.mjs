// The original in Ruffle (or the port in the harness), driven with the keyboard by hand: a browser stays open and runs
// the commands appended to a file (one per line): "d <key>" / "u <key>" key down / up (Left, Right, Up, Down, Space),
// "t <key> [ms]" a tap (down, wait, up), "w ms" waits, "s <png>" takes a screenshot (600 x 600), "o" reloads the game,
// "e <js>" prints the value of an expression, "c [n]" the last lines of the console, "q" quits. The
// original's random cannot be seeded: one game per session, explored with screenshots.
// usage: node ruf_keys.mjs <commands file> [swf | url]   env: RPORT (default 8792), PORT (default 9880), GPU=1
import { launch } from '../../harness/cdp.mjs'
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
const file = process.argv[2]
const swf = process.argv[3] || 'ref.swf'
writeFileSync(file, '')
const b = await launch(+(process.env.PORT || 9880))
const KEYS = {
  Left: [37, 'ArrowLeft'], Right: [39, 'ArrowRight'], Up: [38, 'ArrowUp'], Down: [40, 'ArrowDown'], Space: [32, ' ', 'Space'],
}
const key = (type, k) => {
  const [code, name, c] = KEYS[k]
  return b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: name, code: c || name })
}
let done = 0
const open = async () => {
  if (swf.startsWith('http')) {
    await b.goto(swf)
    await b.waitFor('!!(window.kk && kk.game)', 60000)
  } else {
    await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8792) + '/ref.html?swf=' + swf)
    await b.waitFor('!!(window.__loaded || window.__err)', 60000)
    // the keyboard goes to the focused player
    await b.click(8 + 300, 8 + 300)
  }
  console.log('ready')
}
try {
  await open()
  for (; ;) {
    const lines = existsSync(file) ? readFileSync(file, 'utf8').split('\n').filter((l) => l.trim()) : []
    if (lines.length <= done) { await b.sleep(100); continue }
    const c = lines[done++].trim().split(/\s+/)
    if (c[0] === 'q') break
    if (c[0] === 'o') { await open(); continue }
    if (c[0] === 'c') { console.log(b.consoleLines.splice(0).slice(-(+c[1] || 20)).join('\n')); continue }
    if (c[0] === 's') { await b.screenshot(c[1], { x: 8, y: 8, width: 600, height: 600 }); console.log('shot', c[1]); continue }
    if (c[0] === 'd') { await key('rawKeyDown', c[1]); continue }
    if (c[0] === 'u') { await key('keyUp', c[1]); continue }
    if (c[0] === 't') { await key('rawKeyDown', c[1]); await b.sleep(+(c[2] || 80)); await key('keyUp', c[1]); continue }
    if (c[0] === 'w') { await b.sleep(+c[1]); continue }
    if (c[0] === 'e') { console.log('eval', await b.eval(c.slice(1).join(' '))); continue }
  }
} finally {
  await b.close()
}
