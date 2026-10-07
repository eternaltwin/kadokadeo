// Hypercube on a touch screen: a finger is the mouse (tap a piece of the conveyor, tap the board to put it), the ⟳
// button (SPACE) turns the piece in hand, the ⇄ button held (CONTROL) while another finger taps swaps the piece with
// a form; the end button is tapped after the time out. Then the replay of that game, on a desktop browser, must give
// the same end state.
// usage: node htouch.mjs      env: PORT (DevTools, default 9935), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('hypercube', 'check', 'touch')
const URL0 = HOST + '/game.html?game=hypercube&cls=GameHypercube&seed=123&test=hc&time=900'
const PORT = +(process.env.PORT || 9935)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const tap = async (x, y, id = 1, hold = 90) => { await touch('touchStart', [P(x, y, id)]); await b.sleep(hold); await touch('touchEnd', []); await b.sleep(200) }
// the buttons (TOUCH_CONTROLS: 64 px, 10 px from the corners of the 600 x 640 canvas)
const TURN = [10 + 32, 640 - 10 - 32], SWAP = [600 - 10 - 32, 640 - 10 - 32]
const STATE = `(() => { const g = kk.game; const cubs = (l) => l.map(c => [c.x, c.y])
  return { hand: g.hand ? cubs(g.hand.list) : null, cov: JSON.parse(JSON.stringify(g.cov)), boost: g.pieceBoost, go: g.flGameOver,
    end: !!(g.butEndGame && !g.butEndGame.removed), over: !!window.__over,
    pieces: g.pieceList.map(p => ({ x: p.root._x, y: p.root._y, dx: p.dx, dy: p.dy, list: cubs(p.list) })),
    grid: g.grid.map(col => { const a = []; for (let y = 0; y < 20; y++) a.push(col[y] ? 1 : 0); return a }),
    forms: g.formList.map(f => ({ x: f.x, y: f.y, list: cubs(f.list) })) } })()`
const free = (s, x, y) => x >= 1 && x <= 18 && y >= 6 && y <= 18 && !s.grid[x][y]
const half = (l) => [Math.max(...l.map((c) => c[0])) * 0.5, Math.max(...l.map((c) => c[1])) * 0.5]
const cellPos = (l, x, y) => { const [dx, dy] = half(l); return [Math.round(2 * (x + dx + 0.3) * 15), Math.round(2 * (y + dy + 0.3) * 15)] }
async function takePiece() {
  for (let k = 0; k < 40; k++) {
    const s = await b.eval(STATE)
    const p = s.pieces.find((p) => p.x > 60 && p.x < 240)
    if (p) {
      const c = p.list[0]
      await tap(Math.round(2 * (p.x + (c[0] - p.dx) * 15 - s.boost * 2)), Math.round(2 * (p.y + (c[1] - p.dy) * 15 - 3)))
      if ((await b.eval(STATE)).hand) return true
    }
    await b.sleep(150)
  }
  return false
}
async function put(x0, y0) {
  const s = await b.eval(STATE)
  for (let x = x0; x <= 18; x++) for (let y = y0; y <= 18; y++)
    if (s.hand.every(([cx, cy]) => free(s, x + cx, y + cy))) { const [mx, my] = cellPos(s.hand, x, y); await tap(mx, my); return [x, y] }
  return null
}
const ok = (c, m) => console.log(m, c ? 'OK' : 'FAIL')
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.grid)', 60000)
  await b.sleep(1500)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  ok(await takePiece(), 'tap a piece of the conveyor: in hand')
  await b.screenshot(out + '/t_hand.png', { x: 8, y: 8, width: 600, height: 640 })
  await tap(...TURN)
  ok((await b.eval(STATE)).cov.turn === 1, 'turn button: the piece turns')
  const first = await put(3, 8)
  ok((await b.eval(STATE)).cov.put === 1, 'tap on the board: the piece is put at ' + first)
  ok(await takePiece(), 'a second piece in hand')
  // the swap: the piece over the first form (all its cells on it or free), CONTROL held by the ⇄ button
  let s = await b.eval(STATE)
  const f = s.forms[0]
  const cells = new Set(f.list.map(([cx, cy]) => (f.x + cx) * 100 + f.y + cy))
  let sw = null
  for (let x = f.x - 3; x <= f.x + 3 && !sw; x++) for (let y = f.y - 3; y <= f.y + 3 && !sw; y++) {
    const c = s.hand.map(([cx, cy]) => [x + cx, y + cy])
    if (c.some(([cx, cy]) => cells.has(cx * 100 + cy)) && c.every(([cx, cy]) => cells.has(cx * 100 + cy) || free(s, cx, cy))) sw = [x, y]
  }
  const [mx, my] = cellPos(s.hand, sw[0], sw[1])
  await touch('touchStart', [P(...SWAP, 2)]); await b.sleep(120)
  await touch('touchStart', [P(...SWAP, 2), P(mx, my, 3)]); await b.sleep(90)
  await touch('touchEnd', [P(...SWAP, 2)]); await b.sleep(120)
  await touch('touchEnd', []); await b.sleep(200)
  s = await b.eval(STATE)
  ok(s.cov.swap === 1 && !!s.hand, 'swap button held + tap: the form comes in hand (swaps ' + s.cov.swap + ')')
  await b.screenshot(out + '/t_swap.png', { x: 8, y: 8, width: 600, height: 640 })
  await put(8, 12)
  // to the end of the time, then the end button
  await b.waitFor('kk.game.flGameOver && kk.game.pieceList.length == 0 && !!kk.game.butEndGame', 180000)
  if ((await b.eval(STATE)).hand) await put(1, 6)
  await b.sleep(800)
  await b.screenshot(out + '/t_end.png', { x: 8, y: 8, width: 600, height: 640 })
  await tap(300, 80)
  await b.waitFor('!!window.__over', 30000)
  ok(true, 'end button tapped: game over')
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver.replace(/"grid":"[^"]*"/, '"grid":…'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.grid)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay (desktop)', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  await b.close()
}
