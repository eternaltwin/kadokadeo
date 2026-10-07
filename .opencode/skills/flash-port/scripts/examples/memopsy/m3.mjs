// Memopsy: a bot plays a whole game with real mouse events: it reveals and matches pairs (reading the grid of the
// debug build) until it has passed the last layout of Const.LEVELS (level 7: the clamp is covered), missing on
// purpose now and then (lives lost, cards flipped back), sometimes clicking during a flip or on a face-up card (the
// lock and visibility guards), then drains its lives on known mismatches until the game over. Then the replay of the
// game is played and the end states compared.
// usage: node m3.mjs <bot seed> [replay speed]     env: EXTRA (url params: '&test=...'), PORT, HPORT, SEED (game
//        seed, debug builds play 123), SHOTS (dir: a screenshot every 20 pairs), MISS (1 in N pairs missed, 5),
//        LEVELS (levels to pass before draining, 7)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=memopsy&cls=GameMemopsy&seed=' + (process.env.SEED || '123') + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 10560)
const SHOTS = process.env.SHOTS
const MISS = +(process.env.MISS || 5)
const PASS = +(process.env.LEVELS || 7)
const SIZES = [[4, 2], [4, 3], [4, 4], [5, 4], [5, 4], [5, 4], [6, 4]]
let b = await launch(PORT)
// (Flash pixels -> page pixels: the canvas at (8, 8), x2)
const mouse = (type, x, y, buttons = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + 2 * x, y: 8 + 2 * y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1 })
const STATE = '(() => { const g = kk.game; if (!g) return null; const s = g.debugState(); s.over = !!window.__over; return s })()'

function cells(s) {
  const [w, h] = SIZES[Math.min(s.nlevel, SIZES.length - 1)]
  const px = (300 - w * 50 + 8) / 2, py = (290 - h * 70 + 6) / 2 + 10
  const g = s.grid.split(',')
  const out = []
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const c = g[y * w + x]
      out.push({ x, y, id: parseInt(c), st: c[c.length - 1], cx: px + x * 50 + 21, cy: py + y * 70 + 32 })
    }
  return out
}

async function click(c) {
  const x = c.cx + rnd(25) - 12, y = c.cy + rnd(37) - 18
  await mouse('mouseMoved', x, y)
  await b.sleep(15 + rnd(30))
  await mouse('mousePressed', x, y, 1)
  await b.sleep(20 + rnd(60))
  await mouse('mouseReleased', x, y)
}

const stats = { pair: 0, miss: 0, drain: 0, noise: 0 }
let data, liveOver, n = 0, shot = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  for (; ; n++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (n > 4000) { console.log('STUCK', JSON.stringify(s)); break }
    if (SHOTS && n % 20 === 0 && shot < 40) await b.screenshot(SHOTS + '/m' + String(shot++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    // noise: a click somewhere it does nothing (a flipping card, a face-up card, the decor)
    if (rnd(12) === 0) {
      stats.noise++
      const cs = cells(s)
      const t = rnd(3) === 0 ? { cx: 10 + rnd(280), cy: rnd(2) === 0 ? 30 + rnd(40) : 300 + rnd(60) } : cs[rnd(cs.length)]
      await click(t)
      await b.sleep(40)
      continue
    }
    // wait while cards are flipping (sometimes click the second card during the first card's flip: lock == 1)
    if (s.anims > 0 || s.lock > 0) { await b.sleep(50 + rnd(80)); continue }
    const down = cells(s).filter((c) => c.st === '-')
    if (down.length === 0) { await b.sleep(60); continue }
    const byId = {}
    for (const c of down) (byId[c.id] = byId[c.id] || []).push(c)
    const pairs = Object.values(byId).filter((l) => l.length >= 2)
    const drain = s.nlevel >= PASS
    const wrong = drain || rnd(MISS) === 0
    let a = null, c2 = null
    if (!wrong && pairs.length) {
      const p = pairs[rnd(pairs.length)]
      a = p[0]; c2 = p[1]
    } else {
      // two cards of different ids (a life lost); none: a pair after all
      const ids = Object.keys(byId)
      if (ids.length >= 2) {
        const i = rnd(ids.length); let j = rnd(ids.length - 1); if (j >= i) j++
        a = byId[ids[i]][0]; c2 = byId[ids[j]][0]
        stats[drain ? 'drain' : 'miss']++
      } else if (pairs.length) { a = pairs[0][0]; c2 = pairs[0][1] } else {
        // one lone card face down (its twin is shown, current != null): tap it, the pair resolves
        await click(down[0])
        await b.sleep(120)
        continue
      }
    }
    if (!wrong) stats.pair++
    await click(a)
    await b.sleep(60 + rnd(200))
    await click(c2)
    await b.sleep(80 + rnd(120))
  }
  await b.waitFor('!!window.__over', 60000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval('window.__logs.find(l => l.includes("Replay data:"))')).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', n, 'replay chars', data.length)
  writeFileSync(gameDir('memopsy', 'replays') + '/m_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
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
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
