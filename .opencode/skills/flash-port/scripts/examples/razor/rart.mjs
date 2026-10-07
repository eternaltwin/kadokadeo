// Razor start screen candidates: a combo of a test board (PAT, default c: "MONSTRUEUX!") stepped by hand, a shot every
// STEP steps once up is pressed (the razor in the fruits, the trail, the pieces, then the comment). The chosen one is
// $KKP_WORK/razor/art/<PAT><n>.png, written as public/assets/img/gfx/artwork/razor.jpg by razor_artwork.py.
// usage: node rart.mjs      env: PAT, STEP (default 3), N (shots, default 30), PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9945))
const dir = gameDir('razor', 'art')
const pat = process.env.PAT || 'c'
const step = (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) kk.updatePhysics(1000 / 32); kk.ff.alpha = 1; return kk.game.frameCount })()`)
const key = (type) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: 38, nativeVirtualKeyCode: 38, key: 'ArrowUp', code: 'ArrowUp' })
try {
  await b.goto(HOST + '/game.html?game=razor&cls=GameRazor&seed=' + (process.env.SEED || 123) + '&test=rz&pat=' + pat)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  await step(4)
  await key('keyDown'); await b.sleep(50); await step(1); await key('keyUp'); await b.sleep(50); await step(1)
  for (let i = 0; i < +(process.env.N || 30); i++) {
    await b.sleep(120)
    await b.screenshot(dir + `/${pat}${i}.png`, { x: 8, y: 8, width: 600, height: 600 })
    await step(+(process.env.STEP || 3))
  }
} finally {
  await b.close()
}
