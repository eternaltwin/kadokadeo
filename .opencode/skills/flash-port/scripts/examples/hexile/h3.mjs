// Hexile: a bot plays a whole game with real mouse events (the pointer moved over the island, hexes hovered, a press
// dragged out of its hex and released elsewhere now and then, clicks on free hexes: mostly next to its own soldiers
// or the enemy's, sometimes anywhere, a mountain now and then with more soldiers than it holds), then its replay is
// played and the end states compared.
// usage: node h3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, HPORT, SEED,
//        TOUCH=1 (taps on an emulated touch screen instead of the mouse)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=hexile&cls=GameHexile&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9950)
const TOUCH = !!process.env.TOUCH
const OX = 8, OY = 8   // the canvas in the page
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
// the pointer glides to (x, y) in a few moves (hovering what it crosses)
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
// neighbours on the grid of the original (Cs.DIR)
const isN = (dx, dy) => Math.abs(dx) <= 1 && Math.abs(dy) <= 1 && dx * dy !== -1 && (dx !== 0 || dy !== 0)
const STATE = `(() => { const g = kk.game; if (!g || !g.socles) return null
  return { over: !!window.__over, step: g.step._hx_index, turn: g.turn, count: g.count,
    hexes: g.socles.map(s => ({ x: s.x, y: s.y, sx: s.root._x, sy: s.root._y - s.height, team: s.team, n: s.n, en: s.enabled, mount: s.type._hx_index === 2 })) } })()`
const stats = { moves: 0, drags: 0, hovers: 0, near: 0, mount: 0 }
let live, data, liveOver, t = 0
try {
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.castle)', 60000)
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 20 === 0 && snap < 60) await b.screenshot(shots + '/h' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    const free = s.hexes.filter((h) => h.en)
    if (s.step !== 0 || s.turn !== 0 || !free.length) {
      // not our turn: the pointer wanders now and then
      if (!TOUCH && rnd(6) === 0) await glide(20 + rnd(560), 20 + rnd(560))
      await sleep(40)
      continue
    }
    // next to soldiers (ours to reinforce, the enemy's to convert) most of the time
    const near = free.filter((h) => s.hexes.some((o) => o.team !== null && isN(o.x - h.x, o.y - h.y)))
    // a mountain holds 4 soldiers: with 5 or 6, the others fall into the sea
    const mounts = free.filter((h) => h.mount)
    const pool = s.count >= 5 && mounts.length && rnd(2) ? mounts : near.length && rnd(4) ? near : free
    if (pool === near) stats.near++
    if (pool === mounts) stats.mount++
    const h = pool[rnd(pool.length)]
    // the top of the hex, a little off its centre
    const x = h.sx * 2 + rnd(13) - 6, y = h.sy * 2 + rnd(11) - 5
    if (TOUCH) {
      await tap(x, y)
    } else {
      // hover another free hex first now and then
      if (rnd(3) === 0) { const o = free[rnd(free.length)]; await glide(o.sx * 2, o.sy * 2); stats.hovers++; await sleep(60 + rnd(200)) }
      await glide(x, y)
      await sleep(20 + rnd(80))
      if (rnd(5) === 0) {
        // pressed, dragged out of the hex and released elsewhere: no move
        await mouse('mousePressed', OX + x, OY + y, true)
        await sleep(40 + rnd(60))
        await glide(x + 50 + rnd(40), y + 40 + rnd(30), true)
        await mouse('mouseReleased', OX + px, OY + py, false)
        stats.drags++
        await sleep(100)
        continue
      }
      await mouse('mousePressed', OX + x, OY + y, true)
      await sleep(30 + rnd(120))
      await mouse('mouseReleased', OX + x, OY + y, false)
    }
    stats.moves++
    await sleep(150)
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('hexile', 'replays') + '/h_replay_' + process.argv[2] + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.castle)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
