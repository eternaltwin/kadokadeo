// Digestomax bot + replay: plays a real game with key events (arrows, Space, sometimes the WASD / Enter aliases): looks
// at the grid (kk.game.debugBot()), simulates each move (walk / swallow beside, below, above, poop the stomach as a
// column) with the gravity and the groups of the game, plays the one that makes a group, else swallows fruits or poops
// them, until the game over; then plays the replay and compares the end state (MATCH expected).
// usage: node d3.mjs [bot seed] [replay speed]
// env: PORT (DevTools, default 9863; the replay uses PORT + 50), HPORT, EXTRA (url params, test modes), MAXT (bot moves),
//      LOG=1
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=digestomax&cls=GameDigestomax&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9863)
const MAXT = +(process.env.MAXT || 3000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'], space: [32, 'Space', ' '] }
const ALT = { left: [65, 'KeyA', 'a'], up: [87, 'KeyW', 'w'], right: [68, 'KeyD', 'd'], down: [83, 'KeyS', 's'], space: [13, 'Enter', 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, c, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k || c, code: c })
const XMAX = 9, YMAX = 8
const stats = { moves: 0, poop: 0, eat: 0, dig: 0, up: 0, walk: 0, wait: 0, combosPlanned: 0 }

// ---------------------------------------------------------------- simulation of a move (Game: fall, getGroups)
const copy = (g) => g.map((c) => c.slice())
function fall(g) {
  for (let x = 0; x < XMAX; x++) {
    const col = g[x].filter((v) => v !== -1)
    g[x] = Array(YMAX - col.length).fill(-1).concat(col)
  }
}
function groups(g, limit) {
  const seen = new Set(); let n = 0, size = 0
  for (let x = 0; x < XMAX; x++) for (let y = 0; y < YMAX; y++) {
    const c = g[x][y]
    if (c < 0 || c >= 20 || c === 10 || seen.has(x * 10 + y)) continue
    const st = [[x, y]]; seen.add(x * 10 + y); let k = 0
    while (st.length) {
      const [a, bb] = st.pop(); k++
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = a + dx, ny = bb + dy
        if (nx < 0 || ny < 0 || nx >= XMAX || ny >= YMAX || seen.has(nx * 10 + ny) || g[nx][ny] !== c) continue
        seen.add(nx * 10 + ny); st.push([nx, ny])
      }
    }
    if (k >= limit) { n++; size += k }
  }
  return { n, size }
}
// the grid after a move, or null when the move does nothing
function simulate(s, move) {
  const g = copy(s.grid), x = s.hx, y = s.hy
  const at = (a, c) => (a >= 0 && a < XMAX && c >= 0 && c < YMAX ? g[a][c] : -2)
  if (move === 'left' || move === 'right') {
    const d = move === 'left' ? -1 : 1, n = at(x + d, y)
    if (n === -2) return null
    g[x][y] = -1; g[x + d][y] = 20
  } else if (move === 'down') {
    if (at(x, y + 1) < 0) return null
    g[x][y] = -1; g[x][y + 1] = 20
  } else if (move === 'up') {
    if (y === 0) return null
    if (at(x, y - 1) >= 0) { g[x][y - 1] = -1 }
    else {
      // poop: the stomach as a column under the hero (the last fruit first), the hero on top
      if (!s.stomach.length) return null
      const st = s.stomach.slice(); let py = y
      while (true) {
        if (at(x, py - 1) !== -1) return null
        g[x][py] = st.pop(); py--; g[x][py] = 20
        if (!st.length || py <= 0) break
      }
    }
  }
  fall(g)
  return g
}

