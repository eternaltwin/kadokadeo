// Pacifik: a bot plays a game with real mouse events (moves, clicks to change the laser's colour, long presses to put
// the black laser back), then its replay is played and the end states compared (MATCH expected).
// The bot goes for the ball nearest to a canon, waits ahead of it with the laser of its colour, keeps the coloured laser
// away from the ship. Saves the replay in $KKP_WORK/pacifik/replays/p_replay_<seed>.txt.
// usage: HPORT=8811 PORT=9932 node p3.mjs <bot seed> [extra url, e.g. '&test=pk&frames=3000&learn=2&ship=300']
//   env SLOPPY=<0..1>: probability of a wrong move (default 0.15), TOUCH=1: the finger is the mouse (touch events)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'fs'

const SEED = +(process.argv[2] || 1), EXTRA = process.argv[3] || ''
const PORT = +(process.env.PORT || 9932), SLOPPY = +(process.env.SLOPPY ?? 0.15), TOUCH = !!process.env.TOUCH
let rs = SEED * 7919 + 13
const rnd = () => ((rs = (rs * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff)
const URL0 = HOST + '/game.html?game=pacifik&cls=GamePacifik&seed=123' + EXTRA
const OX = 8, OY = 8
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

const STATE = `(() => { const g = kk.game; if (!g) return null; const L = g.laser
  const bs = g.balls.filter((b) => b.mc != null && !b.mc.removed && !isNaN(b.mc.x)).map((b) => [b.mc.x, b.mc.y, b.type, b.bonus ? 1 : 0, b.moveLeft ? 1 : 0, b.xf])
  return JSON.stringify({ bs, cur: L.curtype, lx: L.mc.x, ship: g.shipIn ? 1 : 0, sy: g.ship ? g.ship.y : 0, over: !!window.__over }) })()`

let b = await launch(PORT)
let data, liveOver
const stats = { clicks: 0, longs: 0, moves: 0 }
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser)', 60000)
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 2 })
  let mx = 150, holdUntil = 0, lastClick = 0, mistakeUntil = 0, mistakeX = 150
  const down = async (x, y) => TOUCH
    ? b.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] })
    : b.mouse('mousePressed', x, y)
  const up = async (x, y) => TOUCH
    ? b.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] })
    : b.mouse('mouseReleased', x, y)
  const moveTo = async (x, y) => TOUCH
    ? null
    : b.move(x, y)
  let holding = false
  for (let t = 0; ; t++) {
    const s = JSON.parse(await b.eval(STATE))
    if (!s || s.over) break
    const now = Date.now()
    if (holding) {
      if (now >= holdUntil) { await up(OX + mx * 2, OY + 300); holding = false }
      await sleep(25)
      continue
    }
    // the most urgent ball: the one nearest to the side it goes to
    let best = null, bt = 1e9
    for (const [x, y, type, bonus, left, xf] of s.bs) {
      const tt = left ? x / Math.max(0.05, -xf) : (300 - x) / Math.max(0.05, xf)
      if (tt < bt) { bt = tt; best = { x, y, type, bonus, left } }
    }
    let want = s.cur, tx = mx
    if (best) {
      want = best.bonus ? 0 : best.type + 1
      tx = best.x + (best.left ? -12 : 12)
    }
    if (now < mistakeUntil) tx = mistakeX
    else if (rnd() < SLOPPY * 0.02) { mistakeUntil = now + 300 + rnd() * 900; mistakeX = 40 + rnd() * 220 }
    // the coloured laser never on the ship's path (x 148..152): it waits beside it, and crosses it with a jump of
    // 90 pixels (more than 37 per Flash frame: the laser turns black first)
    let jump = false
    if (s.ship && (want > 0 || s.cur > 0)) {
      if (tx > 138 && tx < 162) tx = mx < 150 ? 136 : 164
      if ((mx < 150) !== (tx < 150)) {
        if (Math.abs(mx - 150) > 16) tx = mx < 150 ? 136 : 164
        else jump = true
      }
    }
    tx = Math.max(32, Math.min(268, tx))
    // at most ~25 Flash pixels per poll (the laser goes black beyond 37 per Flash frame)
    const dx = jump ? (mx < 150 ? 90 : -90) : Math.max(-25, Math.min(25, tx - mx))
    if (Math.abs(dx) > 0.5) { mx += dx; stats.moves++ }
    if (!TOUCH) await moveTo(OX + mx * 2, OY + 300)
    if (want !== s.cur && now - lastClick > 90) {
      lastClick = now
      if (want === 0 && s.cur < 3 && rnd() < 0.7) {
        // the long press: black laser (pressTimer > 20 Flash frames)
        await down(OX + mx * 2, OY + 300); holding = true; holdUntil = now + 650 + rnd() * 200; stats.longs++
      } else {
        await down(OX + mx * 2, OY + 300); await sleep(30 + rnd() * 40); await up(OX + mx * 2, OY + 300); stats.clicks++
      }
    } else if (TOUCH && Math.abs(dx) > 0.5 && rnd() < 0.05) {
      // (a finger moves the laser only while touching: a short tap where the laser is, sometimes)
    }
    await sleep(25)
  }
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'replay chars', data.length)
  writeFileSync(gameDir('pacifik', 'replays') + '/p_replay_' + SEED + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
