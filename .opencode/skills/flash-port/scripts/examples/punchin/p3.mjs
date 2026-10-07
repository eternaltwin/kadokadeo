// Punch-In bot + replay: plays a real game with key events (arrows, Space, sometimes the Q / D / A / Enter aliases):
// dodges when the afro attacks (holds left or right until the punch is over), punches (Space taps) when he waits,
// sometimes moves for nothing or punches at random, until the game over (the chrono, 2 minutes of real time, or the
// stamina); then plays the replay and compares the end state (MATCH expected).
// usage: node p3.mjs [bot seed] [replay speed]
// env: PORT (DevTools, default 9966; the replay uses PORT + 10), HPORT, EXTRA (url params, test modes), LOG=1,
//      CLUMSY=n (1 in n decisions is random: more hits taken, default 5)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=punchin&cls=GamePunchIn&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9966)
const CLUMSY = +(process.env.CLUMSY || 5)
const K = { left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'], space: [32, 'Space', ' '] }
const ALT = { left: [rnd(2) ? 81 : 65, 'KeyA', 'q'], right: [68, 'KeyD', 'd'], space: [13, 'Enter', 'Enter'] }
let b = await launch(PORT)
const send = (type, [code, c, k]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k || c, code: c })
const stats = { decisions: 0, dodge: 0, punch: 0, idle: 0, randomMove: 0, alias: 0 }
const key = (name) => { if (rnd(6) === 0) { stats.alias++; return ALT[name] } return K[name] }

let data, liveOver
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  for (;;) {
    const s = JSON.parse(await b.eval('JSON.stringify(window.__state)'))
    if (s.over || s.step === 'GameOver') break
    stats.decisions++
    const clumsy = rnd(CLUMSY) === 0
    if (process.env.LOG) console.log(s.frame, s.astep, s.amove, s.aframe, s.bstep, s.bmove, s.stamina.toFixed(1), s.score)
    if (s.astep === 'Attack' && !clumsy) {
      // dodge: hold a side until the afro's punch is over
      stats.dodge++
      const k = key(rnd(2) ? 'left' : 'right')
      await send('keyDown', k)
      const t0 = Date.now()
      while (Date.now() - t0 < 1500) {
        await b.sleep(30)
        const n = JSON.parse(await b.eval('JSON.stringify(window.__state)'))
        if (n.astep !== 'Attack' || n.over) break
      }
      await b.sleep(rnd(3) * 40)
      await send('keyUp', k)
    } else if (clumsy && rnd(2) === 0) {
      stats.randomMove++
      const k = key(rnd(2) ? 'left' : 'right')
      await send('keyDown', k)
      await b.sleep(80 + rnd(8) * 60)
      await send('keyUp', k)
    } else if ((s.astep === 'Wait' || s.astep === 'Defense' || clumsy) && s.bmove === 'Center') {
      stats.punch++
      const k = key('space')
      await send('keyDown', k)
      await b.sleep(40 + rnd(4) * 40)
      await send('keyUp', k)
    } else {
      stats.idle++
    }
    await b.sleep(20 + rnd(60))
  }
  await b.waitFor('!!window.__over', 600000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 120000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'replay chars', data.length)
  writeFileSync(gameDir('punchin', 'replays') + '/p3_' + (process.argv[2] || 1) + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 10)
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
