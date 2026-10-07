// Aqua Splash: a bot plays a whole game with real mouse events (the pointer glides over the board, hovering the slimes
// it crosses; it clicks big slimes for chains, sometimes a smaller one, an empty cell next to slimes (the flame bomb),
// presses and drags out now and then (no move), waits for the time bar to run out now and then (a slime shrinks)),
// then its replay is played and the end states compared.
// usage: node a3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params, default &test=as&map=<seed>),
//        PORT, HPORT, TOUCH=1 (taps on an emulated touch screen instead of the mouse)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const EXTRA = process.env.EXTRA !== undefined ? process.env.EXTRA : '&test=as&map=' + (1000 + rs)
const URL0 = HOST + '/game.html?game=aquasplash&cls=GameAquaSplash&seed=123' + EXTRA
const PORT = +(process.env.PORT || 9960)
const TOUCH = !!process.env.TOUCH
const OX = 8, OY = 8   // the canvas in the page
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
let px = 300, py = 300
const glide = async (x, y, down = false) => {
  const n = 2 + rnd(5)
  for (let i = 1; i <= n; i++) {
    await mouse('mouseMoved', OX + px + (x - px) * i / n, OY + py + (y - py) * i / n, down)
    await sleep(15 + rnd(40))
  }
  px = x; py = y
}
const tap = async (x, y) => {
  await touch('touchStart', [{ x: OX + x, y: OY + y }])
  await sleep(30 + rnd(90))
  await touch('touchEnd', [])
}
// canvas pixels of a cell centre (Cs.getPos(p, true), drawn x2)
const cx = (x) => (30 + x * 40 + 20) * 2, cy = (y) => (10 + y * 40 + 20) * 2
const STATE = `(() => { const g = kk.game; if (!g || !g.allSlimes) return null
  return { over: !!window.__over, step: g.step._hx_index, locked: g.lockSlime || g.flGameOver, plays: g.plays,
    level: g.level, s: g.allSlimes.map(s => [s.pos.x, s.pos.y, s.grow, s.bonus ? 1 : 0]) } })()`
const stats = { clicks: 0, big: 0, small: 0, bombs: 0, drags: 0, waits: 0, hovers: 0 }
let data, liveOver, t = 0
try {
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.mcTime)', 60000)
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 4 === 0 && snap < 80) await b.screenshot(shots + '/a' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (s.step !== 0 || s.locked) {
      if (!TOUCH && rnd(4) === 0) await glide(40 + rnd(520), 20 + rnd(520))
      await sleep(60)
      continue
    }
    const live = s.s.filter((c) => c[2] > 0)
    const big = live.filter((c) => c[2] === 4), mid = live.filter((c) => c[2] === 3)
    // an empty cell (not a bonus) with live slimes around it
    const empty = s.s.filter((c) => c[2] <= 0 && !c[3] && live.some((o) => Math.abs(o[0] - c[0]) <= 1 && Math.abs(o[1] - c[1]) <= 1))
    let pool, kind
    const r = rnd(20)
    if (r < 2 && empty.length) { pool = empty; kind = 'bombs' } else if (r < 14 && big.length) { pool = big; kind = 'big' } else if (r < 17 && mid.length) { pool = mid; kind = 'small' } else { pool = live.length ? live : s.s; kind = 'small' }
    if (rnd(25) === 0) {
      // the time bar runs out: forceReduce
      stats.waits++
      await sleep(16000)
      continue
    }
    const c = pool[rnd(pool.length)]
    // near the centre of the cell (inside the hit square: |offset| < 19 Flash pixels)
    const x = cx(c[0]) + rnd(41) - 20, y = cy(c[1]) + rnd(41) - 20
    if (TOUCH) {
      await tap(x, y)
    } else {
      if (rnd(3) === 0) { const o = s.s[rnd(s.s.length)]; await glide(cx(o[0]), cy(o[1])); stats.hovers++; await sleep(60 + rnd(200)) }
      await glide(x, y)
      await sleep(20 + rnd(80))
      if (rnd(8) === 0) {
        // pressed, dragged out and released elsewhere: no move
        await mouse('mousePressed', OX + x, OY + y, true)
        await sleep(40 + rnd(60))
        await glide(x + 90 + rnd(40), y + 80 + rnd(30), true)
        await mouse('mouseReleased', OX + px, OY + py, false)
        stats.drags++
        await sleep(100)
        continue
      }
      await mouse('mousePressed', OX + x, OY + y, true)
      await sleep(30 + rnd(120))
      await mouse('mouseReleased', OX + x, OY + y, false)
    }
    stats[kind]++
    stats.clicks++
    await sleep(120)
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('aquasplash', 'replays') + '/a_replay_' + process.argv[2] + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver + '\n' + URL0)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 20)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.mcTime)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
