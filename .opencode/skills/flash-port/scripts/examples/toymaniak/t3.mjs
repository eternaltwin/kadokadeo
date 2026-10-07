// Toy Maniak: a bot plays a whole game with real mouse events (moves like a hand, presses on the toys of the rails and
// on the slots of the box), keeping the combos of the rails going: it takes away (or swaps) the toys that would break a
// combo, stores toys in the slots, gives the bonuses to the best rail, and after the 100 s puts the toys of the slots
// back on the rails so that the game can end. Then the replay of the game is played and the end states compared.
// usage: node t3.mjs <bot seed> [replay speed]     env: EXTRA (url params: '&test=...'), PORT, HPORT, SEED (game seed,
//        debug builds play 123), SHOTS (dir: a screenshot every 40 actions), RANDOM (1 in N actions random, 8)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=toymaniak&cls=GameToyManiak&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9964)
const SHOTS = process.env.SHOTS
const RANDOM = +(process.env.RANDOM || 8)
let b = await launch(PORT)
// (Flash pixels -> page pixels: the canvas at (8, 8), x2)
const mouse = (type, x, y, buttons = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + 2 * x, y: 8 + 2 * y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1 })
const STATE = `(() => { const g = kk.game; if (!g || !g.rails) return null
  return { over: !!window.__over, time: g.time, frame: g.frameCount,
    rails: g.rails.map(r => ({ last: r.last, combos: r.ncombos, speed: r.speed * g.speed,
      toys: r.toys.map(t => ({ x: t.x, t: t.t, lock: t.lock })) })),
    sels: g.sels.map(s => s.t), cursor: g.cursor ? g.cursor.t : null } })()`
const SLOT = [[104, 272.6], [150, 272.6], [196, 272.6]]
const toyPos = (r, t, lead) => [t.x - lead, 70 + 75 * r - 22 + rnd(9) - 4]
// what to press: [x, y, why] (Flash pixels)
function plan(s) {
  const late = s.time >= 100
  const lead = (r) => s.rails[r].speed * 0.8 * 40 * 0.25
  const usable = (t, r) => !t.lock && t.x - lead(r) > 75 && t.x - lead(r) < 280
  const breaks = (t, rail) => t.t >= 0 && t.t < 4 && rail.last !== null && t.t !== rail.last
  if (rnd(RANDOM) === 0) {
    // something else (coverage): a random toy or slot
    if (rnd(2) === 0) { const i = rnd(3); return [SLOT[i][0] + rnd(21) - 10, SLOT[i][1] + rnd(21) - 10, 'rslot'] }
    const r = rnd(3), ts = s.rails[r].toys.filter((t) => usable(t, r))
    if (ts.length) { const t = ts[rnd(ts.length)]; return [...toyPos(r, t, lead(r)), 'rtoy'] }
  }
  if (s.cursor !== null) {
    const c = s.cursor
    let best = null
    s.rails.forEach((rail, r) => rail.toys.forEach((t) => {
      if (!usable(t, r)) return
      let score = 0
      if (c < 4) { if (rail.last === c || rail.last === null) score += 10 } else score += 10 + rail.combos / 10
      if (t.t === -1) score += 5
      else if (breaks(t, rail)) score += 3
      else return
      score += (300 - t.x) / 100
      if (!best || score > best.score) best = { score, p: toyPos(r, t, lead(r)) }
    }))
    if (best && best.score >= 10) return [...best.p, 'drop']
    const e = s.sels.indexOf(-1)
    if (e >= 0 && !late) return [SLOT[e][0], SLOT[e][1], 'store']
    if (best) return [...best.p, 'dropAny']
    // a slot with a toy: swap
    if (!late) { const i = rnd(3); return [SLOT[i][0], SLOT[i][1], 'swapSlot'] }
    return null
  }
  // hand empty: a toy about to break a combo, soon at the crusher
  let worst = null
  s.rails.forEach((rail, r) => rail.toys.forEach((t) => {
    if (!usable(t, r) || !breaks(t, rail)) return
    // a slot holds the right toy: take it first (the swap comes next)
    const k = s.sels.indexOf(rail.last)
    const score = 300 - t.x
    if (!worst || score > worst.score) worst = { score, p: k >= 0 ? [SLOT[k][0], SLOT[k][1], 'takeSlot'] : [...toyPos(r, t, lead(r)), 'take'] }
  }))
  if (worst && worst.score > 60) return worst.p
  if (late) {
    // the end: the toys of the slots back on the rails
    const k = s.sels.findIndex((t) => t !== -1)
    if (k >= 0) return [SLOT[k][0], SLOT[k][1], 'unstore']
  }
  // a bonus on a rail without combo: to the best rail
  let bon = null
  s.rails.forEach((rail, r) => rail.toys.forEach((t) => {
    if (usable(t, r) && t.t >= 4 && (t.t === 5 || rail.combos < 5) && t.x < 230) bon = toyPos(r, t, lead(r))
  }))
  if (bon && rnd(2) === 0) return [...bon, 'takeBonus']
  return null
}
let pos = [150, 150]
async function moveTo(tx, ty) {
  const [sx, sy] = pos, n = 4 + rnd(6)
  for (let i = 1; i <= n; i++) {
    const t = i / n, e = t * t * (3 - 2 * t)
    pos = [sx + (tx - sx) * e + (rnd(3) - 1) * 0.5, sy + (ty - sy) * e + (rnd(3) - 1) * 0.5]
    await mouse('mouseMoved', pos[0], pos[1]); await b.sleep(10)
  }
}
const stats = {}
let data, liveOver, n = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.rails)', 60000)
  let shot = 0
  for (; ; n++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (SHOTS && n % 40 === 0 && shot < 60) await b.screenshot(SHOTS + '/t' + String(shot++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    const p = plan(s)
    if (!p) {
      if (rnd(3) === 0) await moveTo(Math.max(5, Math.min(295, pos[0] + rnd(41) - 20)), Math.max(5, Math.min(295, pos[1] + rnd(41) - 20)))
      await b.sleep(30)
      continue
    }
    stats[p[2]] = (stats[p[2]] || 0) + 1
    await moveTo(p[0], p[1])
    await b.sleep(10 + rnd(40))
    await mouse('mousePressed', pos[0], pos[1], 1); await b.sleep(20 + rnd(60)); await mouse('mouseReleased', pos[0], pos[1])
    await b.sleep(40 + rnd(60))
    if (n > 20000) { console.log('STUCK', JSON.stringify(s)); break }
  }
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', n, 'replay chars', data.length)
  writeFileSync(gameDir('toymaniak', 'replays') + '/t_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.rails)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
