// The original in Ruffle (ref_swf.py + ruffle_site.sh): screenshots at given times and the values logged by the ref SWF
// (env LOG of ref_swf.py, collected by ruffle/ref.html in window.__log).
// usage: node rprobe.mjs <out prefix> <ms,ms,...> [swf]      env: RPORT (8797), PORT (DevTools, 9961), GPU=1
import { launch } from '../../harness/cdp.mjs'
import fs from 'fs'
const out = process.argv[2]
const times = (process.argv[3] || '500').split(',').map(Number)
const b = await launch(+(process.env.PORT || 9961))
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8797) + '/ref.html?swf=' + (process.argv[4] || 'ref.swf'))
  await b.waitFor('!!(window.__loaded || window.__err)', 60000)
  const t0 = Date.now()
  let i = 0
  for (const t of times) {
    const w = t - (Date.now() - t0)
    if (w > 0) await b.sleep(w)
    await b.screenshot(out + '_' + (i++) + '.png', { x: 8, y: 8, width: 600, height: 600 })
  }
  const log = JSON.parse(await b.eval('JSON.stringify(window.__log || [])'))
  fs.writeFileSync(out + '_log.json', JSON.stringify(log))
  console.log('frames logged', log.length)
  for (const l of log.slice(0, 40)) console.log(JSON.stringify(l))
} finally {
  await b.close()
}
