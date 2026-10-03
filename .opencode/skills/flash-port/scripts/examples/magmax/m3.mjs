// Magmax: a bot plays a whole game with real key presses (aims at the nearest monster, strafes while firing to keep
// its direction, runs from monsters and their shots, picks the bonuses; arrows and ZQSD-WASD aliases, Space,
// Control and Enter to fire), then its replay is played and the end states compared.
// usage: node m3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, MAXT (actions before
//        the bot stops playing), SEED
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=magmax&cls=GameMagmax&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9610)
const MAXT = +(process.env.MAXT || 100000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'], fire: [32, ' ', 'Space'] }
const ALT = { left: [65, 'a', 'KeyA'], right: [68, 'd', 'KeyD'], up: [87, 'w', 'KeyW'], down: [83, 's', 'KeyS'] }
const FIRE_ALT = [[17, 'Control', 'ControlLeft'], [13, 'Enter', 'Enter']]
let b = await launch(PORT)
const send = (type, [code, k, c]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c || k })
const held = new Map()
const hold = async (name, on) => {
  if (on && !held.has(name)) {
    const kk = name === 'fire' ? (rnd(5) === 0 ? FIRE_ALT[rnd(2)] : K.fire) : rnd(4) === 0 ? ALT[name] : K[name]
    await send('keyDown', kk); held.set(name, kk)
  }
  if (!on && held.has(name)) { await send('keyUp', held.get(name)); held.delete(name) }
}
const STATE = `(() => { const g = kk.game; if (!g || !g.hero) return null
  return { over: !!window.__over, dead: g.game_over, x: g.hero.x, y: g.hero.y, tang: g.hero.tang,
    m: g.monsters.map(m => ({ x: m.x, y: m.y, t: m.type })),
    s: g.tirs.filter(t => t.fromMonster).map(t => ({ x: t.x, y: t.y, dx: t.dx, dy: t.dy })),
    b: g.bonus.map(o => ({ x: o._x, y: o._y, t: o.t })) } })()`
const stats = { fire: 0, flee: 0, bonus: 0, aim: 0 }
let live, data, liveOver, t = 0
const sgn = (v, d) => v > d ? 1 : v < -d ? -1 : 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % (+process.env.SHOT_EVERY || 40) === 0 && snap < 40) await b.screenshot(shots + '/m' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 })
    let mx = 0, my = 0, fire = false
    if (!s.dead && t < MAXT) {
      // danger: monsters close, monster shots coming
      let fx = 0, fy = 0
      for (const m of s.m) {
        const dx = s.x - m.x, dy = s.y - m.y, d = Math.hypot(dx, dy)
        if (d < 70) { fx += dx / (d + 1) * (70 - d); fy += dy / (d + 1) * (70 - d) }
      }
      for (const o of s.s) {
        const dx = s.x - o.x, dy = s.y - o.y, d = Math.hypot(dx, dy)
        if (d < 45 && dx * o.dx + dy * o.dy > 0) { fx += -o.dy * Math.sign(dx * -o.dy + dy * o.dx) * (45 - d); fy += o.dx * Math.sign(dx * -o.dy + dy * o.dx) * (45 - d) }
      }
      // keep off the borders
      fx += (s.x < 40 ? 40 - s.x : 0) - (s.x > 260 ? s.x - 260 : 0)
      fy += (s.y < 45 ? 45 - s.y : 0) - (s.y > 265 ? s.y - 265 : 0)
      const target = s.m.filter(m => m.x > 0 && m.x < 300 && m.y > 0 && m.y < 300).sort((a, c) => Math.hypot(a.x - s.x, a.y - s.y) - Math.hypot(c.x - s.x, c.y - s.y))[0]
      if (Math.hypot(fx, fy) > 8) {
        mx = sgn(fx, 3); my = sgn(fy, 3); fire = true; stats.flee++
      } else if (s.b.length && rnd(3)) {
        const o = s.b.sort((a, c) => Math.hypot(a.x - s.x, a.y - s.y) - Math.hypot(c.x - s.x, c.y - s.y))[0]
        mx = sgn(o.x - s.x, 4); my = sgn(o.y - s.y, 4); fire = rnd(2) === 0; stats.bonus++
      } else if (target) {
        // face the monster (fire released while turning), then fire, moving to keep a row / column / diagonal
        const dx = target.x - s.x, dy = target.y - s.y
        const want = Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4)
        let da = Math.abs(((s.tang - want) % (2 * Math.PI) + 3 * Math.PI) % (2 * Math.PI) - Math.PI)
        if (da > 0.1) { mx = Math.round(Math.cos(want)); my = Math.round(Math.sin(want)); fire = false; stats.aim++ }
        else {
          fire = true
          const ax = Math.abs(dx), ay = Math.abs(dy)
          if (Math.abs(Math.cos(want)) < 0.1) mx = sgn(dx, 3)
          else if (Math.abs(Math.sin(want)) < 0.1) my = sgn(dy, 3)
          else if (Math.abs(ax - ay) > 6) { if (ax > ay) mx = sgn(dx, 0); else my = sgn(dy, 0) }
        }
      } else if (rnd(8) === 0) { mx = rnd(3) - 1; my = rnd(3) - 1 }
      if (fire) stats.fire++
    }
    await hold('left', mx < 0); await hold('right', mx > 0)
    await hold('up', my < 0); await hold('down', my > 0)
    await hold('fire', fire)
    await b.sleep(15 + rnd(25))
  }
  for (const name of [...held.keys()]) await hold(name, false)
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('magmax', 'replays') + '/m_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
