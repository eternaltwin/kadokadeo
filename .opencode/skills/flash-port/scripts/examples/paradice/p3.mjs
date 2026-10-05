// Paradice: a bot plays a whole game with real key presses (chooses the shift of the carried balls that makes the
// biggest groups, moves the row with the arrows or the ZQSD-WASD aliases, validates with Up, Space, Enter or by
// waiting for the timer), then its replay is played and the end states compared.
// usage: node p3.mjs <rng seed> [replay speed]     env: EXTRA (url params), PORT, HPORT, MAXT (plays before the bot
//        stops moving: the timer then validates every row), SEED, SHOTS (dir: a screenshot every play)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=paradice&cls=GameParadice&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9750)
const MAXT = +(process.env.MAXT || 100000)
const SHOTS = process.env.SHOTS
const K = { left: [[37, 'ArrowLeft', 'ArrowLeft'], [65, 'a', 'KeyA'], [81, 'q', 'KeyQ']], right: [[39, 'ArrowRight', 'ArrowRight'], [68, 'd', 'KeyD']],
  ok: [[38, 'ArrowUp', 'ArrowUp'], [32, ' ', 'Space'], [13, 'Enter', 'Enter'], [87, 'w', 'KeyW']] }
let b = await launch(PORT)
const send = (type, [code, k, c]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c || k })
const pick = (name) => (rnd(4) === 0 ? K[name][1 + rnd(K[name].length - 1)] : K[name][0])
const STATE = `(() => { const g = kk.game; if (!g || !g.ground) return null; const G = g.ground
  return { over: !!window.__over, step: g.step, gstep: G.step, play: g.play, dx: G.dx, cm: G.cMove,
    carried: G.bList ? G.bList.map(o => ({ x: o.x, c: o.b.col == null ? -1 : o.b.col })) : [],
    special: G.special == null ? -1 : G.special,
    grid: g.grid.map(col => col.slice(0, 11).map(o => o == null ? -2 : o.flIce ? -1 : o.col)) } })()`
// groups of 4+ (4 neighbours) after pushing the carried balls with the shift s; the height of the stack
function evalShift(s, st) {
  const g = st.grid.map(c => { const a = []; for (let y = 0; y < 11; y++) a.push(c[y] == null ? -2 : c[y]); return a })
  for (const o of st.carried) {
    const x = ((o.x + s) % 10 + 10) % 10
    g[x].unshift(o.c); g[x].length = 11
  }
  const seen = g.map(c => c.map(() => false))
  let score = 0, adj = 0
  for (let x = 0; x < 10; x++) for (let y = 0; y < 11; y++) {
    const c = g[x][y]
    if (c < 0 || seen[x][y]) continue
    const stack = [[x, y]]; seen[x][y] = true; let n = 0
    while (stack.length) {
      const [px, py] = stack.pop(); n++
      for (const [ax, ay] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = px + ax, ny = py + ay
        if (nx < 0 || nx > 9 || ny < 0 || ny > 10 || seen[nx][ny] || g[nx][ny] !== c) continue
        seen[nx][ny] = true; stack.push([nx, ny])
      }
    }
    if (n >= 4) score += n * n
    else adj += n * n
  }
  let h = 0
  for (let x = 0; x < 10; x++) { let k = 0; while (k < 11 && g[x][k] !== -2) k++; h = Math.max(h, k) }
  return score * 10 + adj - h * h * 2
}
const stats = { plays: 0, moves: 0, waits: 0 }
let data, liveOver, shot = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.ground)', 60000)
  let lastPlay = -1
  for (;;) {
    let s = await b.eval(STATE)
    if (!s || s.over) break
    if (s.step !== 3 || s.gstep !== 0 || s.play === lastPlay) { await b.sleep(20); continue }
    lastPlay = s.play
    stats.plays++
    if (SHOTS && shot < 200) await b.screenshot(SHOTS + '/p' + String(shot++).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    if (s.play > MAXT) { stats.waits++; continue }
    // best shift (relative to the current dx), a random one now and then
    let best = 0, bv = -1e9
    for (let k = 0; k < 10; k++) {
      const v = evalShift(k, s) + rnd(3)
      if (v > bv) { bv = v; best = k }
    }
    if (rnd(12) === 0) best = rnd(10)
    // shortest way round
    let steps = best <= 5 ? best : best - 10
    const dir = steps > 0 ? 'right' : 'left'
    let target = ((s.dx + steps) % 10 + 10) % 10
    if (steps !== 0) {
      stats.moves++
      const kk = pick(dir)
      await send('keyDown', kk)
      const t0 = Date.now()
      for (;;) {
        await b.sleep(8)
        const d = await b.eval('kk.game.ground.dx')
        if (d === target || Date.now() - t0 > 4000) break
      }
      await send('keyUp', kk)
      // wait for the end of the move (the penguins catch the balls)
      const t1 = Date.now()
      while (Date.now() - t1 < 3000) { const g = await b.eval('kk.game.ground.step + "/" + kk.game.step'); if (g !== '1/3') break; await b.sleep(10) }
    }
    if (rnd(10) === 0) { stats.waits++; continue }     // the timer validates
    await b.sleep(rnd(200))
    const ok = pick('ok')
    await send('keyDown', ok); await b.sleep(60 + rnd(80)); await send('keyUp', ok)
  }
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'replay chars', data.length)
  writeFileSync(gameDir('paradice', 'replays') + '/p_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.ground)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
