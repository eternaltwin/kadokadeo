// Cereal Punk: scenario a (modes/cerealpunk.js) played step by step with real key events, a screenshot every few steps:
// the cook takes two cereals (hands), throws them on the full column (one explodes in a group of 3, one flies away), the
// bonus next to them is destroyed, the score drops down; then he takes the 5000 bonus.
// usage: node cpstep.mjs [out prefix]     env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const pre = process.argv[2] || gameDir('cerealpunk', 'step') + '/a'
const b = await launch(+(process.env.PORT || 9879))
const KEYS = { up: [38, 'ArrowUp'], down: [40, 'ArrowDown'], left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][1] })
const step = (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) kk.updatePhysics(1000 / 32); kk.ff.alpha = 1; return kk.game.frameCount })()`)
let n = 0
const shot = async (label) => { await b.sleep(80); await b.screenshot(`${pre}${String(n++).padStart(2, '0')}.png`, { x: 8, y: 8, width: 600, height: 640 }); console.log(n - 1, label, await b.eval('kk.game.frameCount')) }
const press = async (k) => { await key('keyDown', k); await b.sleep(30); await step(1); await key('keyUp', k); await b.sleep(30); await step(1) }
try {
  await b.goto(HOST + '/game.html?game=cerealpunk&cls=GameCerealPunk&seed=123&test=cp&setup=a&hold=100000')
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  await step(8); await shot('start')
  await press('up'); for (let i = 0; i < 6; i++) { await step(2); await shot('take ' + i) }
  await step(20); await shot('held')
  await press('right'); for (let i = 0; i < 3; i++) { await step(3); await shot('jump ' + i) }
  await step(16)
  await press('down'); for (let i = 0; i < 16; i++) { await step(2); await shot('throw ' + i) }
  await step(20); await press('left'); await step(12); await press('left'); await step(14)
  await press('up'); for (let i = 0; i < 8; i++) { await step(2); await shot('bonus ' + i) }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
