// The original Memopsy in Ruffle next to the port: the same scenario on both (the start, a card pressed, the flip
// caught mid-way, the face shown, a second press, the mismatch flipping back), one screenshot each in
// $KKP_WORK/memopsy/check/ruffle/. The original's random cannot be seeded: the faces differ, the timing and the
// drawing are what is compared. Run with GPU=1 (Ruffle is very slow on the software renderer).
// usage: GPU=1 node mruf.mjs      env: PORT (DevTools, 10590), HPORT (the port's harness, 8785), RPORT (ruffle_site.sh, 8797)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { mkdirSync } from 'node:fs'
const PORT = +(process.env.PORT || 10590)
const RPORT = +(process.env.RPORT || 8797)
const OUT = gameDir('memopsy', 'check', 'ruffle')
mkdirSync(OUT, { recursive: true })
// level 1 card centres (4 x 2): px = 54, py = 88, +21 / +32
const cell = (x, y) => [54 + x * 50 + 21, 88 + y * 70 + 32]

async function scenario(b, name, click, shotOpts) {
  const shoot = (tag) => b.screenshot(OUT + '/' + name + '_' + tag + '.png', shotOpts)
  await b.sleep(2500)
  await shoot('start')
  await click(...cell(0, 0))
  await b.sleep(100)
  await shoot('flip')
  await b.sleep(400)
  await shoot('face')
  await click(...cell(1, 0))
  await b.sleep(400)
  await shoot('two')
  await b.sleep(700)
  await shoot('back')
  await b.sleep(1200)
  await shoot('end')
}

// the original in Ruffle (600 x 600, x2 like the port)
let b = await launch(PORT)
try {
  await b.goto('http://127.0.0.1:' + RPORT + '/ref.html?swf=ref.swf')
  await b.waitFor('!!window.__loaded', 60000)
  const click = async (x, y) => {
    await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + 2 * x, y: 8 + 2 * y, buttons: 0 })
    await b.sleep(40)
    await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + 2 * x, y: 8 + 2 * y, button: 'left', buttons: 1, clickCount: 1 })
    await b.sleep(60)
    await b.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 8 + 2 * x, y: 8 + 2 * y, button: 'left', buttons: 0, clickCount: 1 })
  }
  await scenario(b, 'ruf', click, { x: 8, y: 8, width: 600, height: 600 })
} finally {
  await b.close()
}
// the port, same clicks
b = await launch(PORT + 1)
try {
  await b.goto(HOST + '/game.html?game=memopsy&cls=GameMemopsy&seed=123')
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  const click = async (x, y) => {
    await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + 2 * x, y: 8 + 2 * y, buttons: 0 })
    await b.sleep(40)
    await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + 2 * x, y: 8 + 2 * y, button: 'left', buttons: 1, clickCount: 1 })
    await b.sleep(60)
    await b.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 8 + 2 * x, y: 8 + 2 * y, button: 'left', buttons: 0, clickCount: 1 })
  }
  await scenario(b, 'port', click, { x: 8, y: 8, width: 600, height: 600 })
} finally {
  await b.close()
}
console.log(OUT)
