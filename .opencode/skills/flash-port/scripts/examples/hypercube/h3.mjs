// Hypercube: a bot plays a whole game with real mouse and key events, then the replay of the game is played and the
// end states compared (frame, score, time, pieces, combos, coverage counters, grid).
// The bot builds squares: it picks a free target square (3 x 3 or 4 x 4), takes the conveyor pieces that fit in what
// is left of it (turned with SPACE), puts the others aside; now and then it misses on purpose (shake, a neighbour
// square, 5 misses burst the piece), takes a placed form back, or swaps the piece in hand with a form (CONTROL +
// click). After the time is out it keeps rearranging for a while, then presses the end button.
// usage: node h3.mjs <bot seed> [replay speed]     env: EXTRA (url params, default '&test=hc&time=1500'), PORT, HPORT,
//        SEED (game seed, debug builds play 123), SHOTS (dir: a screenshot every 20 actions),
//        BURST=1 (the first piece in hand dropped 5 times on the conveyor: it bursts), MONO=1 (only pieces of one colour
//        in a target square: MONOCOLOR)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const EXTRA = process.env.EXTRA !== undefined ? process.env.EXTRA : '&test=hc&time=1500'
const URL0 = HOST + '/game.html?game=hypercube&cls=GameHypercube&seed=' + (process.env.SEED || '123') + EXTRA
const PORT = +(process.env.PORT || 9933)
const SHOTS = process.env.SHOTS
let b = await launch(PORT)
const mouse = (type, x, y, buttons = 0, modifiers = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x, y: 8 + y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1, modifiers })
const KEYS = { space: [32, ' ', 'Space'], ctrl: [17, 'Control', 'ControlLeft'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][2], modifiers: k === 'ctrl' && type === 'keyDown' ? 2 : 0 })
const STATE = `(() => { const g = kk.game; if (!g || !g.grid) return null
  const cubs = (l) => l.map(c => [c.x, c.y, c.n])
  return { over: !!window.__over, go: g.flGameOver, end: !!(g.butEndGame && !g.butEndGame.removed), shake: g.shake,
    boost: g.pieceBoost, frame: g.frameCount, timer: g.mainTimer,
    hand: g.hand ? cubs(g.hand.list) : null,
    pieces: g.pieceList.map(p => ({ x: p.root._x, y: p.root._y, dx: p.dx, dy: p.dy, list: cubs(p.list) })),
    grid: g.grid.map(col => { const a = []; for (let y = 0; y < 20; y++) a.push(col[y] ? 1 : 0); return a }),
    forms: g.formList.map(f => ({ x: f.x, y: f.y, list: cubs(f.list) })) } })()`

// ---------------------------------------------------------------- the game's rules, on the state
const free = (s, x, y) => x >= 1 && x <= 18 && y >= 6 && y <= 18 && !s.grid[x][y]
const fits = (s, l, x, y) => l.every(([cx, cy]) => free(s, x + cx, y + cy))
// Game.turnHand
function turn(l) {
  const r = l.map(([x, y, n]) => [-y, x, n])
  const mx = Math.min(...r.map((c) => c[0])), my = Math.min(...r.map((c) => c[1]))
  return r.map(([x, y, n]) => [x - mx, y - my, n])
}
const half = (l) => [Math.max(...l.map((c) => c[0])) * 0.5, Math.max(...l.map((c) => c[1])) * 0.5]
const rotations = (l) => { const o = [l]; for (let i = 1; i < 4; i++) o.push(turn(o[i - 1])); return o }

