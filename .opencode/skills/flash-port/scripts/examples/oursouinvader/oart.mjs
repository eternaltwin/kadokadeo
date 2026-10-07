// Start screen candidates (public/assets/img/gfx/artwork/oursouinvader.jpg): the port's own pictures (SWF renders
// played by its runtime) at a moment of a game chosen by a test mode, 600 x 600 without the bar of KadoKadeo.
// usage: node oart.mjs <out png> <url params (test mode)> <Flash frame> [keys js run each step]
// the committed one (the layout of the old thumbnail artwork/old/oursouinvader.gif: octopuses on the sides, crabs):
//   node oart.mjs a.png "&test=oi&wave=2&dif=45&inv=1" 170, then saved as a 600 x 600 JPEG (quality 90)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const [out, extra, frame, keys] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9967))
try {
  await b.goto(HOST + '/game.html?game=oursouinvader&cls=GameOursouinvader&seed=123' + extra)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.ff.onTick = () => {}')
  await b.eval(`(() => { while (window.__state.frame < ${frame}) { ${keys || ''}; kk.updatePhysics(1000 / 32) } })()`)
  await b.sleep(500)
  await b.screenshot(out, { x: 8, y: 8, width: 600, height: 600 })
} finally { await b.close() }
