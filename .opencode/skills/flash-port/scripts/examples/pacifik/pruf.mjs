// The original in Ruffle (ruffle/ruffle_site.sh), played like p0.mjs: the mouse sweeps the stage, a click now and then,
// screenshots every `every` ms into $KKP_WORK/pacifik/shots/ruf_<n>.png. The original's random cannot be seeded.
// usage: GPU=1 RPORT=8812 PORT=9936 node pruf.mjs [shots] [every ms] [first shot ms] [swf]
import { launch } from '../../harness/cdp.mjs'
import { gameDir } from '../../harness/paths.mjs'
const N = +(process.argv[2] || 8), EVERY = +(process.argv[3] || 1500), FIRST = +(process.argv[4] || 0)
const swf = process.argv[5] || 'ref.swf'
const b = await launch(+(process.env.PORT || 9936))
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8812) + '/ref.html?swf=' + swf)
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  console.log('ready', await b.eval('window.__err || "ok"'))
  const dir = gameDir('pacifik', 'shots')
  const t0 = Date.now()
  let shot = 0, nextShot = FIRST, nextClick = 700
  while (shot < N) {
    const t = Date.now() - t0
    if (t >= nextShot) {
      await b.screenshot(dir + '/ruf_' + shot + '.png', { x: 8, y: 8, width: 600, height: 600 })
      shot++
      nextShot += EVERY
    }
    const x = 300 + 220 * Math.sin(t / 900)
    await b.move(8 + x, 8 + 300)
    if (t >= nextClick) { await b.click(8 + x, 8 + 300); nextClick += 1100 }
    await new Promise(r => setTimeout(r, 25))
  }
} finally {
  await b.close()
}
