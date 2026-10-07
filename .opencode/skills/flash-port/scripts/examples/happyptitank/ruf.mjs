// The original in Ruffle (ruffle/ruffle_site.sh, served on RPORT): screenshots of a game played by a script, real
// keyboard and mouse events (CDP). usage: node ruf.mjs <out prefix> "<commands>"
// commands (separated by spaces or ';'): "k:<key>:down" / "k:<key>:up" (ArrowUp, ArrowLeft, ..., KeyZ, Space...),
// "m:x,y" pointer moved to (x, y) stage pixels (0..300) in 4 steps, "p" / "r" press / release, "w:ms" wait,
// "s" screenshot <prefix>_<n>.png (600 x 600: the stage at x2), "s:name" -> <prefix>_<name>.png.
// The game starts at the first frame (Manager.init) and its time at the first arrow key.
// env: RPORT (default 8813), PORT (DevTools, default 9940), FIXED=1 (fixed step, see ruffle/Host.hx), GPU=1 (Ruffle is
// slow without)
import { launch } from '../../harness/cdp.mjs'
const out = process.argv[2]
const cmds = (process.argv[3] || 's').split(/[\s;]+/).filter(Boolean)
const KEYS = { ArrowLeft: 37, ArrowUp: 38, ArrowRight: 39, ArrowDown: 40, Space: 32, Enter: 13, Escape: 27, Delete: 46 }
const keyInfo = (code) => {
  if (KEYS[code]) return { code, key: code === 'Space' ? ' ' : code, windowsVirtualKeyCode: KEYS[code] }
  const c = code.replace(/^Key/, '').toUpperCase() // KeyZ or Z
  return { code: 'Key' + c, key: c.toLowerCase(), text: c.toLowerCase(), windowsVirtualKeyCode: c.charCodeAt(0) }
}
const b = await launch(+(process.env.PORT || 9940))
let n = 0, x = 150, y = 150, down = false
const ev = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const state = () => b.eval('JSON.stringify(window.__player.hptState())').catch((e) => String(e))
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8813) + '/ref.html' + (process.env.FIXED ? '?fixed=1' : ''))
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  if (await b.eval('window.__err || ""')) throw new Error(await b.eval('window.__err'))
  await b.waitFor('window.__player.hptState && window.__player.hptState().frame > 2', 30000)
  await b.eval('window.__player.focus()') // the keyboard events go to the focused player
  await ev('mouseMoved')
  for (const c of cmds) {
    const [op, a, d] = c.split(':')
    if (op === 's') {
      const f = out + '_' + (a || n++) + '.png'
      await b.screenshot(f, { x: 8, y: 8, width: 600, height: 600 })
      console.log(f, await state())
    } else if (op === 'p') { down = true; await ev('mousePressed') }
    else if (op === 'r') { down = false; await ev('mouseReleased') }
    else if (op === 'w') await b.sleep(+a)
    else if (op === 'k') await b.send('Input.dispatchKeyEvent', { type: d === 'up' ? 'keyUp' : 'rawKeyDown', ...keyInfo(a) })
    else if (op === 'm') {
      const [mx, my] = a.split(',').map(Number)
      const sx = x, sy = y
      for (let i = 1; i <= 4; i++) { x = sx + (mx - sx) * i / 4; y = sy + (my - sy) * i / 4; await ev('mouseMoved'); await b.sleep(15) }
    } else throw new Error('unknown command ' + c)
  }
} finally {
  for (const l of b.consoleLines) console.log('console', l)
  await b.close()
}
