// The original in Ruffle (or the port): mouse moves / presses, then the values logged by the ref SWF (env LOG of
// ref_swf.py) or by an expression on the port's page (env PEXPR, every frame of the script).
// usage: node rclick.mjs <ruffle|port> <out prefix> "x,y,ms;p;r;s;w,ms..."  (Flash pixels)
//   env: RPORT (8797), HPORT (8798), PORT (DevTools, 9963), GPU=1, EXTRA (port url)
import { launch } from '../../harness/cdp.mjs'
import fs from 'fs'
const which = process.argv[2]
const out = process.argv[3]
const moves = (process.argv[4] || 's').split(';')
const b = await launch(+(process.env.PORT || 9963))
let n = 0, x = 150, y = 150, down = false
const ev = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x * 2, y: 8 + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
try {
  if (which === 'port') {
    await b.goto('http://127.0.0.1:' + (process.env.HPORT || 8798) + '/game.html?game=toymaniak&cls=GameToyManiak&seed=123' + (process.env.EXTRA || ''))
    await b.waitFor('!!(window.kk && kk.game && kk.game.rails)', 60000)
  } else {
    await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8797) + '/ref.html?swf=' + (process.env.SWF || 'ref.swf'))
    await b.waitFor('!!(window.__loaded || window.__err)', 60000)
    await b.sleep(500)
  }
  const plog = []
  for (const m of moves) {
    if (m === 's') { await b.screenshot(out + '_' + (n++) + '.png', { x: 8, y: 8, width: 600, height: 600 }); continue }
    if (m === 'p') { down = true; await ev('mousePressed'); continue }
    if (m === 'r') { down = false; await ev('mouseReleased'); continue }
    if (m.startsWith('w,')) { await b.sleep(+m.slice(2)); continue }
    if (m === 'l' && process.env.PEXPR) { plog.push(await b.eval(process.env.PEXPR)); continue }
    const [mx, my, ms] = m.split(',').map(Number)
    const sx = x, sy = y
    for (let i = 1; i <= 4; i++) { x = sx + (mx - sx) * i / 4; y = sy + (my - sy) * i / 4; await ev('mouseMoved'); await b.sleep(15) }
    await b.sleep(ms || 0)
  }
  if (which === 'port') {
    fs.writeFileSync(out + '_log.json', JSON.stringify(plog))
    for (const l of plog) console.log(JSON.stringify(l))
  } else {
    const log = JSON.parse(await b.eval('JSON.stringify(window.__log || [])'))
    fs.writeFileSync(out + '_log.json', JSON.stringify(log))
    for (const l of log.slice(-8)) console.log(JSON.stringify(l))
  }
  console.log(b.consoleLines.filter(l => /EXCEPTION/.test(l)).slice(0, 5).join('\n'))
} finally {
  await b.close()
}
