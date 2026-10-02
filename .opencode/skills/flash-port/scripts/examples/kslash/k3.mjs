// K-Slash: a bot plays a whole game with real key presses (runs, jumps and double jumps held or not, drops through
// platforms, shurikens / slashes, aliases ZQSD-WASD / Enter), then its replay is played and the end states compared.
// usage: node k3.mjs <rng seed> [replay speed] [shots dir]     env: EXTRA (url params), PORT, SEED (game seed), MAXT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=kslash&cls=GameKSlash&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9510)
const MAXT = +(process.env.MAXT || 3000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'], space: [32, ' '], ctrl: [17, 'Control'] }
const ALT = { left: [81, 'KeyA'], right: [68, 'KeyD'], up: [87, 'KeyW'], down: [83, 'KeyS'], space: [13, 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = new Set()
const press = async (name, alt) => { const kk = alt && ALT[name] ? ALT[name] : K[name]; await send('keyDown', kk); held.add(kk) }
const release = async (name) => { for (const kk of [K[name], ALT[name]]) if (kk && held.has(kk)) { await send('keyUp', kk); held.delete(kk) } }
const tap = async (name, ms = 60, alt = false) => { await press(name, alt); await b.sleep(ms); await release(name) }
const STATE = `(() => { const g = kk.game; if (!g || !g.hero) return null; const h = g.hero
  let near = 99, side = 0; for (const m of g.mList) { const d = Math.max(Math.abs(m.x - h.x), Math.abs(m.y - h.y)); if (d < near) { near = d; side = m.x < h.x ? -1 : 1 } }
  return { step: h.step, x: h.x, y: h.y, gr: !!h.flGround, near, side, star: h.star, over: !!window.__over, mons: g.mList.length } })()`
const stats = { jumps: 0, djumps: 0, drops: 0, shots: 0, turns: 0 }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  let snap = 0, dir = 'right'
  await press(dir, rnd(3) === 0)
  for (; t < MAXT; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 50 === 0 && snap < 16) await b.screenshot(shots + '/k' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    // direction: towards the middle, sometimes the other way; stop now and then
    if (rnd(12) === 0 || (dir === 'right' && s.x > 21) || (dir === 'left' && s.x < 3)) {
      await release(dir); dir = dir === 'right' ? 'left' : 'right'; stats.turns++
      if (rnd(5)) await press(dir, rnd(3) === 0)
    }
    if (s.gr) {
      if (rnd(6) === 0) { await press('up', rnd(4) === 0); await b.sleep(40 + rnd(300)); await release('up'); stats.jumps++
        if (rnd(2) === 0) { await b.sleep(80 + rnd(200)); await tap('up', 60 + rnd(150)); stats.djumps++ } }
      else if (rnd(25) === 0 && s.y < 21) { await tap('down', 60, rnd(2) === 0); stats.drops++ }
    }
    // shurikens / slash when a monster is near, or at random
    if (s.near < 6 || rnd(8) === 0) { await tap(rnd(4) === 0 ? 'ctrl' : 'space', 40, rnd(3) === 0); stats.shots++ }
    await b.sleep(20 + rnd(50))
  }
  for (const kk of [...held]) await send('keyUp', kk)
  if (!(await b.eval('!!window.__over'))) await b.eval('kk.game.gameOver()')
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  live = JSON.parse(liveOver).score
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  writeFileSync(gameDir('kslash', 'replays') + '/ks_replay_' + process.argv[2] + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 600000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
