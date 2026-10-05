// Electrolink on a touch screen: a tap on a tile rotates it (the finger is the mouse: onPress), taps chosen like the
// bot of e3.mjs make links and explosions; then the replay of that game on a desktop browser must give the same end
// state.   env: PORT, HPORT, EXTRA (default '&test=el&time=25000')
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('electrolink', 'check', 'touch')
const URL0 = HOST + '/game.html?game=electrolink&cls=GameElectrolink&seed=123' + (process.env.EXTRA || '&test=el&time=25000')
const PORT = +(process.env.PORT || 9545)
let rs = 3
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const tap = async (x, y) => { await touch('touchStart', [P(x, y, 1)]); await b.sleep(40 + rnd(60)); await touch('touchEnd', []) }
const rot = (p, n) => { const o = p.slice(); for (let i = 0; i < 4; i++) o[(i + n) % 4] = p[i]; return o }
function reach(board) {
  const W = board.length, H = board[0].length, seen = new Set(), stack = []
  for (let y = 0; y < H; y++) if (board[0][y][2]) { seen.add(y); stack.push([0, y]) }
  let maxX = -1, linked = false
  const D = [[1, 0], [0, 1], [-1, 0], [0, -1]]
  while (stack.length) {
    const [x, y] = stack.pop(); maxX = Math.max(maxX, x)
    if (x === W - 1 && board[x][y][0]) linked = true
    for (let i = 0; i < 4; i++) {
      const nx = x + D[i][0], ny = y + D[i][1]
      if (nx < 0 || ny < 0 || nx >= W || ny >= H || !board[x][y][i] || !board[nx][ny][(i + 2) % 4]) continue
      if (!seen.has(nx * H + ny)) { seen.add(nx * H + ny); stack.push([nx, ny]) }
    }
  }
  return (linked ? 1000 : 0) + maxX * 10 + seen.size
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.board)', 60000)
  // one tap: the tile under the finger turns by a quarter
  const D = 'JSON.stringify([kk.game.board[2][3].d, kk.game.board[2][3].mc._rotation])'
  const before = await b.eval(D)
  await tap(2 * (60 + 25 * 2), 2 * (45 + 25 * 3))
  await b.sleep(400)
  const after = await b.eval(D)
  console.log('tap on (2, 3): d / rotation', before, '->', after, JSON.parse(after)[0] === (JSON.parse(before)[0] + 1) % 4 ? 'OK' : 'FAIL')
  let taps = 0, n = 0
  while (!(await b.eval('!!window.__over'))) {
    if (await b.eval('kk.game.isLocked()')) { await b.sleep(50); continue }
    const board = JSON.parse(await b.eval('JSON.stringify(kk.game.board.map(c => c.map(t => [t.tile, t.pipes])))'))
    let best = null
    for (let x = 0; x < 8; x++) for (let y = 0; y < 9; y++) {
      if (board[x][y][0] === 3) continue
      const p = board.map(c => c.map(t => t[1]))
      p[x][y] = rot(board[x][y][1], 1)
      const s = reach(p) + rnd(5)
      if (!best || s > best.s) best = { x, y, s }
    }
    await tap(2 * (60 + 25 * best.x) + rnd(21) - 10, 2 * (45 + 25 * best.y) + rnd(21) - 10)
    taps++
    if (taps === 30) await b.screenshot(out + '/touch.png', { x: 8, y: 8, width: 600, height: 640 })
    await b.sleep(200 + rnd(100))
  }
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, 'taps', taps, 'replay chars', data.length)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
// replay on a desktop browser (no touch)
b = await launch(PORT)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.board)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
