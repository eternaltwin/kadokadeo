// Razor bot + replay: plays a real game with key events (arrows, sometimes the WASD aliases): looks at the board
// (kk.game.debugBot()), rates every place of the razor around the board by the combo its slice would make (the longest
// path of the game's getPath, avoiding a colour whose 4 icons are already shown: its 5th slice ends the game), walks the
// razor there one cell at a time (a press per cell, let go once it moves), slices (up), until the game over; then plays the
// replay and compares the end state (MATCH expected).
// usage: node r3.mjs [bot seed] [replay speed]
// env: PORT (DevTools, default 9933; the replay uses PORT + 50), HPORT, EXTRA (url params, test modes), MAXT (bot
//      actions), LOG=1
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=razor&cls=GameRazor&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9933)
const MAXT = +(process.env.MAXT || 2000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'] }
const ALT = { left: [65, 'KeyA', 'a'], up: [87, 'KeyW', 'w'], right: [68, 'KeyD', 'd'] }
let b = await launch(PORT)
const send = (type, [code, c, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k || c, code: c })
const SIDE = 6, COL_MAX = 3, POOL_MAX = 4
const DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]]
const smod = (n, m) => ((n % m) + m) % m
const stats = { slices: 0, steps: 0, alias: 0, best: 0 }

// ---------------------------------------------------------------- the game's rules (Game.slip, getSliceTarget, getPath)
function slip(p, sens) {
  let di = (p.bdir + 1 - sens) % 4
  const dx = DIR[di][0], dy = DIR[di][1]
  let x = p.x + dx, y = p.y + dy, bdir = p.bdir
  if ((dx !== 0 && (x === -1 || x === SIDE)) || (dy !== 0 && (y === -1 || y === SIDE))) {
    di = smod(di - sens, 4)
    bdir = smod(bdir - sens, 4)
    x += DIR[di][0]
    y += DIR[di][1]
  }
  return { x, y, bdir }
}
const target = (p) => { const d = DIR[smod(p.bdir - 1, 4)]; return [p.x + d[0], p.y + d[1]] }
const at = (g, x, y) => (x >= 0 && x < SIDE && y >= 0 && y < SIDE ? g[x][y] : -2)
// length of the longest path of getPath (capped search)
function pathLen(g, x0, y0) {
  const col = g[x0][y0]
  let best = 0, budget = 200000
  const seen = new Set()
  const dfs = (x, y, n) => {
    if (--budget < 0) return
    if (n > best) best = n
    for (const [dx, dy] of DIR) {
      const nx = x + dx, ny = y + dy, c = at(g, nx, ny)
      if ((c === col || c === COL_MAX) && !seen.has(nx * 8 + ny)) {
        seen.add(nx * 8 + ny); dfs(nx, ny, n + 1); seen.delete(nx * 8 + ny)
      }
    }
  }
  seen.add(x0 * 8 + y0); dfs(x0, y0, 1)
  return best
}
// the 24 places of the razor, walking right from p (index = number of right presses)
function ring(p) {
  const out = [p]
  let q = p
  for (let i = 1; i < 24; i++) { q = slip(q, 1); out.push(q) }
  return out
}

// ---------------------------------------------------------------- live
const held = {}
const STATE = 'JSON.stringify(kk.game.debugBot())'
// a key held until the game reacts (the razor leaves the place / the slice starts), then let go: released before the
// move of 5 Flash frames ends, no second slip; never a tap between two steps (the game would not see it)
const press = async (name, from) => {
  const kk = rnd(5) === 0 ? ALT[name] : K[name]
  if (kk === ALT[name]) stats.alias++
  await send('keyDown', kk); held[name] = kk
  const t0 = Date.now()
  while (Date.now() - t0 < 2000) {
    await b.sleep(8)
    const n = JSON.parse(await b.eval(STATE))
    if (!n.idle || n.over || n.rx !== from.x || n.ry !== from.y) break
  }
  await send('keyUp', kk); held[name] = null
}
let data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(300)
  let plan = null
  for (; t < MAXT; t++) {
    let s
    try { s = JSON.parse(await b.eval(STATE)) } catch (e) { console.log(b.consoleLines.slice(-15).join('\n')); throw e }
    if (s.over) break
    if (!s.idle) { await b.sleep(25); continue }
    const p = { x: s.rx, y: s.ry, bdir: s.bdir }
    if (!plan) {
      // rate the places: the combo, its colour's icons (the 5th slice of a colour ends the game: last resort)
      const places = ring(p)
      const opts = []
      places.forEach((q, i) => {
        const [tx, ty] = target(q)
        const c = at(s.grid, tx, ty)
        if (c < 0) return
        const n = pathLen(s.grid, tx, ty)
        const full = c < COL_MAX && s.limits[c] >= POOL_MAX
        const steps = Math.min(i, 24 - i)
        opts.push({ i, n, c, v: (full ? -1000 : 0) + n * 10 - steps + rnd(6) })
      })
      opts.sort((a, c) => c.v - a.v)
      const o = rnd(8) === 0 ? opts[rnd(Math.min(4, opts.length))] : opts[0]
      plan = { to: places[o.i], combo: o.n, col: o.c }
      if (process.env.LOG) console.log(t, s.frame, 'at', p, 'limits', s.limits.join(','), '->', JSON.stringify(plan))
    }
    // where the place is from here (a move can overshoot when the page is slow to answer: walk back)
    const i = ring(p).findIndex((q) => q.x === plan.to.x && q.y === plan.to.y && q.bdir === plan.to.bdir)
    if (i > 0) {
      await press(i <= 12 ? 'right' : 'left', p)
      stats.steps++
      await b.sleep(30)
      continue
    }
    stats.slices++
    if (plan.combo > stats.best) stats.best = plan.combo
    await press('up', p)
    plan = null
    await b.sleep(60)
  }
  for (const k of Object.keys(held)) if (held[k]) await send('keyUp', held[k])
  await b.waitFor('!!window.__over', 600000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('razor', 'replays') + '/r3_' + (process.argv[2] || 1) + (process.env.TAG || '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
