// The port stepped Flash frame by Flash frame (test=hold), a screenshot at each frame listed: the state of that
// frame, as the original showed it (display(1)). Pairs with rframes.mjs (the original in Ruffle, same frames).
// usage: node pframes.mjs <out prefix> <frame,frame,...>     env: PORT (default 9864), HPORT, EXTRA (url params),
//        MOUSE=x,y (stage pixels, the mouse during the frames), PRESS=F (button pressed from frame F)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const out = process.argv[2]
const frames = (process.argv[3] || '1').split(',').map(Number)
const b = await launch(+(process.env.PORT || 9864))
try {
  await b.goto(HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123&test=hold' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.root)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  if (process.env.MOUSE) {
    const [x, y] = process.env.MOUSE.split(',').map(Number)
    await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + x * 2, y: 8 + y * 2, button: 'none', pointerType: 'mouse' })
  }
  // the constructor played Flash frame 1; KadoKadeo's steps (inputs polled, 15 Flash frames per 16 steps) until the
  // frame wanted
  // (steps run in the page, at most 60 per call: few round trips)
  const upTo = (f) => b.eval(`(() => { let n = 0; while (kk.game.frameCount < ${f} && n++ < 60) { window.__hold = false; kk.updatePhysics(1000 / 32); window.__hold = true } return kk.game.frameCount })()`)
  const press = process.env.PRESS ? +process.env.PRESS : 0
  let pressed = false
  for (const target of frames) {
    for (let f = await b.eval('kk.game.frameCount'); f < target;) {
      if (press && !pressed && f + 1 >= press) {
        pressed = true
        const [x, y] = (process.env.MOUSE || '150,150').split(',').map(Number)
        await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + x * 2, y: 8 + y * 2, button: 'left', buttons: 1, clickCount: 1, pointerType: 'mouse' })
        await b.sleep(50)
      }
      f = await upTo(press && !pressed ? Math.min(target, press - 1) : target)
    }
    await b.eval('kk.game.display(1); kk.ff.alpha = 1')
    await b.sleep(150)
    await b.screenshot(`${out}_${target}.png`, { x: 8, y: 8, width: 600, height: 600 })
    console.log(target, await b.eval('JSON.stringify(window.__state || {})'))
  }
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
