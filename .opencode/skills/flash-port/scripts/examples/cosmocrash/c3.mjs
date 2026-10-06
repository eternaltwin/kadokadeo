// Cosmo Crash bot + replay: plays a real game with key events (arrows, sometimes the WASD aliases): flies above the
// colonists so they jump on, brings them to a platform, lands softly (they walk into the shuttle), refuels, takes off
// again, until the game over; then plays the replay and compares the end state (MATCH expected).
// usage: node c3.mjs [bot seed] [replay speed] [shots dir]
// env: PORT (DevTools, default 9924; the replay uses PORT + 50), HPORT, EXTRA (url params, test modes), MAXT (bot ticks)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=cosmocrash&cls=GameCosmoCrash&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9924)
const MAXT = +(process.env.MAXT || 6000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'] }
const ALT = { left: [65, 'KeyA'], up: [87, 'KeyW'], right: [68, 'KeyD'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = {}
const set = async (name, on) => {
  if (on && !held[name]) { const kk = rnd(5) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held[name] = kk }
  else if (!on && held[name]) { await send('keyUp', held[name]); held[name] = null }
}
const STATE = `(() => { const g = kk.game; const h = g.hero
  const fo = []; for (const f of g.folks) if (f.step == 1) fo.push([f.x, f.y])
  return { over: !!window.__over, frame: window.__state && window.__state.frame, fuel: g.fuel, rescue: g.flRescue,
    h: h ? { x: h.x, y: h.y, vx: h.vx, vy: h.vy, a: h.angle, step: h.step, n: h.folks.length, ready: h.flReady } : null,
    folks: fo, plats: g.plats.map(p => [p.x, p.y, p.ray, p.step]), veh: g.vehicules.map(v => v.x) } })()`
const LW = 2000
const hmod = (n, m) => { while (n > m) n -= 2 * m; while (n < -m) n += 2 * m; return n }
const clamp = (v, a, b) => Math.max(a, Math.min(b, v))
const stats = { pick: 0, land: 0, takeoff: 0, crashes: 0, maxCarry: 0, loops: 0 }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let want = 1 + rnd(4), landedAt = -1, wasDead = false, lastN = 0, looping = 0, looped = false
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 60 === 0) await b.screenshot(shots + '/c' + String(t / 60).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    const h = s.h
    if (!h) {
      if (!wasDead) { stats.crashes++; wasDead = true }
      await set('left', false); await set('right', false); await set('up', false)
      await b.sleep(30)
      continue
    }
    wasDead = false
    if (h.n > lastN) stats.pick += h.n - lastN
    lastN = h.n
    stats.maxCarry = Math.max(stats.maxCarry, h.n)
    if (h.step === 1) {
      // landed: wait for the colonists to get off and for some fuel, then take off (up released first: flReady)
      await set('left', false); await set('right', false)
      if (landedAt < 0) { landedAt = t; stats.land++; want = 1 + rnd(5); looped = false }
      if (h.n === 0 && t - landedAt > 6 + rnd(30) && (s.fuel > 60 || t - landedAt > 120) && h.ready) {
        await set('up', true); stats.takeoff++; landedAt = -1
      } else await set('up', false)
      await b.sleep(25)
      continue
    }
    landedAt = -1
    // target: a colonist on the ground (until `want` are on board), else the nearest platform
    const gy = (x) => b.eval(`kk.game.getGY(${x})`)
    let tx, ty, land = false
    const cand = s.folks.map(([fx, fy]) => [Math.abs(hmod(fx - h.x, LW / 2)), fx, fy]).sort((a, c) => a[0] - c[0])
    if (h.n < want && s.fuel > 30 && cand.length) {
      tx = cand[0][1]; ty = cand[0][2] - 32
    } else {
      const pl = s.plats.map(p => [Math.abs(hmod(p[0] - h.x, LW / 2)), ...p]).sort((a, c) => a[0] - c[0])[0]
      tx = pl[1]; ty = pl[2] - 40
      land = pl[0] < pl[3] * 0.6
      if (land) ty = pl[2] + 5
    }
    const dx = hmod(tx - h.x, LW / 2)
    // stay above the ground on the way (both sides of the ship touch it)
    const wrap = (x) => ((x % LW) + LW) % LW
    const ahead = await gy(wrap(h.x + clamp(h.vx * 25, -60, 60)))
    const here = Math.min(await gy(wrap(h.x - 15)), await gy(wrap(h.x + 15)))
    ty = Math.min(ty, Math.min(ahead, here) - 40)
    if (land) ty = s.plats.find(p => Math.abs(hmod(p[0] - tx, LW / 2)) < 1)[1] + 5
    // never cross a platform from above outside of a landing: stay above it until clear on the side
    for (const p of s.plats) {
      const pdx = Math.abs(hmod(p[0] - h.x, LW / 2))
      if (!land && h.y < p[1] - 5 && pdx < p[2] + 25 && ty > p[1] - 30) ty = p[1] - 35
    }
    // the "loop" bonus (Hero.updateFly: the ship pointing left, angle ~ 3.14, then a landing with colonists within 100
    // frames): left held without thrust tilts it there; done once per trip, high enough above the platform
    const platY = land ? s.plats.find(p => Math.abs(hmod(p[0] - tx, LW / 2)) < 1)[1] : 0
    if (h.n > 0 && land && !looped && Math.abs(dx) < 10 && platY - h.y > 35 && platY - h.y < 70 && Math.abs(h.vy) < 0.6 && rnd(2) === 0) looping = 1
    if (looping) {
      await set('right', false); await set('up', false); await set('left', true)
      if (h.a < -3.0 || looping++ > 40 || h.y > Math.min(here, ahead) - 50 || (land && platY - h.y < 28)) { looping = 0; looped = true; stats.loops++; await set('left', false) }
      await b.sleep(15 + rnd(25))
      continue
    }
    const vmax = land ? 0.6 : h.n ? 1.4 : 1.8
    const vxd = clamp(dx * 0.02, -vmax, vmax)
    const vyd = land ? (Math.abs(dx) < 15 ? 0.7 : 0.1) : clamp((ty - h.y) * 0.03, -1.4, 1.0)
    const g = 0.05 + h.n * 0.02
    // thrust needed (per frame): the velocity error closed in a few frames, gravity compensated (y down)
    const ax = (vxd - h.vx) * 0.15
    const ay = (vyd - h.vy) * 0.15 - g
    // the direction of the thrust, within 0.7 rad of up (and up when landing near the platform); none downwards
    let ad = ay < 0 ? Math.atan2(ay, ax) : -1.57
    ad = clamp(hmod(ad + 1.57, Math.PI), -0.7, 0.7) - 1.57
    if (land && Math.abs(dx) < 20) ad = clamp(ad, -1.57 - 0.12, -1.57 + 0.12)
    const da = hmod(ad - h.a, Math.PI)
    await set('right', da > 0.06)
    await set('left', da < -0.06)
    const duty = clamp(Math.hypot(ax, ay) / 0.2, 0, 1)
    await set('up', s.fuel > 0 && ay < -0.005 && Math.abs(da) < 0.4 && rnd(100) < duty * 100)
    if (process.env.LOG && t % 40 === 0) console.log(t, s.frame, JSON.stringify(h), 'tx', tx.toFixed(0), 'ty', ty.toFixed(0), 'land', land, 'fuel', s.fuel.toFixed(1))
    await b.sleep(15 + rnd(25))
  }
  for (const k of ['left', 'right', 'up']) await set(k, false)
  // a game that does not end: the test mode's frames=N, or the bot gives up (the hero crashes on purpose)
  const t0 = Date.now()
  while (!(await b.eval('!!window.__over')) && Date.now() - t0 < 60000) { await set('right', true); await set('up', true); await b.sleep(200) }
  for (const k of ['left', 'right', 'up']) await set(k, false)
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('cosmocrash', 'replays') + '/c3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
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
