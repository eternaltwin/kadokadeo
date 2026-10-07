// Memopsy on a touch screen: a finger is the mouse (a tap presses the card under it). Taps match the pairs of the
// first level and miss once (a life lost), then drain the lives on known mismatches until the game over; the replay
// of that game, on a desktop browser, must give the same end state.
// usage: node mtouch.mjs      env: PORT (DevTools, default 10575), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const URL0 = HOST + '/game.html?game=memopsy&cls=GameMemopsy&seed=123'
const PORT = +(process.env.PORT || 10575)
const SIZES = [[4, 2], [4, 3], [4, 4], [5, 4], [5, 4], [5, 4], [6, 4]]
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
// (Flash pixels -> page pixels: the canvas at (8, 8), x2)
const P = (x, y) => ({ x: 8 + 2 * x, y: 8 + 2 * y, id: 1, radiusX: 4, radiusY: 4, force: 1 })
const tap = async (x, y, hold = 90) => { await touch('touchStart', [P(x, y)]); await b.sleep(hold); await touch('touchEnd', []); await b.sleep(150) }
const STATE = '(() => { const g = kk.game; if (!g) return null; const s = g.debugState(); s.over = !!window.__over; return s })()'
const ok = (c, m) => console.log(m, c ? 'OK' : 'FAIL')

function cells(s) {
  const [w, h] = SIZES[Math.min(s.nlevel, SIZES.length - 1)]
  const px = (300 - w * 50 + 8) / 2, py = (290 - h * 70 + 6) / 2 + 10
  const g = s.grid.split(',')
  const out = []
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++)
      out.push({ id: parseInt(g[y * w + x]), st: g[y * w + x].slice(-1), cx: px + x * 50 + 21, cy: py + y * 70 + 32 })
  return out
}
async function settle() {
  for (let i = 0; i < 100; i++) {
    const s = await b.eval(STATE)
    if (s.over || (s.anims === 0 && (s.lock === 0 || s.lock > 90))) return s
    await b.sleep(80)
  }
  return await b.eval(STATE)
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.sleep(800)
  // a matching pair by two taps
  let s = await b.eval(STATE)
  const down = cells(s).filter((c) => c.st === '-')
  const byId = {}
  for (const c of down) (byId[c.id] = byId[c.id] || []).push(c)
  const pair = Object.values(byId).find((l) => l.length >= 2)
  await tap(pair[0].cx, pair[0].cy)
  s = await b.eval(STATE)
  ok(s.anims >= 1 || s.lock >= 1, 'tap a card: it flips')
  await tap(pair[1].cx, pair[1].cy)
  s = await settle()
  ok(s.score > 0 && s.npairs === s.maxpairs - 1, 'tap its pair: matched, scored (' + s.score + ')')
  await b.screenshot(gameDir('memopsy', 'check', 'touch') + '/t_pair.png', { x: 8, y: 8, width: 600, height: 640 })
  // a mismatch: a life lost
  const lives0 = s.lives
  for (let i = 0; i < 200; i++) {
    s = await settle()
    if (s.over) break
    const d = cells(s).filter((c) => c.st === '-')
    const ids = {}
    for (const c of d) (ids[c.id] = ids[c.id] || []).push(c)
    const ks = Object.keys(ids)
    if (ks.length < 2) { // only one id left face down: match it (a new level comes)
      await tap(ids[ks[0]][0].cx, ids[ks[0]][0].cy); await tap(ids[ks[0]][1].cx, ids[ks[0]][1].cy)
      continue
    }
    await tap(ids[ks[0]][0].cx, ids[ks[0]][0].cy)
    await tap(ids[ks[1]][0].cx, ids[ks[1]][0].cy)
    if (i === 0) { s = await settle(); ok(s.lives === lives0 - 1, 'tap two different cards: a life lost (' + s.lives + ')') }
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval('window.__logs.find(l => l.includes("Replay data:"))')).split('Replay data: ')[1].trim()
  console.log('live', liveOver)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
// the replay on a desktop browser (no touch emulation)
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 600000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  await b.close()
}
