// Puzzle-Manda bot: plays a real game with the mouse (real events: the Flash buttons of the port see them like a
// player's), then its replay must give the same end state (MATCH).
// The bot finds a path of the sequence in the grid (the generated one or another one), starts it with a click on its
// first fruit, then goes on with the ways the original offers: the mouse over the next fruit (onRollOver), the mouse
// already there while the snake moves (Cell.tryNeighbour once the animation ends), a drag with the button held (no
// rollOver: tryNeighbour only), sometimes a wrong start or a click that cancels the snake (reinit). After <levels>
// levels it stops playing and waits for the end of the time.
// usage: node p3.mjs <bot seed> [levels] [speed]   env: PORT (default 9973), HPORT, EXTRA (url params, e.g.
//        '&test=pm&time=400&lv=8&bonus=2')
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
const seed = +(process.argv[2] || 1)
const levels = +(process.argv[3] || 3)
const speed = +(process.argv[4] || 8)
const PORT = +(process.env.PORT || 9973)
const URL0 = HOST + '/game.html?game=puzzlemanda&cls=GamePuzzleManda&seed=123' + (process.env.EXTRA || '')
let s = seed * 2654435761 >>> 0
const rnd = () => { s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s / 4294967296 }
const STATE = `(() => { const G = window.GamePuzzleManda; if (!G || !G.suite || !G.grid) return 'null'; const H = G.grid.length, W = G.grid[0].length;
  const pos = c => ({ x: c.x * 30 + (300 - W * 30) / 2 + 15, y: c.y * 30 + 60 + (240 - H * 30) / 2 + 15 });
  return JSON.stringify({ locked: G.locked(), over: !!window.__over, W, H, level: kk.game.debugState().level,
    eaten: G.suite.tmpList.length, seq: G.suite.list.map(c => c.symbol), gen: G.suite.list.map(c => [c.x, c.y]),
    grid: G.grid.map(r => r.map(c => c.chained ? -1 : c.symbol)), last: G.suite.tmpList.length ? [G.suite.last().x, G.suite.last().y] : null,
    tmp: G.suite.tmpList.map(c => [c.x, c.y]) }) })()`