const MONO = !!process.env.MONO
let target = null, targetTries = 0, targetCol = null, burstDone = !process.env.BURST
function newTarget(s) {
  const n = rnd(4) === 0 && !MONO ? 4 : 3
  for (let k = 0; k < 200; k++) {
    const x = 1 + rnd(19 - n), y = 6 + rnd(14 - n)
    let ok = true
    for (let i = 0; i < n && ok; i++) for (let j = 0; j < n && ok; j++) if (s.grid[x + i][y + j]) ok = false
    if (ok) { target = { x, y, n }; targetTries = 0; targetCol = null; return }
  }
  target = null
}
const inTarget = (x, y) => target && x >= target.x && x < target.x + target.n && y >= target.y && y < target.y + target.n
// a placement of the piece in the target: [rotation, x, y] (fewest turns first)
function placeInTarget(s, l) {
  if (!target) return null
  const rots = rotations(l)
  for (let r = 0; r < 4; r++)
    for (let x = target.x - 3; x < target.x + target.n; x++)
      for (let y = target.y - 3; y < target.y + target.n; y++)
        if (rots[r].every(([cx, cy]) => inTarget(x + cx, y + cy)) && fits(s, rots[r], x, y)) return [r, x, y]
  return null
}
// out of the target, as far from it as possible (the board fills from the bottom left)
function placeAside(s, l) {
  const rots = rotations(l)
  const r = rnd(4)
  const cand = []
  for (let x = 1; x <= 18; x++) for (let y = 6; y <= 18; y++)
    if (fits(s, rots[r], x, y) && !rots[r].some(([cx, cy]) => inTarget(x + cx, y + cy))) cand.push([r, x, y])
  if (!cand.length) return null
  cand.sort((a, b) => (a[1] - a[2]) - (b[1] - b[2]))
  return cand[rnd(Math.min(4, cand.length))]
}

// ---------------------------------------------------------------- hand-like mouse
let pos = [300, 450]
async function moveTo(tx, ty, steps) {
  const [sx, sy] = pos, n = steps || 5 + rnd(8)
  for (let i = 1; i <= n; i++) {
    const t = i / n, e = t * t * (3 - 2 * t)
    pos = [Math.round(sx + (tx - sx) * e + rnd(3) - 1), Math.round(sy + (ty - sy) * e + rnd(3) - 1)]
    await mouse('mouseMoved', pos[0], pos[1]); await b.sleep(12)
  }
  pos = [Math.round(tx), Math.round(ty)]
  await mouse('mouseMoved', pos[0], pos[1])
}
async function click(mod = 0) {
  await mouse('mousePressed', pos[0], pos[1], 1, mod); await b.sleep(50 + rnd(60)); await mouse('mouseReleased', pos[0], pos[1], 0, mod)
  await b.sleep(80 + rnd(60))
}
async function press(k) { await key('keyDown', k); await b.sleep(60 + rnd(40)); await key('keyUp', k); await b.sleep(70 + rnd(40)) }
// mouse position (canvas px) putting the piece l of the hand at cell (x, y): floor(hx / 15 - dx) = x
const cellPos = (l, x, y) => { const [dx, dy] = half(l); return [2 * (x + dx + 0.3) * 15, 2 * (y + dy + 0.3) * 15] }

