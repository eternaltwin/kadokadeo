// Hypercube: first look. Loads the game, takes the first piece of the conveyor, puts it on the board and saves
// screenshots ($KKP_WORK/hypercube/shots/h0_*.png).
// usage: node h0.mjs        env: PORT (DevTools, default 9931), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const PORT = +(process.env.PORT || 9931)
const D = gameDir('hypercube', 'shots')
const b = await launch(PORT)
const mouse = (type, x, y, buttons = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x, y: 8 + y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1 })
const shot = (n) => b.screenshot(D + '/h0_' + n + '.png', { x: 8, y: 8, width: 600, height: 640 })
try {
  await b.goto(HOST + '/game.html?game=hypercube&cls=GameHypercube&seed=123')
  await b.waitFor('!!(window.kk && kk.game && kk.game.pieceList)', 60000)
  await b.sleep(2500)
  await shot('a')
  // the first piece of the conveyor (Flash px -> canvas px: x2)
  const p = JSON.parse(await b.eval('JSON.stringify(kk.game.pieceList.map(p => [p.root._x, p.root._y]))'))
  console.log('pieces', JSON.stringify(p))
  const [px, py] = p.find(q => q[0] > 60 && q[0] < 260)
  await mouse('mouseMoved', px * 2, py * 2)
  await b.sleep(100)
  await mouse('mousePressed', px * 2, py * 2, 1); await b.sleep(60); await mouse('mouseReleased', px * 2, py * 2)
  await b.sleep(200)
  for (let i = 0; i <= 10; i++) { await mouse('mouseMoved', px * 2 + (300 - px * 2) * i / 10, py * 2 + (300 - py * 2) * i / 10); await b.sleep(20) }
  await b.sleep(300)
  await shot('b')
  console.log('hand', await b.eval('JSON.stringify(kk.game.hand && kk.game.hand.list.map(c => [c.x, c.y, c.n, c.s]))'))
  await mouse('mousePressed', 300, 300, 1); await b.sleep(60); await mouse('mouseReleased', 300, 300)
  await b.sleep(150)
  await shot('c')
  await b.sleep(1500)
  await shot('d')
  console.log('state', await b.eval('JSON.stringify(kk.game.debugState())'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