const b = await launch(PORT)
let liveOver, data
let mx = 150, my = 290, down = false
const stats = { clicks: 0, hovers: 0, early: 0, drags: 0, cancels: 0, wrong: 0, levels: 0 }
const ev = (type) => b.send('Input.dispatchMouseEvent', { type, x: 8 + mx * 2, y: 8 + my * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
async function move(x, y, steps = 3 + Math.floor(rnd() * 4)) {
  const x0 = mx, y0 = my
  for (let i = 1; i <= steps; i++) { mx = x0 + (x - x0) * i / steps; my = y0 + (y - y0) * i / steps; await ev('mouseMoved'); await b.sleep(10 + rnd() * 25) }
}
async function press() { down = true; await ev('mousePressed') }
async function release() { down = false; await ev('mouseReleased') }
async function click() { await press(); await b.sleep(40 + rnd() * 80); await release(); stats.clicks++ }
const at = (st, c) => ({ x: c[0] * 30 + (300 - st.W * 30) / 2 + 15, y: c[1] * 30 + 60 + (240 - st.H * 30) / 2 + 15 })
const jit = (p, r) => ({ x: p.x + (rnd() * 2 - 1) * r, y: p.y + (rnd() * 2 - 1) * r })
// a path of the sequence from index k on, after `from` (null: any start), on the free cells: randomized DFS
function findPath(st, k, from, used) {
  const out = []
  const free = (x, y) => y >= 0 && y < st.H && x >= 0 && x < st.W && st.grid[y][x] >= 0 && !used.has(x + ',' + y)
  function dfs(i, c) {
    if (i == st.seq.length) return true
    let cand = []
    if (c == null) { for (let y = 0; y < st.H; y++) for (let x = 0; x < st.W; x++) cand.push([x, y]) } else cand = [[c[0] + 1, c[1]], [c[0] - 1, c[1]], [c[0], c[1] + 1], [c[0], c[1] - 1]]
    cand = cand.filter(([x, y]) => free(x, y) && st.grid[y][x] == st.seq[i]).sort(() => rnd() - 0.5)
    for (const n of cand) {
      used.add(n[0] + ',' + n[1]); out.push(n)
      if (dfs(i + 1, n)) return true
      out.pop(); used.delete(n[0] + ',' + n[1])
    }
    return false
  }
  return dfs(k, from) ? out : null
}
async function waitUnlocked(ms = 15000) {
  const t0 = Date.now()
  for (; ;) {
    const st = JSON.parse(await b.eval(STATE))
    if (st && (st.over || !st.locked)) return st
    if (Date.now() - t0 > ms) return st
    await b.sleep(30)
  }
}
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  await move(mx, my, 1)
  let lastLevel = 0, t = 0
  for (; t < 4000; t++) {
    const st = await waitUnlocked()
    if (!st || st.over) break
    if (st.level != lastLevel) { lastLevel = st.level; stats.levels = st.level }
    if (st.level > levels) {
      // idle until the end of the time: the mouse wanders under the grid
      await move(20 + rnd() * 260, 270 + rnd() * 25)
      await b.sleep(400)
      continue
    }
    if (st.eaten == 0) {
      // a start: the generated path, another one, or (sometimes) a fruit of the right symbol that leads nowhere
      let path = rnd() < 0.5 ? st.gen : findPath(st, 0, null, new Set())
      if (!path) path = st.gen
      if (rnd() < 0.08) {
        const wrong = []
        for (let y = 0; y < st.H; y++) for (let x = 0; x < st.W; x++) if (st.grid[y][x] == st.seq[0] && !(x == st.gen[0][0] && y == st.gen[0][1])) wrong.push([x, y])
        if (wrong.length) { path = [wrong[Math.floor(rnd() * wrong.length)]]; stats.wrong++ }
      }
      const p = jit(at(st, path[0]), 6)
      await move(p.x, p.y)
      await b.sleep(30 + rnd() * 60)
      await click()
      // (the game takes the click at its next step: not twice)
      await b.sleep(150)
      continue
    }
    // going on: the rest of a path from the head
    const used = new Set(st.tmp.map(c => c[0] + ',' + c[1]))
    const rest = findPath(st, st.eaten, st.last, used)
    if (!rest || rnd() < 0.03) {
      // a dead end (or a whim): a click cancels the snake
      const p = rnd() < 0.5 ? { x: 20 + rnd() * 40, y: 120 + rnd() * 100 } : jit(at(st, st.last), 4)
      await move(p.x, p.y)
      await click()
      await b.sleep(150)
      stats.cancels++
      continue
    }
    const r = rnd()
    if (r < 0.15 && rest.length >= 2) {
      // a drag with the button held through the next fruits (tryNeighbour: 20 px from the head), released on the last
      await press()
      for (const c of rest.slice(0, 1 + Math.floor(rnd() * Math.min(3, rest.length)))) {
        const p = jit(at(st, c), 3)
        await move(p.x, p.y)
        await waitUnlocked()
        await b.sleep(60)
      }
      await b.sleep(80)
      await release()
      stats.drags++
    } else if (r < 0.45) {
      // early: the mouse goes to the next fruits while the snake moves (rollOvers while locked do nothing)
      const n = Math.min(rest.length, 1 + Math.floor(rnd() * 3))
      for (const c of rest.slice(0, n)) {
        const p = jit(at(st, c), 5)
        await move(p.x, p.y, 2)
        await b.sleep(40 + rnd() * 80)
      }
      stats.early++
    } else {
      // the mouse over the next fruit
      const p = jit(at(st, rest[0]), 7)
      await move(p.x, p.y)
      await b.sleep(30 + rnd() * 40)
      stats.hovers++
    }
  }
  await b.waitFor('!!window.__over', 600000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'replay chars', data.length)
  if (process.env.EVENTS) console.log(await b.eval('JSON.stringify(window.__events)'))
  writeFileSync(gameDir('puzzlemanda', 'replays') + '/p_replay_' + seed + '.txt', data + '\n' + liveOver + '\n' + URL0)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
const r = await launch(PORT + 50)
try {
  await r.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await r.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  await r.eval(`kk.setReplaySpeed(${speed})`)
  await r.waitFor('!!window.__over', 600000)
  const rep = await r.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = r.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await r.close()
}
