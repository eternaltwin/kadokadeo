// Spiroule frame by frame (the physics stepped by hand): a staged combo. Once the chain is in, the colours of a few
// balls are set (debug build) so that the shot makes 3 balls explode (explosion, shards, wave), the two halves have the
// same colour at their ends (they attract: lightning between them, flashing balls), join and explode again (the "x2"
// multiplier); the shot is aimed and fired with real mouse events, then one screenshot per step. Only for the eye (the
// colours are changed by hand: no replay).
// usage: node pstep.mjs <out prefix> [count] [step]     env: HPORT, PORT, AT (frame to stage at)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const out = process.argv[2] || '/tmp/ps'
const count = +(process.argv[3] || 60)
const STEP = +(process.argv[4] || 1)
const b = await launch(+(process.env.PORT || 10320))
const OX = 8, OY = 8
const step = async (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) kk.updatePhysics(1000 / 32); kk.ff.alpha = 1; return kk.game.frameCount })()`)
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x: OX + x * 2, y: OY + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
// colours: 0 red, 1 yellow, 2 blue, 3 green; A shot, D the ends of the two halves
const STAGE = `(() => { const g = kk.game; const L = g.chains[0].list
  const set = (bl, c) => { bl.col = c; bl.root.gotoAndStop(c + 1) }
  // a ball of the outer ring, in the top half, with 4 balls on each side
  let i = -1
  for (let k = 4; k < L.length - 4; k++) if (L[k].y < 70 && L[k].x > 120 && L[k].x < 200) { i = k; break }
  if (i < 0) return null
  const cols = [3, 2, 2, 0, 0, 2, 1]
  for (let k = 0; k < cols.length; k++) set(L[i - 3 + k], cols[k])
  set(g.launcher.ball, 0)
  return JSON.stringify({ x: L[i].x, y: L[i].y }) })()`
try {
  await b.goto(HOST + '/game.html?game=spiroule&cls=GameSpiroule&seed=123')
  await b.waitFor('!!(window.kk && kk.game && kk.game.chains)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  const at = +(process.env.AT || 330)
  let t = null
  for (let f = 0; f < 3000; f++) {
    const fc = await step(1)
    if (fc >= at && (await b.eval('!!kk.game.launcher.ball'))) { t = await b.eval(STAGE); if (t) break }
  }
  if (!t) throw new Error('no ball to stage')
  t = JSON.parse(t)
  // aim (the launcher follows the pointer), then press and release
  await mouse('mouseMoved', t.x, t.y)
  await b.sleep(50); await step(2)
  await mouse('mousePressed', t.x, t.y, true)
  await b.sleep(50); await step(1)
  await mouse('mouseReleased', t.x, t.y, false)
  for (let i = 0; i < count; i++) {
    await b.sleep(100)
    await b.screenshot(out + String(i).padStart(3, '0') + '.png', { x: OX, y: OY, width: 600, height: 600 })
    await step(STEP)
  }
  console.log(await b.eval('JSON.stringify(kk.game.stats)'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