const stats = { actions: 0, targets: 0, aside: 0, missed: 0, swaps: 0, backs: 0, waits: 0 }
let data, liveOver, t = 0, endAfter = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.grid)', 60000)
  await moveTo(300, 450)
  let shot = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (SHOTS && t % 20 === 0 && shot < 60) await b.screenshot(SHOTS + '/h' + String(shot++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (t > 4000) { console.log('STUCK'); break }
    stats.actions++
    if (!target || !inTargetFree(s)) newTarget(s)
    if (s.hand) {
      if (!burstDone) {
        // 5 drops where it cannot go (the conveyor): life 0, the piece bursts
        burstDone = true
        for (let i = 0; i < 5; i++) { await moveTo(150 + 60 * i, 60); await b.sleep(60); await click(); await b.sleep(100) }
        continue
      }
      if (s.shake != null) { await b.sleep(60); continue }
      let p = rnd(14) === 0 && !MONO ? null : placeInTarget(s, s.hand)
      if (p && MONO && targetCol != null && s.hand[0][2] % 3 !== targetCol) p = null
      if (p) { stats.targets++; if (targetCol == null) targetCol = s.hand[0][2] % 3 }
      // a swap: CONTROL + click with the piece over a form (and empty cells): the form comes in hand
      if (!p && s.forms.length && rnd(4) === 0 && !MONO) {
        const f = s.forms[rnd(s.forms.length)]
        const cells = new Set(f.list.map(([cx, cy]) => (f.x + cx) * 100 + f.y + cy))
        const rots = rotations(s.hand)
        let sw = null
        for (let r = 0; r < 4 && !sw; r++)
          for (let x = f.x - 3; x <= f.x + 3 && !sw; x++)
            for (let y = f.y - 3; y <= f.y + 3 && !sw; y++) {
              const c = rots[r].map(([cx, cy]) => [x + cx, y + cy])
              if (c.some(([cx, cy]) => cells.has(cx * 100 + cy)) && c.every(([cx, cy]) => cells.has(cx * 100 + cy) || free(s, cx, cy))) sw = [r, x, y]
            }
        if (sw) {
          for (let i = 0; i < sw[0]; i++) await press('space')
          const l = rots[sw[0]]
          const [mx, my] = cellPos(l, sw[1], sw[2])
          await moveTo(mx, my)
          await b.sleep(40 + rnd(80))
          await key('keyDown', 'ctrl'); await b.sleep(50)
          await click(2)
          await key('keyUp', 'ctrl')
          stats.swaps++
          continue
        }
      }
      if (!p) { p = placeAside(s, s.hand); if (p) stats.aside++ }
      if (!p) { p = [0, 1 + rnd(18), 6 + rnd(13)]; stats.missed++ }
      for (let i = 0; i < p[0]; i++) await press('space')
      const l = rotations(s.hand)[p[0]]
      let [mx, my] = cellPos(l, p[1], p[2])
      // a miss on purpose: one cell off (a neighbour square, or a shake)
      if (rnd(10) === 0 && !MONO) { mx += 30 * (rnd(3) - 1); my += 30 * (rnd(3) - 1); stats.missed++ }
      await moveTo(mx, my)
      await b.sleep(30 + rnd(100))
      await click()
      continue
    }
    // nothing in hand
    if (s.go && !s.pieces.length) {
      // time out, conveyor empty: a few moves of placed forms, then the end button
      if (s.end && (endAfter++ > 4 + rnd(4) || !s.forms.length)) {
        await moveTo(300, 70 + rnd(30))
        await b.sleep(200 + rnd(300))
        await click()
        await b.sleep(500)
        continue
      }
    }
    // take a form back now and then (or after the time out)
    if (s.forms.length && ((rnd(12) === 0 && !MONO) || (s.go && !s.pieces.length))) {
      const f = s.forms[rnd(s.forms.length)]
      const [cx, cy] = f.list[0]
      await moveTo(2 * (f.x + cx + 0.5) * 15, 2 * ((f.y + cy + 0.5) * 15 - 5))
      await b.sleep(30 + rnd(60))
      await click()
      stats.backs++
      continue
    }
    // a piece of the conveyor: one that fits in the target if possible
    const vis = s.pieces.filter((p) => p.x > 40 && p.x < 270)
    if (!vis.length) { stats.waits++; await b.sleep(100); continue }
    let pick = vis.find((p) => placeInTarget(s, p.list) && (!MONO || targetCol == null || p.list[0][2] % 3 === targetCol)) || (rnd(MONO ? 8 : 3) === 0 || ++targetTries > (MONO ? 30 : 6) ? vis[rnd(vis.length)] : null)
    if (targetTries > (MONO ? 60 : 12)) newTarget(s)
    if (!pick) { stats.waits++; await b.sleep(150); continue }
    const i = s.pieces.indexOf(pick)
    const c = pick.list[rnd(pick.list.length)]
    await moveTo(2 * (pick.x + (c[0] - pick.dx) * 15 - s.boost * 3), 2 * (pick.y + (c[1] - pick.dy) * 15 - 3))
    // where it is now (it moves on)
    const q = await b.eval(`(() => { const p = window.kk && kk.game && !kk.game.flGameOver && kk.game.pieceList[${i}]; return p ? [p.root._x, p.root._y, kk.game.pieceBoost] : null })()`)
    if (!q) continue
    await moveTo(2 * (q[0] + (c[0] - pick.dx) * 15 - q[2] * 2), 2 * (q[1] + (c[1] - pick.dy) * 15 - 3), 2)
    await click()
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver.replace(/"grid":"[^"]*"/, '"grid":…'), JSON.stringify(stats), 'replay chars', data.length)
  writeFileSync(gameDir('hypercube', 'replays') + '/h_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.grid)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep.replace(/"grid":"[^"]*"/, '"grid":…'), rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}

// the target is still empty or filled by whole forms placed in it (otherwise a new one)
function inTargetFree(s) {
  if (!target) return false
  for (let i = 0; i < target.n; i++) for (let j = 0; j < target.n; j++) {
    const x = target.x + i, y = target.y + j
    if (!s.grid[x][y]) continue
    const f = s.forms.find((f) => f.list.some(([cx, cy]) => f.x + cx === x && f.y + cy === y))
    if (!f || !f.list.every(([cx, cy]) => inTarget(f.x + cx, f.y + cy))) return false
  }
  return true
}
