// The original in Ruffle (ruffle/ruffle_site.sh on RPORT) slowed down to FR frames/s with a fixed step: a screenshot
// at each frame listed (Host.hx counts the frames from Manager.init). Pairs with pframes.mjs.
// usage: node rframes.mjs <out prefix> <frame,frame,...>     env: RPORT (8792), PORT (9866), FR (3), GPU=1
//        MOUSE=x,y (stage pixels), PRESS=F (button pressed from frame F)
import { launch } from '../../harness/cdp.mjs'
const out = process.argv[2]
const frames = (process.argv[3] || '1').split(',').map(Number)
const b = await launch(+(process.env.PORT || 9866))
const [mx, my] = (process.env.MOUSE || '150,150').split(',').map(Number)
const state = () => b.eval('JSON.parse(JSON.stringify(window.__player.pState()))')
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8792) + '/ref.html?fixed=1&fr=' + (process.env.FR || 3))
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + mx * 2, y: 8 + my * 2, button: 'none', pointerType: 'mouse' })
  let pressed = false
  for (const target of frames) {
    for (;;) {
      const s = await state().catch(() => null)
      const f = s ? s.frame : 0
      if (process.env.PRESS && !pressed && f >= +process.env.PRESS - 1) {
        pressed = true
        await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + mx * 2, y: 8 + my * 2, button: 'left', buttons: 1, clickCount: 1, pointerType: 'mouse' })
      }
      if (f >= target) {
        if (f > target) console.log('late', target, f)
        break
      }
      await b.sleep(20)
    }
    await b.screenshot(`${out}_${target}.png`, { x: 8, y: 8, width: 600, height: 600 })
    console.log(target, JSON.stringify(await state()))
  }
} finally {
  await b.close()
}
