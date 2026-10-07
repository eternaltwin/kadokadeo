// Cereal Punk bot + replay: plays a real game with key events (arrows, sometimes the ZQSD / WASD aliases): takes the
// top cereals of a column and throws them on a column whose top is the same kind (3 in a column explode), takes the
// bonuses, rearranges when nothing matches; after MAXT ticks it stacks everything on one column until the game over
// (cereals thrown on a full column fly away: the out of screen combo). Then it plays the replay and compares the end
// state (MATCH expected).
// usage: node cp3.mjs [bot seed] [replay speed]
// env: PORT (DevTools, default 9862; the replay uses PORT + 50), HPORT, EXTRA (url params, test modes), MAXT (bot ticks),
//      BLIND=1: no state read, a fixed pattern (take, one column right, throw, back) until the game over (with
//      EXTRA='&test=cp&maxtime=1&hold=N' the columns are full: the throws fly above the screen),
//      PAT=up,right,...: these keys once (0.7 s apart), then wait for the end (scenarios: EXTRA='&test=cp&setup=a...')
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=cerealpunk&cls=GameCerealPunk&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9862)
const MAXT = +(process.env.MAXT || 700)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'] }
const ALT = { left: [65, 'KeyA'], up: [87, 'KeyW'], right: [68, 'KeyD'], down: [83, 'KeyS'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const stats = { takes: 0, throws: 0, bonusTakes: 0, stoneTakes: 0, fullThrows: 0, maxScore: 0 }
const tap = async (name, ms) => {
  const kk = rnd(5) === 0 ? ALT[name] : K[name]
  await send('keyDown', kk); await b.sleep(ms || 50 + rnd(70)); await send('keyUp', kk)
}
const STATE = `(() => { const g = kk.game; const h = g.hero; const cols = []
  for (let x = 0; x < 8; x++) { const c = []; for (let y = 0; y < 12; y++) { const l = g.level.legumes[x][y]; c.push(l == null ? -1 : l.id) } cols.push(c) }
  return { over: !!window.__over, go: window.__state && window.__state.gameOver, frame: window.__state && window.__state.frame,
    px: h.px, held: h.legumes.length, hid: h.legumes.length ? h.legumes[0].id : -1, lock: g.animator.locked(false),
    score: window.__state && window.__state.score, cols } })()`
// top of a column: [row, kind, run of that kind from the top]
const top = (c) => { let y = 0; while (y < 12 && c[y] < 0) y++; if (y == 12) return [12, -1, 0]; let r = 1; while (y + r < 12 && c[y + r] == c[y]) r++; return [y, c[y], r] }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let target = -1, plan = null, sink = -1
  if (process.env.PAT) {
    await b.sleep(1000)
    for (const k of process.env.PAT.split(',')) { await tap(k, 60); await b.sleep(700); t++ }
    console.log('state', await b.eval('JSON.stringify(window.__state.cov)'))
  }
  if (process.env.BLIND) {
    // take, one column further (sweeping right then left), throw
    let dir = 'right'
    for (; !(await b.eval('!!window.__over')); t++) {
      const px = await b.eval('kk.game.hero.px')
      if (px == 7) dir = 'left'
      if (px == 0) dir = 'right'
      const k = ['up', dir, 'down'][t % 3]
      await tap(k, 60)
      if (k == 'down') stats.throws++
      await b.sleep(500)
      if (process.env.LOG) console.log(t, k, await b.eval('JSON.stringify([window.__state.frame, window.__state.px, window.__state.held, window.__state.height, window.__state.cov])'))
    }
  }
  for (; !process.env.BLIND && !process.env.PAT; t++) {
    const s = await b.eval(STATE)
    if (s.over) break
    stats.maxScore = Math.max(stats.maxScore, s.score)
    const tops = s.cols.map(top)
    const end = t >= MAXT
    if (s.held == 0) {
      // choose a column to take from (and where its cereals will go)
      if (plan == null || tops[plan.src][1] < 0) {
        plan = null
        const cand = []
        for (let x = 0; x < 8; x++) {
          const [y, k, r] = tops[x]
          if (k < 0 || k == 20) continue
          if (k == 22 || k == 23) { cand.push({ src: x, dst: -1, v: 100 }); continue }
          if (k == 21) { cand.push({ src: x, dst: -1, v: end ? 5 : 1 }); continue }
          for (let d = 0; d < 8; d++) if (d != x && tops[d][1] == k) cand.push({ src: x, dst: d, v: (r + tops[d][2] >= 3 ? 20 : 3) + r })
          cand.push({ src: x, dst: -1, v: 2 })
        }
        if (cand.length) {
          cand.sort((a, b) => b.v - a.v + (rnd(3) - 1) * 0.5)
          plan = cand[end ? rnd(cand.length) : (rnd(6) == 0 ? rnd(cand.length) : 0)]
        }
      }
      if (plan) {
        if (s.px != plan.src) await tap(s.px > plan.src ? 'left' : 'right')
        else if (!s.lock) {
          const k = tops[plan.src][1]
          await tap('up')
          stats.takes++
          if (k == 22 || k == 23) stats.bonusTakes++
          if (k == 21) stats.stoneTakes++
          target = plan.dst
          if (k == 22 || k == 23) plan = null
        }
      }
    } else {
      // throw: on the planned column, or a column whose top is the same kind, or the lowest one; at the end, always
      // on the tallest (sink) column
      plan = null
      if (end) {
        if (sink < 0 || rnd(40) == 0) { sink = 0; for (let x = 1; x < 8; x++) if (tops[x][0] < tops[sink][0]) sink = x }
        target = sink
      } else if (target < 0 || target == s.px && tops[target][1] != s.hid) {
        target = -1
        for (let x = 0; x < 8; x++) if (x != s.px && tops[x][1] == s.hid) target = x
        if (target < 0) { let best = -1; for (let x = 0; x < 8; x++) if (x != s.px && (best < 0 || tops[x][0] > tops[best][0])) best = x; target = best }
      }
      if (s.px != target) await tap(s.px > target ? 'left' : 'right')
      else {
        if (tops[target][0] == 0) stats.fullThrows++
        await tap('down'); stats.throws++
        target = -1
      }
    }
    await b.sleep(40 + rnd(60))
  }
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('cerealpunk', 'replays') + '/cp3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
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
