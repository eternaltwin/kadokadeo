// frame by frame screenshots: the physics is stepped by hand until a condition, then one screenshot per step
// usage: node step.mjs <pkg> <Class> <out prefix> <condition js> <count> [extra query]
//   env: STEP (frames per shot), KEYS (js run before each step), PRE (js run once), PRESS (keyCode,key pressed once), HPORT, PORT
//   e.g. node step.mjs kslash GameKSlash /tmp/ks 'kk.game.frameCount > 100' 8
import { launch } from './cdp.mjs'
const [pkg, cls, out, cond, count = '6', extra = ''] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9820))
const step = async (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) { ${process.env.KEYS || ''}; kk.updatePhysics(1000 / 32) } kk.ff.alpha = 1; return kk.game ? kk.game.frameCount : -1 })()`)
try {
  await b.goto(`http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&seed=` + (process.env.SEED || '123') + extra)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  if (process.env.PRE) await b.eval(process.env.PRE)
  let f = 0
  while (!(await b.eval(cond))) { f = await step(1); if (f > 20000) throw new Error('condition never met') }
  if (process.env.PRESS) {
    const [code, key] = process.env.PRESS.split(',')
    await b.send('Input.dispatchKeyEvent', { type: 'keyDown', windowsVirtualKeyCode: +code, nativeVirtualKeyCode: +code, key, code: key })
    await b.sleep(50); await step(1)
    await b.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: +code, nativeVirtualKeyCode: +code, key, code: key })
    await b.sleep(50); await step(1)
  }
  for (let i = 0; i < +count; i++) {
    await b.sleep(120)
    await b.screenshot(out + i + '.png', { x: 8, y: 8, width: 600, height: 640 })
    await step(+(process.env.STEP || 1))
  }
  console.log('frame', f)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
