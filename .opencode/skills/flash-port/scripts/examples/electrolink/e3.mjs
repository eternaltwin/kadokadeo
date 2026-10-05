// Electrolink: a bot plays a whole game with real mouse events (moves like a hand, hovers, presses), looking for
// the rotation that links the left and right goals, then the replay of the game is played and the end states
// (frame, score, explosions, time bonus, board) compared.
// usage: node e3.mjs <bot seed> [replay speed]     env: EXTRA (url params, e.g. '&test=el&time=30000'), PORT, HPORT,
//        SEED (game seed, debug builds play 123), SHOTS (dir: a screenshot every 25 actions)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=electrolink&cls=GameElectrolink&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9710)
const SHOTS = process.env.SHOTS
let b = await launch(PORT)
const mouse = (type, x, y, buttons = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x, y: 8 + y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1 })
const STATE = `(() => { const g = kk.game; if (!g || !g.board) return null
  return { over: !!window.__over, locked: g.isLocked(), step: g.step._hx_name,
    board: g.board.map(c => c.map(t => ({ k: t.tile, p: t.pipes.slice(), fall: t.state._hx_name }))) } })()`
// tiles reached from the left goals (or a link to the right ones) for a board of pipes
function reach(board) {
  const W = board.length, H = board[0].length, seen = new Set(), stack = []
  for (let y = 0; y < H; y++) if (board[0][y].p[2]) { seen.add(y); stack.push([0, y]) }
  let maxX = -1, linked = false
  const D = [[1, 0], [0, 1], [-1, 0], [0, -1]]
  while (stack.length) {
    const [x, y] = stack.pop()
    maxX = Math.max(maxX, x)
    if (x === W - 1 && board[x][y].p[0]) linked = true
    for (let i = 0; i < 4; i++) {
      const nx = x + D[i][0], ny = y + D[i][1]
      if (nx < 0 || ny < 0 || nx >= W || ny >= H || !board[x][y].p[i] || !board[nx][ny].p[(i + 2) % 4]) continue
      const k = nx * H + ny
      if (!seen.has(k)) { seen.add(k); stack.push([nx, ny]) }
    }
  }
  return { linked, maxX, n: seen.size }
}
const rot = (p, n) => { const o = p.slice(); for (let i = 0; i < 4; i++) o[(i + n) % 4] = p[i]; return o }
function choose(board) {
  let best = null
  for (let x = 0; x < board.length; x++) for (let y = 0; y < board[x].length; y++) {
    if (board[x][y].k === 3) continue
    for (let n = 1; n <= 3; n++) {
      const bb = board.map(c => c.map(t => ({ p: t.p })))
      bb[x][y] = { p: rot(board[x][y].p, n) }
      const r = reach(bb)
      const score = (r.linked ? 1000 : 0) - n * 3 + r.maxX * 10 + r.n + rnd(4)
      if (!best || score > best.score) best = { x, y, n, score }
    }
  }
  return best
}
// PERF=1 (with GPU=1): shaders compiled, textures uploaded and long frames during the game
const PERF_INIT = `(() => {
  const S = kk.renderer.shader, gen = S.generateShader.bind(S)
  window.__progs = 0; S.generateShader = function (sh) { __progs++; return gen(sh) }
  window.__ups = []; const gl = kk.renderer.gl
  for (const fn of ['texImage2D', 'texSubImage2D']) { const o = gl[fn].bind(gl)
    gl[fn] = function (...a) { const t = performance.now(), r = o(...a), src = a[a.length - 1]
      __ups.push([+(performance.now() - t).toFixed(2), src && src.width ? src.width + 'x' + src.height : '?']); return r } }
  window.__long = []; let last = performance.now()
  const tick = () => { const n = performance.now(); if (n - last > 25) __long.push([+(n - last).toFixed(1), kk.game && kk.game.frameCount, kk.game && kk.game.mcScoring._currentframe, kk.game && kk.game.step._hx_name]); last = n; if (!window.__over) requestAnimationFrame(tick) }
  requestAnimationFrame(tick); return true })()`
const PERF_REPORT = `JSON.stringify({ shaders: __progs, uploads: __ups.length, uploadMsMax: Math.max(0, ...__ups.map(u => u[0])), uploadMsSum: +__ups.reduce((s, u) => s + u[0], 0).toFixed(1), sizes: [...new Set(__ups.map(u => u[1]))].slice(0, 8), longFrames: __long })`
let pos = [300, 300]
async function moveTo(tx, ty) {
  const [sx, sy] = pos, n = 6 + rnd(10)
  for (let i = 1; i <= n; i++) {
    const t = i / n, e = t * t * (3 - 2 * t)
    pos = [Math.round(sx + (tx - sx) * e + rnd(3) - 1), Math.round(sy + (ty - sy) * e + rnd(3) - 1)]
    await mouse('mouseMoved', pos[0], pos[1]); await b.sleep(12)
  }
}
const stats = { clicks: 0, links: 0, random: 0 }
let data, liveOver, t = 0, lockedFor = 0
const window_crash = (c) => { if (c !== 'null') console.log('CRASH', c.slice(0, 1500)); return c !== 'null' }
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.board)', 60000)
  if (process.env.PERF) await b.eval(PERF_INIT)
  let shot = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (SHOTS && t % 25 === 0 && shot < 40) await b.screenshot(SHOTS + '/e' + String(shot++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (window_crash(await b.eval('JSON.stringify(window.__crash || null)'))) break
    if (s.locked) {
      if (++lockedFor > 1500) { console.log('STUCK', s.step); break }
      // wandering a little while the board is busy (hovers while locked: no glow)
      if (rnd(3) === 0) await moveTo(pos[0] + rnd(41) - 20, pos[1] + rnd(41) - 20)
      await b.sleep(40)
      continue
    }
    lockedFor = 0
    let c = rnd(12) === 0 ? null : choose(s.board)
    if (!c || c.score < 0) { c = { x: rnd(8), y: rnd(9), n: 1 }; stats.random++ }
    if (c.score >= 1000) stats.links++
    const cx = 2 * (60 + 25 * c.x) + rnd(31) - 15, cy = 2 * (45 + 25 * c.y) + rnd(31) - 15
    await moveTo(cx, cy)
    await b.sleep(20 + rnd(120))
    // one press per rotation, waiting for the tile to be free again
    for (let i = 0; i < c.n; i++) {
      await mouse('mousePressed', pos[0], pos[1], 1); await b.sleep(20 + rnd(60)); await mouse('mouseReleased', pos[0], pos[1])
      stats.clicks++
      await b.sleep(150 + rnd(80))
      if (await b.eval('kk.game.step._hx_name !== "Play"')) break
    }
  }
  await b.waitFor('!!window.__over', 120000)
  if (process.env.PERF) console.log('perf', await b.eval(PERF_REPORT))
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('electrolink', 'replays') + '/e_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.board)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
