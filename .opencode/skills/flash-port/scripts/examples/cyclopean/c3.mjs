// Cyclopean: a bot plays a whole game with real key presses (left / right turn the cave so that the gravity takes
// the chick along a path to the nearest bonus, or to the pentacle when balls follow it; another bonus when it is
// stuck; the
// aliases Q / D too; random taps while the level is made, which changes the level: the gameplay random is stirred
// by the inputs), then its replay is played and the end states compared.
// usage: node c3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, HPORT, SEED
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=cyclopean&cls=GameCyclopean&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9871)
const K = { left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'] }
const ALT = { left: [81, 'KeyA'], right: [68, 'KeyD'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = new Map()
const hold = async (name, on) => {
  if (on && !held.has(name)) { const kk = rnd(4) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held.set(name, kk) }
  if (!on && held.has(name)) { await send('keyUp', held.get(name)); held.delete(name) }
}
// path finding in the page: cells of 4 px, free when the level is a hole there (alpha <= 60) and around it (the
// chick is 8 px wide); a BFS from the target, then the point 40 px further along the path from the chick
const NAV = `window.__nav = (tx, ty, bx, by) => { const g = kk.game, A = g.level.alpha, S = 1600, C = 4, N = S / C
  if (!window.__free) { const f = new Uint8Array(N * N); for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) { let ok = 1
      for (let j = -1; j <= 1 && ok; j++) for (let i = -1; i <= 1; i++) { const px = x * C + 2 + i * 6, py = y * C + 2 + j * 6
        if (px >= 0 && py >= 0 && px < S && py < S && A[py * S + px] > 60) { ok = 0; break } }
      f[y * N + x] = ok } window.__free = f }
  const F = window.__free, key = (tx | 0) + ',' + (ty | 0)
  if (window.__navKey !== key) { const D = new Int32Array(N * N).fill(-1), q = new Int32Array(N * N); let h = 0, t = 0
    const s = Math.min(N - 1, Math.max(0, ty / C | 0)) * N + Math.min(N - 1, Math.max(0, tx / C | 0)); D[s] = 0; q[t++] = s
    while (h < t) { const c = q[h++], cx = c % N, cy = (c / N) | 0
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const nx = cx + dx, ny = cy + dy; if (nx < 0 || ny < 0 || nx >= N || ny >= N) continue
        const n = ny * N + nx; if (D[n] >= 0 || !F[n]) continue; D[n] = D[c] + 1; q[t++] = n } }
    window.__navD = D; window.__navKey = key }
  const D = window.__navD; let c = Math.min(N - 1, Math.max(0, by / C | 0)) * N + Math.min(N - 1, Math.max(0, bx / C | 0))
  if (D[c] < 0) { let best = -1; for (let j = -3; j <= 3; j++) for (let i = -3; i <= 3; i++) { const n = c + j * N + i; if (n >= 0 && n < N * N && D[n] >= 0 && (best < 0 || D[n] < D[best])) best = n } if (best < 0) return null; c = best }
  for (let k = 0; k < 10 && D[c] > 0; k++) { const cx = c % N, cy = (c / N) | 0; let nb = c
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const n = (cy + dy) * N + cx + dx; if (D[n] >= 0 && D[n] < D[nb]) nb = n } if (nb === c) break; c = nb }
  return { x: (c % N) * C + 2, y: ((c / N) | 0) * C + 2, d: D[c] } }`
const STATE = `(() => { const g = kk.game; if (!g) return null
  if (g.step !== 1) return { over: !!window.__over, step: g.step }
  const b = g.ball
  return { over: !!window.__over, step: g.step, x: b.x, y: b.y, vx: b.vx, vy: b.vy, angle: g.angle, t: g.gameTimer, gen: g.generator.length,
    follow: g.bList.filter(o => o.step === 1).length,
    el: g.eList.map(e => ({ x: e.x, y: e.y, id: e.id })) } })()`
const stats = { left: 0, right: 0, stuck: 0, center: 0 }
const hMod = (v, m) => { while (v > m) v -= 2 * m; while (v < -m) v += 2 * m; return v }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  let snap = 0, lastX = 0, lastY = 0, lastT = 0, wander = 0, skip = 1, navOn = false
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % (+process.env.SHOT_EVERY || 40) === 0 && snap < 40) await b.screenshot(shots + '/c' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (s.step === 0) {
      // the level is being made: a random tap now and then (a different level for each bot seed)
      if (rnd(6) === 0) { const n = rnd(2) ? 'left' : 'right'; await hold(n, true); await b.sleep(20 + rnd(60)); await hold(n, false) }
      await b.sleep(20)
      continue
    }
    if (s.step !== 1) { await hold('left', false); await hold('right', false); await b.sleep(50); continue }
    if (!navOn) { await b.eval(NAV); navOn = true }
    // stuck (barely moved for a while): another target for a moment
    if (t - lastT > 80) {
      if (Math.hypot(s.x - lastX, s.y - lastY) < 30 && !wander) { wander = 60 + rnd(60); stats.stuck++; skip = 1 + rnd(3) }
      lastX = s.x; lastY = s.y; lastT = t
    }
    let target
    if (s.follow > 0 && !wander) { target = { x: 800, y: 800 }; stats.center++ }
    else {
      const el = s.el.slice().sort((a, c) => Math.hypot(a.x - s.x, a.y - s.y) - Math.hypot(c.x - s.x, c.y - s.y))
      target = el[wander ? Math.min(skip, el.length - 1) : 0] || { x: 800, y: 800 }
    }
    if (wander) wander--
    const way = await b.eval(`JSON.stringify(window.__nav(${target.x}, ${target.y}, ${s.x}, ${s.y}))`).then(JSON.parse)
    const aim = way || target
    // the gravity points to -angle + 1.57 in the level: the angle that drops the chick towards the aim (minus its
    // speed: brake when it goes too fast the wrong way)
    const want = 1.57 - Math.atan2(aim.y - s.y - s.vy * 6, aim.x - s.x - s.vx * 6)
    const d = hMod(want - s.angle, Math.PI)
    const dir = d > 0.2 ? 'right' : d < -0.2 ? 'left' : null
    if (dir && !held.has(dir)) stats[dir]++
    await hold('left', dir === 'left')
    await hold('right', dir === 'right')
    await b.sleep(15 + rnd(30))
  }
  for (const name of [...held.keys()]) await hold(name, false)
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('cyclopean', 'replays') + '/c_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
