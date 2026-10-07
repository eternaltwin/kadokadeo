// Julianus on a touch screen: a finger moves the target of the hero (a touch outside the button is not a click: no
// blow), the blow button (bottom right) blows without moving the target; a game played that way, then its replay
// watched on a desktop browser (no touch).
// usage: node jtouch.mjs      env: PORT (devtools, +50 for the replay), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const PORT = +(process.env.PORT || 9873)
const URL0 = HOST + '/game.html?game=julianus&cls=GameJulianus&seed=123&test=ju&frames=900'
const OX = 8, OY = 8
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const P = (x, y, id) => ({ x: OX + x, y: OY + y, id })
let b = await launch(PORT)
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const st = () => b.eval('JSON.stringify({f: kk.game.frameCount, tx: kk.game.hero.tx, ty: kk.game.hero.ty, act: kk.game.hero.action, blow: !!kk.game.hero.blow, cy: kk.game.mc._y})').then(JSON.parse)
const BX = 600 - 20 - 45, BY = 640 - 20 - 45
let data, liveOver
const checks = []
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 2 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero && kk.game.frameCount > 5)', 60000)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  // 1. a finger steers
  await touch('touchStart', [P(200, 260, 1)])
  await sleep(150)
  await touch('touchMove', [P(240, 300, 1)])
  await sleep(150)
  let s = await st()
  checks.push(['finger moves the target', Math.abs(s.tx - 120) < 1 && Math.abs(s.ty - (150 - s.cy)) < 1 && !s.blow, JSON.stringify(s)])
  await touch('touchEnd', [])
  await sleep(100)
  s = await st()
  checks.push(['lifting it does not blow', !s.blow && !s.act, JSON.stringify(s)])
  // 2. the button blows, the target stays
  const before = s
  await touch('touchStart', [P(BX, BY, 2)])
  await sleep(300)
  s = await st()
  checks.push(['button blows', s.blow && Math.abs(s.tx - before.tx) < 0.01 && Math.abs(s.ty - before.ty) < 0.01, JSON.stringify(s)])
  await touch('touchEnd', [])
  await sleep(150)
  s = await st()
  checks.push(['released: no blow', !s.blow, JSON.stringify(s)])
  // 3. a game: steer behind the bubble, blow now and then, until frame 900
  for (let i = 0; ; i++) {
    const g = JSON.parse(await b.eval('JSON.stringify({over: !!window.__over, bl: kk.game.bulles.map(b => [b.px, b.py, b.size]), cy: kk.game.mc._y})'))
    if (g.over) break
    if (g.bl.length) {
      const bb = g.bl[0]
      const x = (bb[0] - bb[2] / 2 - 22) * 2, y = (bb[1] + 10 + g.cy) * 2
      await touch('touchStart', [P(Math.max(2, Math.min(590, x)), Math.max(2, Math.min(590, y)), 1)])
      await sleep(60)
      await touch('touchEnd', [])
      if (i % 3 === 0) {
        await touch('touchStart', [P(BX, BY, 2)])
        await sleep(200)
        await touch('touchEnd', [])
      }
    }
    await sleep(80)
  }
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
for (const c of checks) console.log(c[1] ? 'OK  ' : 'FAIL', c[0], c[1] ? '' : c[2])
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  await b.close()
}
