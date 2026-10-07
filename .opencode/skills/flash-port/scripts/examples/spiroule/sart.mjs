// Spiroule start screen candidates (the physics stepped by hand): the chain far along the spiral, then a ball shot
// towards its outer ring, one picture per step while it flies (its trail of sparks). The chosen one is
// $KKP_WORK/spiroule/art/<name>.png, written as public/assets/img/gfx/artwork/spiroule.jpg by:
//   python3 -c "from PIL import Image; Image.open('<png>').convert('RGB').save('<repo>/public/assets/img/gfx/artwork/spiroule.jpg', quality=92)"
// usage: node sart.mjs [aim x] [aim y] [top of the chain]     env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const ax = +(process.argv[2] || 262), ay = +(process.argv[3] || 70), top = +(process.argv[4] || 0.42)
const b = await launch(+(process.env.PORT || 10340))
const dir = gameDir('spiroule', 'art')
const OX = 8, OY = 8
const step = async (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) kk.updatePhysics(1000 / 32); kk.ff.alpha = 1; return kk.game.frameCount })()`)
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x: OX + x * 2, y: OY + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
try {
  // (a faster chain: it fills the spiral sooner, see modes/spiroule.js)
  await b.goto(HOST + '/game.html?game=spiroule&cls=GameSpiroule&seed=123&test=sp&spd=0.0010')
  await b.waitFor('!!(window.kk && kk.game && kk.game.chains)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  await mouse('mouseMoved', ax, ay)
  for (let f = 0; f < 4000; f++) {
    await step(1)
    const t = await b.eval('(() => { const c = kk.game.chains[0]; return c.pos - c.list.length * 0.0185 })()')
    if (t < top && (await b.eval('!!kk.game.launcher.ball'))) break
  }
  await step(2)
  await mouse('mousePressed', ax, ay, true)
  await b.sleep(50); await step(1)
  await mouse('mouseReleased', ax, ay, false)
  for (let i = 0; i < 10; i++) {
    await b.sleep(100)
    await b.screenshot(dir + `/f${i}.png`, { x: OX, y: OY, width: 600, height: 600 })
    await step(1)
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
