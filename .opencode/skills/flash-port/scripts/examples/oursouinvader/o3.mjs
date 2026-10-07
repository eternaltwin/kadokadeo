// Oursouinvader bot + replay: plays a real game with key events (arrows and Space, sometimes the WASD / Enter
// aliases): dodges the enemy shots, goes under the monsters and shoots, catches the bonuses, until the game over (after
// MAXT ticks it stops dodging); then plays the replay and compares the end state (MATCH expected).
// usage: node o3.mjs [bot seed] [replay speed] [shots dir]
// env: PORT (DevTools, default 9962; the replay uses PORT + 1), HPORT, EXTRA (url params, test modes), MAXT (bot ticks),
//      NOFIRE=1 (never shoots: the monsters come down and dive at the hero)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=oursouinvader&cls=GameOursouinvader&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9962)
const MAXT = +(process.env.MAXT || 2500)
const K = { left: [37, 'ArrowLeft', 'ArrowLeft'], right: [39, 'ArrowRight', 'ArrowRight'], fire: [32, ' ', 'Space'] }
const ALT = { left: [65, 'a', 'KeyA'], right: [68, 'd', 'KeyD'], fire: [13, 'Enter', 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, k, c]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c })
const held = {}
const set = async (name, on) => {
  if (on && !held[name]) { const kk = rnd(6) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held[name] = kk }
  else if (!on && held[name]) { await send('keyUp', held[name]); held[name] = null }
}
const STATE = `(() => { const g = kk.game; const h = g.hero
  return { over: !!window.__over, frame: window.__state && window.__state.frame, step: g.step,
    h: { x: h.x, y: h.y, dead: h.dead, sp: h.speed },
    m: g.monsterList.map(m => [m.x, m.y, m.ray, m.mType, m.flKamikaze ? 1 : 0, m.vx]),
    s: g.shotList.filter(s => s.badShot).map(s => [s.x, s.y, s.vy, s.ray]),
    bo: g.bonusList.map(o => [o.x, o.y, o.bType]),
    dir: g.direction, ms: g.mSpeed } })()`
const clamp = (v, a, c) => Math.max(a, Math.min(c, v))
const stats = { dodge: 0, bonus: 0, waves: 0 }
let data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let target = 150, lastFire = 0
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 80 === 0) await b.screenshot(shots + '/o' + String(t / 80).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    const hx = s.h.x
    const careless = t > MAXT * 0.8
    // danger: an enemy shot that will reach the hero's line close to it (positions in a few frames)
    let danger = null
    for (const [sx, sy, svy] of s.s) {
      const f = svy > 0 ? (285 - 15 - sy) / Math.max(svy * 0.8, 0.5) : 99
      if (sy < 300 && f < 30 && Math.abs(sx - hx) < 34) { if (!danger || f < danger.f) danger = { x: sx, f } }
    }
    for (const m of s.m) if (m[4] && m[1] > 200 && Math.abs(m[0] - hx) < 50) { if (!danger || danger.f > 8) danger = { x: m[0], f: 8 } }
    if (danger && !careless) {
      stats.dodge++
      // to the side with room
      target = danger.x > hx ? (hx - 60 < 22 ? danger.x + 60 : hx - 60) : (hx + 60 > 278 ? danger.x - 60 : hx + 60)
    } else if (s.bo.length && rnd(4) > 0) {
      const o = s.bo.sort((a, c) => c[1] - a[1])[0]
      target = o[0]
    } else if (s.m.length) {
      // the lowest monster, ahead of its move (the wave moves dir * mSpeed per frame)
      const m = s.m.slice().sort((a, c) => c[1] - a[1] + (rnd(3) - 1) * 10)[0]
      const lead = m[4] ? m[5] * 8 : s.dir * s.ms * 10
      target = clamp(m[0] + lead, 22, 278)
    }
    const dx = target - hx
    const dead = Math.max(2, s.h.sp * 0.6)
    await set('left', dx < -dead)
    await set('right', dx > dead)
    // shoot most of the time (the cooldown limits it), sometimes released
    const fire = !process.env.NOFIRE && s.step === 1 && (rnd(10) > 0 || t - lastFire > 20)
    if (fire) lastFire = t
    await set('fire', fire)
    if (process.env.LOG && (t % 40 === 0 || s.s.length)) console.log(t, s.frame, 'hx', hx, 'target', target.toFixed(0), 'm', s.m.length, 'bad', JSON.stringify(s.s), danger ? 'DANGER' : '')
    await b.sleep(10 + rnd(20))
  }
  for (const k of ['left', 'right', 'fire']) await set(k, false)
  // a game that does not end: the bot gives up (stands under the lowest monster without shooting)
  const t0 = Date.now()
  while (!(await b.eval('!!window.__over')) && Date.now() - t0 < 180000) {
    const s = await b.eval(STATE)
    const m = s.m.length ? s.m.slice().sort((a, c) => c[1] - a[1])[0] : null
    const sh = s.s.length ? s.s.slice().sort((a, c) => c[1] - a[1])[0] : null
    const tx = sh ? sh[0] : m ? m[0] : 150
    await set('left', tx < s.h.x - 3); await set('right', tx > s.h.x + 3)
    await set('fire', !m || m[1] < 150)
    await b.sleep(20)
  }
  for (const k of ['left', 'right', 'fire']) await set(k, false)
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('oursouinvader', 'replays') + '/o3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 1)
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
