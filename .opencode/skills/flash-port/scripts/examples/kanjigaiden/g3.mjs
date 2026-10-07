// Kanji Gaiden bot + replay: plays a real game with key events (arrows and Space, sometimes the aliases Q / D / A and
// Enter): turns towards the most dangerous monkey (the nearest plane first) and throws when the shot's line meets it,
// until the game over (after MAXT ticks it stops throwing, so that a monkey ends the game); then plays the replay and
// compares the end state (MATCH expected).
// A shot thrown at Game.pos = h meets a plane of width w at its x = h (w - 300) + 150 (Game.getPosShot).
// usage: node g3.mjs [bot seed] [replay speed] [shots dir]
// env: PORT (DevTools, default 9862; the replay uses PORT + 50), HPORT, EXTRA (url params, test modes), MAXT (bot ticks)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=kanjigaiden&cls=GameKanjiGaiden&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9862)
const MAXT = +(process.env.MAXT || 2500)
const K = { left: [37, 'ArrowLeft', 'ArrowLeft'], right: [39, 'ArrowRight', 'ArrowRight'], space: [32, ' ', 'Space'] }
const ALT = { left: [81, 'q', 'KeyA'], right: [68, 'd', 'KeyD'], space: [13, 'Enter', 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, k, c]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c })
const held = {}
const set = async (name, on) => {
  if (on && !held[name]) { const kk = rnd(6) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held[name] = kk }
  else if (!on && held[name]) { await send('keyUp', held[name]); held[name] = null }
}
const STATE = `(() => { const g = kk.game
  return { over: !!window.__over, frame: window.__state && window.__state.frame, pos: g.pos, sType: g.hero.sType,
    plans: g.plans.map(p => [p.width, p.cz]),
    m: g.monkeys.map(m => [m.pl, m.x, m.protected, m.vx]) } })()`
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let lazy = 0
  for (; t < MAXT * 3; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 40 === 0) await b.screenshot(shots + '/g' + String(t / 40).padStart(3, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    const playing = t < MAXT
    // the target: the monkey on the nearest plane (then the one in the middle of the view)
    let best = null, bs = 1e9
    for (const [pl, x, prot, vx] of s.m) {
      const w = s.plans[pl][0]
      const hp = (x + vx * 4 - 150) / (w - 300)
      const sc = pl * 10 + Math.abs(hp - s.pos) + (prot ? 3 : 0)
      if (sc < bs) { bs = sc; best = hp }
    }
    if (lazy > 0) lazy--
    else if (rnd(80) === 0) lazy = 10 + rnd(30)
    if (best === null || !playing || lazy > 0) {
      await set('left', false); await set('right', false)
      await set('space', playing && rnd(3) === 0)
    } else {
      const d = best - s.pos
      await set('right', d > 0.02)
      await set('left', d < -0.02)
      await set('space', Math.abs(d) < 0.06 || rnd(8) === 0)
    }
    if (process.env.LOG && t % 50 === 0) console.log(t, s.frame, s.pos.toFixed(3), best, JSON.stringify(s.m))
    await b.sleep(15 + rnd(25))
  }
  for (const k of ['left', 'right', 'space']) await set(k, false)
  await b.waitFor('!!window.__over', 600000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('kanjigaiden', 'replays') + '/g3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
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
