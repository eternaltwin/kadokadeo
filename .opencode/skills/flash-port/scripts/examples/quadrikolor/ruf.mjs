// The original in Ruffle (ruffle/ruffle_site.sh): aims with the mouse at a point, clicks (direction), clicks again
// after `wait` ms (power), screenshots during the shot. Positions in game pixels (300 x 300).
// usage: node ruf.mjs <aim x> <aim y> [power wait ms] [shots prefix]     env: PORT (default 9967), RPORT (8799), GPU=1
import { launch } from '../../harness/cdp.mjs'
import { gameDir } from '../../harness/paths.mjs'
const [ax, ay] = [+(process.argv[2] || 150), +(process.argv[3] || 150)]
const wait = +(process.argv[4] || 500)
const pre = process.argv[5] || 'r'
const b = await launch(+(process.env.PORT || 9967))
const P = (v) => 8 + v * 2
const shot = (n) => b.screenshot(gameDir('quadrikolor', 'ruffle') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 600 })
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8799) + '/ref.html?swf=ref.swf')
  await b.waitFor('!!window.__loaded || !!window.__err', 60000)
  await b.sleep(2500)
  await shot('00start')
  for (let i = 1; i <= 10; i++) { await b.move(P(150 + (ax - 150) * i / 10), P(150 + (ay - 150) * i / 10)); await b.sleep(30) }
  await b.sleep(1500)
  await shot('01aim')
  await b.click(P(ax), P(ay))
  await b.sleep(wait)
  await shot('02power')
  await b.click(P(ax), P(ay))
  for (let i = 0; i < 12; i++) { await b.sleep(300); await shot(String(10 + i)) }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
