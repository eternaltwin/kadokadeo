// The original in Ruffle played by a bot, for screenshots of whole games (score sheets, holes, ends): the ship and
// the balls are found on a screenshot (ruf_detect.py), the ship is aimed at the ghost ball of a ball for a hole (like
// q3.mjs), the power is clicked at once (the gauge starts at its maximum); screenshots every 0.4 s after the shot.
// usage: node ruf3.mjs [shots] [prefix]      env: PORT (default 9968), RPORT (8799), GPU=1
import { launch } from '../../harness/cdp.mjs'
import { gameDir } from '../../harness/paths.mjs'
import { execFileSync } from 'node:child_process'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'
const HERE = dirname(fileURLToPath(import.meta.url))
const PY = process.env.PY || join(homedir(), 'kadokadeo-port/venv/bin/python3')
const N = +(process.argv[2] || 7)
const pre = process.argv[3] || 'g'
const dir = gameDir('quadrikolor', 'ruffle3')
const b = await launch(+(process.env.PORT || 9968))
const P = (v) => 8 + v * 2
const HOLES = [[0, 14], [300, 14], [0, 300], [300, 300]]
let k = 0
const shot = async () => { const f = `${dir}/${pre}${String(k++).padStart(3, '0')}.png`; await b.screenshot(f, { x: 8, y: 8, width: 600, height: 600 }); return f }
try {
  await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8799) + '/ref.html?swf=ref.swf')
  await b.waitFor('!!window.__loaded || !!window.__err', 60000)
  await b.sleep(2500)
  for (let n = 0; n < N; n++) {
    const s = JSON.parse(execFileSync(PY, [join(HERE, 'ruf_detect.py'), await shot()]).toString())
    if (!s.ship || !s.balls.length) { console.log('no ship / balls', JSON.stringify(s)); break }
    let best = null
    for (const o of s.balls) for (const h of HOLES) {
      const bx = h[0] - o[1], by = h[1] - o[2], bd = Math.hypot(bx, by)
      const cx = o[1] - bx / bd * 26, cy = o[2] - by / bd * 26
      const ax = cx - s.ship[0], ay = cy - s.ship[1], ad = Math.hypot(ax, ay)
      const cos = (ax * bx + ay * by) / (ad * bd)
      const v = cos * 2 - (ad + bd) / 300
      if (!best || v > best.v) best = { v, x: cx, y: cy }
    }
    const x = Math.max(1, Math.min(299, best.x)), y = Math.max(15, Math.min(299, best.y))
    for (let i = 1; i <= 8; i++) { await b.move(P(150 + (x - 150) * i / 8), P(150 + (y - 150) * i / 8)); await b.sleep(25) }
    await b.sleep(1500)
    await shot()
    await b.click(P(x), P(y))
    await b.sleep(60)
    await b.click(P(x), P(y))
    console.log('shot', n, JSON.stringify(s), '->', x.toFixed(1), y.toFixed(1))
    for (let i = 0; i < 22; i++) { await b.sleep(250); await shot() }
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
