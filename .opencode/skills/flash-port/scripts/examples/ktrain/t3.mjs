// K-Train bot + replay: plays a real game with key events (arrows, sometimes the WASD / Enter aliases): keeps the
// train fast, brakes into each station to stop past its line (coal), sometimes gets out for a gem near the train and
// walks back in, brakes or slows down now and then, until the game over (the train behind, no coal, or the train lost);
// then plays the replay and compares the end state (MATCH expected).
// usage: node t3.mjs [bot seed] [replay speed] [shots dir]
// env: PORT (DevTools, default 9884; the replay uses PORT + 50), HPORT, EXTRA (url params, test modes), MAXT (bot ticks)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=ktrain&cls=GameKTrain&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9884)
const MAXT = +(process.env.MAXT || 20000)
const K = { left: [37, 'ArrowLeft'], up: [38, 'ArrowUp'], right: [39, 'ArrowRight'], down: [40, 'ArrowDown'], space: [32, 'Space'] }
const ALT = { left: [65, 'KeyA'], up: [87, 'KeyW'], right: [68, 'KeyD'], down: [83, 'KeyS'], space: [13, 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const held = {}
const set = async (name, on) => {
  if (on && !held[name]) { const kk = rnd(6) === 0 ? ALT[name] : K[name]; await send('keyDown', kk); held[name] = kk }
  else if (!on && held[name]) { await send('keyUp', held[name]); held[name] = null }
}
const tap = async (name) => { await set(name, true); await b.sleep(40 + rnd(60)); await set(name, false) }
const release = async () => { for (const k of Object.keys(K)) await set(k, false) }
const STATE = 'JSON.stringify(kk.game.debugBot())'
// distance (scroll) to stop from speed v with the brake held: per Flash frame the scroll is 0.8 v, then
// Game.updateSpeed (v - 0.08, 0 under 0.1) and Loco.update (v * 0.98)
const stopDist = (v) => { let d = 0; while (v > 0) { d += 0.8 * v; v = v <= 0.1 ? 0 : (v - 0.08) * 0.98 } return d }
const stats = { stations: 0, gemTrips: 0, gems: 0, brakes: 0, downs: 0 }
let live, data, liveOver, t = 0
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  let want = 4, stopped = false, trip = null, nextFun = 200 + rnd(300), lastStation = 1e9
  for (; t < MAXT; t++) {
    const s = JSON.parse(await b.eval(STATE))
    if (s.over) break
    if (shots && t % 50 === 0) await b.screenshot(shots + '/t' + String(t / 50).padStart(4, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (s.station > lastStation + 1000) stopped = false
    lastStation = s.station
    // the coal carried to the train (CoalAnim): the stop at this station is done (Station.update sets nextStation to 0)
    if (s.anim > 0) { if (!stopped) { stopped = true; stats.stations++ } await release(); await b.sleep(40); continue }
    if (s.out) {
      // walking: to the gem, then back into the locomotive
      if (!trip) trip = { t: 0, back: true }
      trip.t++
      let tx = 150, ty = s.locoY - 60
      if (!trip.back) {
        const g = s.gems.find((g) => Math.abs(g[0] - trip.gx) < 2 && Math.abs(g[1] - trip.gy) < 2)
        if (!g || trip.t > 120) trip.back = true
        else { tx = g[0]; ty = g[1] }
      }
      // (stuck on the way back: a detour on the other axis)
      const dx = tx - s.mx, dy = ty - s.my
      const sidestep = trip.back && trip.t > 150 && (trip.t >> 4) % 2 === 1
      await set('left', !sidestep && dx < -2)
      await set('right', !sidestep && dx > 2)
      await set('up', dy < -2 || sidestep)
      await set('down', !sidestep && dy > 2)
      if (Math.abs(dx) <= 2 && Math.abs(dy) <= 2) await tap('up')
      await b.sleep(20 + rnd(20))
      continue
    }
    if (trip) { stats.gemTrips++; trip = null; await release() }
    // station ahead: no more acceleration, then brake so that the train stops past its line (nextStation between -308
    // and -147, aimed at -230)
    const near = !stopped && s.station < 1500 && s.station > -300
    if (near) {
      if (process.env.LOG && t % 10 === 0) console.log('st', t, s.frame, s.station.toFixed(1), s.speed.toFixed(3), s.step, s.coal.toFixed(0))
      const brake = s.speed > 0 && s.station - stopDist(s.speed) < -230
      await set('space', brake)
      if (s.speed <= 0 && !brake) await tap('up')
      if (!brake && s.step > 2 && s.station < 600) await tap('down')
      await b.sleep(15)
      continue
    }
    await set('space', false)
    // stopped at a station (coal given): sometimes a gem close enough to fetch
    if (s.speed <= 0 && stopped && !s.lock && rnd(2) === 0) {
      const near = s.gems.filter((g) => Math.hypot(g[0] - 150, g[1] - (s.locoY - 60)) < 140)
      if (near.length) {
        const g = near[0]
        trip = { t: 0, back: false, gx: g[0], gy: g[1] }
        await tap(g[0] < 150 ? 'left' : 'right')
        await b.sleep(40)
        continue
      }
    }
    // now and then: the brake, a step down, a gem beside the track fetched with the train stopped
    if (--nextFun <= 0) {
      nextFun = 200 + rnd(400)
      const r = rnd(4) === 0 ? rnd(2) : 2
      if (r === 0) { stats.brakes++; await set('space', true); await b.sleep(300 + rnd(500)); await set('space', false) }
      else if (r === 1) { stats.downs++; await tap('down'); want = 2 + rnd(3) }
      else {
        // a gem coming down beside the train: brake so that it stops near the locomotive, then fetch it
        const ahead = s.gems.filter((g) => g[1] > -260 - stopDist(s.speed) && g[1] < 120 - stopDist(s.speed))
        if (!ahead.length) { nextFun = 20; continue }
        await set('space', true)
        for (let i = 0; i < 300; i++) { const v = JSON.parse(await b.eval(STATE)); if (v.speed <= 0 || v.over) break; await b.sleep(25) }
        await set('space', false)
        const v = JSON.parse(await b.eval(STATE))
        const near = v.gems.filter((g) => g[1] > 10 && g[1] < 290).sort((a, c) => Math.hypot(a[0] - 150, a[1] - v.locoY) - Math.hypot(c[0] - 150, c[1] - v.locoY))
        if (near.length) { trip = { t: 0, back: false, gx: near[0][0], gy: near[0][1] }; await set(near[0][0] < 150 ? 'left' : 'right', true); await b.sleep(150); await release() }
        else await tap('up')
      }
      continue
    }
    // the speed asked: step `want` (taps of up / down)
    if (s.step < want && s.coal > 0) await tap('up')
    else if (s.step > want) await tap('down')
    if (rnd(500) === 0) want = 3 + rnd(2)
    if (process.env.LOG && t % 50 === 0) console.log(t, JSON.stringify(s))
    await b.sleep(25 + rnd(25))
  }
  await release()
  const t0 = Date.now()
  // a game that does not end (MAXT): the train left without its driver
  while (!(await b.eval('!!window.__over')) && Date.now() - t0 < 120000) { await set('up', true); await b.sleep(150); await set('up', false); await tap('left'); await b.sleep(300) }
  await release()
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'ticks', t, 'replay chars', data.length)
  writeFileSync(gameDir('ktrain', 'replays') + '/t3_' + process.argv[2] + '.txt', data + '\n' + liveOver)
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
