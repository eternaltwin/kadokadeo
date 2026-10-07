// The same play on the original in Ruffle (ruffle/ruffle_site.sh) or on the port (harness), screenshots at the same
// moments: the board, the first fruit clicked, the mouse over the next ones (one by one), the end of the level and the
// next board. The sequence is read from the game (the original: the state ref_swf.py sends after every frame). The
// original's random cannot be seeded: the boards differ, the pictures and their timing can be compared.
// usage: node pruf.mjs ref|port <shots prefix> [levels]   env: RPORT (default 8782), HPORT, PORT (default 9972), GPU=1
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const mode = process.argv[2] || 'ref'
const pre = process.argv[3] || mode
const levels = +(process.argv[4] || 1)
const b = await launch(+(process.env.PORT || 9972))
const dir = gameDir('puzzlemanda', 'cmp')
const shot = (n) => b.screenshot(`${dir}/${pre}_${n}.png`, { x: 8, y: 8, width: 600, height: 600 })
let mx = 150, my = 150
const ev = (type, down) => b.send('Input.dispatchMouseEvent', { type, x: 8 + mx * 2, y: 8 + my * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
async function move(x, y, steps = 4) {
  const x0 = mx, y0 = my
  for (let i = 1; i <= steps; i++) { mx = x0 + (x - x0) * i / steps; my = y0 + (y - y0) * i / steps; await ev('mouseMoved', false); await b.sleep(15) }
}
async function click() { await ev('mousePressed', true); await b.sleep(60); await ev('mouseReleased', false) }
// {score, level, cTime, eaten, path: [{x, y, s}]}
async function state() {
  if (mode === 'ref') {
    const l = JSON.parse(await b.eval('JSON.stringify(window.__log[window.__log.length - 1] || null)'))
    if (!l) return null
    const [score, level, cTime, w, h, eaten] = l
    const path = []
    for (let i = 0; i < 8; i++) {
      const x = l[6 + i * 3], y = l[7 + i * 3], s = l[8 + i * 3]
      if (x == null) break
      path.push({ x: x * 30 + (300 - w * 30) / 2 + 15, y: y * 30 + 60 + (240 - h * 30) / 2 + 15, s })
    }
    return { score, level, cTime, eaten, path }
  }
  return JSON.parse(await b.eval(`(() => { const G = GamePuzzleManda; const H = G.grid.length, W = G.grid[0].length;
    return JSON.stringify({ score: kk.score.get(), level: kk.game.debugState().level, cTime: G.cTime, eaten: G.suite.tmpList.length,
      path: G.suite.list.map(c => ({ x: c.x * 30 + (300 - W * 30) / 2 + 15, y: c.y * 30 + 60 + (240 - H * 30) / 2 + 15, s: c.symbol })) }) })()`))
}
try {
  if (mode === 'ref') {
    await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8782) + '/ref.html?swf=ref.swf')
    await b.waitFor('!!(window.__loaded || window.__err) && window.__log.length > 0', 60000)
  } else {
    await b.goto(HOST + '/game.html?game=puzzlemanda&cls=GamePuzzleManda&seed=123' + (process.env.EXTRA || ''))
    await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  }
  await move(150, 280)
  await b.sleep(250)
  await shot('a0appear')
  await b.sleep(2500)
  await shot('a1board')
  for (let lv = 0; lv < levels; lv++) {
    const st = await state()
    console.log(mode, 'level', st.level, 'score', st.score, 'cTime', st.cTime, JSON.stringify(st.path))
    const p = st.path
    await move(p[0].x, p[0].y)
    await b.sleep(150)
    await shot(`l${lv}b0hover`)
    await click()
    await b.sleep(80)
    await shot(`l${lv}b1eat`)
    await b.sleep(150)
    await shot(`l${lv}b2eat`)
    for (let i = 1; i < p.length; i++) {
      await b.sleep(250)
      await move(p[i].x, p[i].y, 3)
      await b.sleep(90)
      await shot(`l${lv}c${i}a`)
      await b.sleep(120)
      await shot(`l${lv}c${i}b`)
    }
    for (const t of [200, 500, 900, 1500]) {
      await b.sleep(t - (t > 200 ? [200, 500, 900][[500, 900, 1500].indexOf(t)] : 0))
      await shot(`l${lv}d${t}`)
    }
    await b.sleep(1500)
    await shot(`l${lv}e`)
    console.log(mode, JSON.stringify(await state()))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|panic/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