// ---------------------------------------------------------------- live
const held = {}
const press = async (name, ms) => {
  const kk = rnd(6) === 0 ? ALT[name] : K[name]
  await send('keyDown', kk); held[name] = kk
  await b.sleep(ms)
  await send('keyUp', kk); held[name] = null
}
const STATE = 'JSON.stringify(kk.game.debugBot())'
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  for (; t < MAXT; t++) {
    let s
    try { s = JSON.parse(await b.eval(STATE)) } catch (e) { console.log(b.consoleLines.slice(-15).join("\n")); throw e }
    if (s.over) break
    if (!s.idle) { stats.wait++; await b.sleep(30); continue }
    stats.moves++
    // the moves that make a group (the most fruits), else a useful one
    const cand = []
    for (const m of ['left', 'right', 'down', 'up']) {
      const g = simulate(s, m)
      if (!g) continue
      const gr = groups(g, s.limit)
      const x = s.hx, y = s.hy
      const eats = m === 'left' ? s.grid[x - 1]?.[y] >= 0 : m === 'right' ? s.grid[x + 1]?.[y] >= 0 : m === 'down' ? s.grid[x][y + 1] >= 0 : y > 0 && s.grid[x][y - 1] >= 0
      const poop = m === 'up' && !eats
      let v = gr.size * 10 + rnd(5)
      if (eats && s.stomach.length < s.size - 1) v += 4
      if (eats && s.stomach.length >= s.size) v -= 6
      if (poop) v += s.stomach.length >= s.size - 1 ? 8 : 1
      cand.push({ m, v, gr, eats, poop })
    }
    cand.sort((a, c) => c.v - a.v)
    let pick = cand.length ? cand[0] : null
    if (pick && pick.gr.n) stats.combosPlanned++
    // few fruits left (the level ends when the hero has swallowed the last one): go and swallow them
    let left = 0, near = null
    for (let x = 0; x < XMAX; x++) for (let y = 0; y < YMAX; y++) if (s.grid[x][y] >= 0 && s.grid[x][y] < 20) {
      left++
      if (!near || Math.abs(x - s.hx) < Math.abs(near - s.hx)) near = x
    }
    if (left && left <= 6 && !(pick && (pick.gr.n || pick.eats))) {
      const e = cand.find((c) => c.eats)
      pick = e || { m: near < s.hx ? 'left' : near > s.hx ? 'right' : rnd(2) ? 'left' : 'right', gr: { n: 0 } }
    } else if (!pick || rnd(12) === 0) pick = cand.length ? cand[rnd(cand.length)] : { m: rnd(2) ? 'left' : 'right' }
    if (process.env.LOG) console.log(t, s.frame, 'hero', s.hx, s.hy, 'st', s.stomach.join(''), '->', pick.m, JSON.stringify(pick.gr || {}))
    const m = pick.m
    if (m === 'left' || m === 'right') {
      // walk until the hero changes cell (or swallows), then let go
      stats[pick.eats ? 'eat' : 'walk']++
      const kk = rnd(6) === 0 ? ALT[m] : K[m]
      await send('keyDown', kk)
      const t0 = Date.now()
      while (Date.now() - t0 < 1500) {
        await b.sleep(25)
        const n = JSON.parse(await b.eval(STATE))
        if (n.hx !== s.hx || n.hy !== s.hy || !n.idle || n.over) break
      }
      await send('keyUp', kk)
    } else if (m === 'down') {
      stats.dig++
      await press('down', 60)
    } else if (pick.eats) {
      // swallow upwards: up held a little while (the next fruit above too, sometimes)
      stats.up++
      await press('up', 60 + rnd(3) * 120)
    } else {
      stats.poop++
      await press(rnd(3) === 0 ? 'space' : 'up', 60)
    }
    await b.sleep(20 + rnd(40))
  }
  for (const k of Object.keys(held)) if (held[k]) await send('keyUp', held[k])
  await b.waitFor('!!window.__over', 600000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'moves', t, 'replay chars', data.length)
  writeFileSync(gameDir('digestomax', 'replays') + '/d3_' + (process.argv[2] || 1) + '.txt', data + '\n' + liveOver)
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
