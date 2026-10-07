// K-Train: the driver catches a piouz (24000 points). Test mode kt with piouz=1 (every gem a piouz, on the track):
// the train runs at its starting speed, stops when a piouz is ahead (it can appear just in front of it), the driver walks to it, then back into
// the locomotive; the game ends at Flash frame 5000; then its replay must give the same end state.
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const URL0 = HOST + '/game.html?game=ktrain&cls=GameKTrain&seed=123&test=kt&piouz=1&frames=5000'
const PORT = +(process.env.PORT || 9908)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'], space: [32, 'Space'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = {}
const set = async (n, on) => { if (on && !held[n]) { await send('keyDown', K[n]); held[n] = 1 } else if (!on && held[n]) { await send('keyUp', K[n]); held[n] = 0 } }
const tap = async (n) => { await set(n, true); await b.sleep(80); await set(n, false); await b.sleep(80) }
const st = async () => JSON.parse(await b.eval('JSON.stringify(Object.assign(kk.game.debugBot(), {stats: kk.game.stats}))'))
const stopDist = (v) => { let d = 0; while (v > 0) { d += 0.8 * v; v = v <= 0.1 ? 0 : (v - 0.08) * 0.98 } return d }
let data, liveOver
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  // (at the starting speed: a piouz can appear right in front of the train, at y = Scroller.cycles)
  let phase = 'wait', target = null
  for (let t = 0; t < 4000; t++) {
    const s = await st()
    if (s.over) break
    const p0 = s.gems.find((g) => g[2] === 1 && g[1] < s.locoY - 150)
    if (phase === 'wait') {
      // a piouz on the track ahead: stop, then come close at the lowest speed
      if (p0) { await set('space', true); phase = 'brake' }
    } else if (phase === 'brake') {
      if (s.speed <= 0) { await set('space', false); phase = p0 && p0[1] > 40 ? 'stop' : 'creep' }
    } else if (phase === 'creep') {
      if (!p0) phase = 'wait'
      else if (p0[1] > 40) { await set('space', true); phase = 'stop' }
      else if (s.speed <= 0) await tap('up')
    } else if (phase === 'stop') {
      if (s.speed <= 0) { await set('space', false); await tap('left'); phase = 'walk' }
    } else if (phase === 'walk') {
      const p = s.gems.find((g) => g[2] === 1 && g[1] > -20 && g[1] < 300)
      if (s.stats.piouz > 0 && process.env.SHOT) { for (let i = 0; i < 3; i++) { await b.screenshot(process.env.SHOT + '/piouz' + i + '.png', { x: 8, y: 8, width: 600, height: 640 }); await b.sleep(90) } delete process.env.SHOT }
      if (s.stats.piouz > 0 || !p) { phase = 'back'; await set('left', false); await set('right', false); await set('up', false); await set('down', false) }
      else {
        // beside the locomotive: up past its front first (touching it with a key down is boarding)
        const beside = s.my > s.locoY - 147 - 16
        await set('left', !beside && p[0] < s.mx - 2); await set('right', !beside && p[0] > s.mx + 2); await set('up', p[1] < s.my - 2); await set('down', !beside && p[1] > s.my + 2)
      }
    } else if (phase === 'back') {
      if (!s.out) { phase = 'done'; for (const k of Object.keys(K)) await set(k, false); await tap('up') }
      else { const tx = 150, ty = s.locoY - 60; await set('left', tx < s.mx - 2); await set('right', tx > s.mx + 2); await set('up', ty < s.my - 2 || (Math.abs(tx - s.mx) <= 2 && Math.abs(ty - s.my) <= 2)); await set('down', ty > s.my + 2) }
    }
    if (process.env.LOG && t % 10 === 0 && phase !== 'wait') console.log(t, phase, s.speed.toFixed(2), s.out, s.mx, s.my, JSON.stringify(s.gems.filter((g) => g[2] === 1)))
    await b.sleep(25)
  }
  for (const k of Object.keys(K)) await set(k, false)
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
b = await launch(PORT)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  await b.close()
}
