// Judo Commando: a bot plays a whole game with real key events (arrows, and now and then the aliases WASD / Enter):
// it runs to the monsters, grapples them and throws them with every technique (tomoe nage, kata guruma, ippon seoi,
// osoto gari), lifts and drops the bodies, punches them, knee grabs and head crushes, arm locks the bodies on the
// ground, climbs ladders and ledges, hangs from the planks, jumps down through them, takes the end of level jump;
// then its replay is played and the end states compared.
// usage: node j3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, HPORT, SEED, MAXMS
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=judocommando&cls=GameJudoCommando&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9893)
const MAXMS = +(process.env.MAXMS || 600000)
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const KEYS = {
  left: [[37, 'ArrowLeft', 'ArrowLeft'], [65, 'a', 'KeyA']], right: [[39, 'ArrowRight', 'ArrowRight'], [68, 'd', 'KeyD']],
  up: [[38, 'ArrowUp', 'ArrowUp'], [87, 'w', 'KeyW']], down: [[40, 'ArrowDown', 'ArrowDown'], [83, 's', 'KeyS']],
  fire: [[32, ' ', 'Space'], [13, 'Enter', 'Enter']],
}
const held = {}   // name -> the key used
const press = async (name, down) => {
  if (down && !held[name]) {
    const k = KEYS[name][rnd(8) === 0 ? 1 : 0]
    held[name] = k
    await b.send('Input.dispatchKeyEvent', { type: 'keyDown', windowsVirtualKeyCode: k[0], nativeVirtualKeyCode: k[0], key: k[1], code: k[2] })
  } else if (!down && held[name]) {
    const k = held[name]
    delete held[name]
    await b.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: k[0], nativeVirtualKeyCode: k[0], key: k[1], code: k[2] })
  }
}
const want = async (set) => { for (const n of Object.keys(KEYS)) await press(n, !!set[n]) }
const tapKey = async (name, ms = 70) => { await press(name, true); await sleep(ms); await press(name, false) }
const STATE = `(() => { const g = kk.game; if (!g) return null; const h = g.hero; const nm = (e) => e ? e._hx_name : null
  const sq = (x, y) => g.grid && g.grid[x] && g.grid[x][y] ? g.grid[x][y] : null
  return { over: !!window.__over, step: nm(g.step), lvl: g.lvl,
    hero: h ? { px: h.px, py: h.py, ox: h.ox, st: nm(h.state), hold: nm(h.holdStyle), end: !!h.flEndLevelOk, sens: h.sens,
      ladder: !!(h.sq && h.sq.ladder), below: sq(h.px, h.py + 1) ? nm(sq(h.px, h.py + 1).type) : null,
      belowLadder: !!(sq(h.px, h.py + 1) && sq(h.px, h.py + 1).ladder) } : null,
    mons: g.monsters.map(m => ({ px: m.px, py: m.py, ox: m.ox, st: nm(m.state), life: m.life, t: nm(m.mtype) })) } })()`
const stats = {}
const count = (k) => { stats[k] = (stats[k] || 0) + 1 }
let live, data, liveOver, t = 0
const t0 = Date.now()
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let snap = 0, wander = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over || Date.now() - t0 > MAXMS) break
    if (shots && t % 25 === 0 && snap < 80) await b.screenshot(shots + '/j' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    const h = s.hero
    if (s.step !== 'Play' || !h) { await want({}); await sleep(50); continue }
    const alive = s.mons.filter(m => m.life > 0 && m.st !== 'Crash')
    const near = (m) => Math.abs(m.px + m.ox - h.px - h.ox) + Math.abs(m.py - h.py) * 2
    alive.sort((a, b) => near(a) - near(b))
    const tg = alive[0]
    if (h.st === 'Grapple') {
      const tech = ['up', 'down', 'left', 'right'][rnd(4)]
      count('grapple_' + tech)
      await want({}); await sleep(30); await tapKey(tech, 60 + rnd(60)); await sleep(80); continue
    }
    if (h.st === 'KneeGrab') {
      const r = rnd(10)
      const k = r < 5 ? 'fire' : r < 8 ? 'down' : 'up'
      count('knee_' + k)
      await want({}); await sleep(30); await tapKey(k); await sleep(120); continue
    }
    if (h.st === 'Hang') {
      const k = rnd(3) === 0 ? 'down' : rnd(2) ? 'up' : (rnd(2) ? 'left' : 'right')
      count('hang_' + k)
      await want({}); await sleep(30); await tapKey(k, 80 + rnd(200)); await sleep(60); continue
    }
    if (h.st === 'Ladder') {
      count('ladder')
      const dir = tg && tg.py > h.py ? 'down' : 'up'
      await want({ [dir]: true, fire: rnd(30) === 0 }); await sleep(60 + rnd(80)); continue
    }
    if (h.st === 'Crouch') {
      // arm lock a body on the ground, else stand up (grabbing it), or jump down a plank
      const r = rnd(4)
      count('crouch_' + r)
      if (r === 0) { await want({ down: true, fire: true }); await sleep(80) } else await want({})
      await sleep(60); continue
    }
    if (h.st === 'Stand' && h.hold) {
      const r = rnd(h.hold === 'LIFT' ? 5 : 4)
      const k = h.hold === 'LIFT' ? ['fire', 'up', 'down', 'left', 'right'][r] : ['up', 'fire', 'down', 'left'][r]
      count('hold' + h.hold + '_' + k)
      await want({}); await sleep(30)
      if (k === 'left' || k === 'right') await tapKey(k, 150 + rnd(300)); else await tapKey(k, 60 + rnd(60))
      await sleep(100); continue
    }
    if (h.st === 'Stand' && h.end) { count('endJump'); await want({}); await sleep(30); await tapKey('fire'); await sleep(200); continue }
    if (h.st === 'Stand' || h.st === 'Fly') {
      const keys = {}
      // a body on the ground at the feet: crouch on it
      const body = s.mons.find(m => m.st === 'Crash' && m.life > 0 && m.py === h.py && Math.abs(m.px + m.ox - h.px - h.ox) < 0.6)
      if (h.st === 'Stand' && body && rnd(2) === 0) { count('crouchOnBody'); await want({ down: true }); await sleep(120); continue }
      if (wander > 0) {
        wander--
        keys[wander % 20 < 10 ? 'left' : 'right'] = true
      } else if (tg) {
        const dx = tg.px + tg.ox - h.px - h.ox
        if (Math.abs(dx) > 0.3) keys[dx < 0 ? 'left' : 'right'] = true
        if (tg.py < h.py && h.st === 'Stand' && rnd(6) === 0) keys[h.ladder ? 'up' : 'fire'] = true
        if (tg.py > h.py && h.st === 'Stand' && rnd(8) === 0) keys.down = true
        if (h.st === 'Fly' && tg.py < h.py) keys.up = rnd(2) === 0
      }
      if (h.st === 'Stand' && rnd(25) === 0) { keys.fire = true; count('jump') }
      if (rnd(60) === 0) wander = 20 + rnd(40)
      await want(keys)
      await sleep(40 + rnd(60))
      continue
    }
    await want({}); await sleep(50)
  }
  await want({})
  if (!(await b.eval('!!window.__over'))) await b.eval('kk.game.initGameOver()')
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, '\n stats', JSON.stringify(stats), 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('judocommando', 'replays') + '/j_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
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
