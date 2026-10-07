// Toy Maniak on a touch screen: a finger is the mouse (tap a slot: its toy in hand, tap a toy of a rail: put / swap,
// tap a slot again: the toy back in the box). A short game (test=cov&time=95), whose toys of the slots are put back
// on the rails at the end; then the replay of that game, on a desktop browser, must give the same end state.
// usage: node ttouch.mjs      env: PORT (DevTools, default 9968), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('toymaniak', 'check', 'touch')
const URL0 = HOST + '/game.html?game=toymaniak&cls=GameToyManiak&seed=123&test=cov&time=95'
const PORT = +(process.env.PORT || 9968)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
// (Flash pixels -> page pixels: the canvas at (8, 8), x2)
const P = (x, y) => ({ x: 8 + 2 * x, y: 8 + 2 * y, id: 1, radiusX: 4, radiusY: 4, force: 1 })
const tap = async (x, y, hold = 90) => { await touch('touchStart', [P(x, y)]); await b.sleep(hold); await touch('touchEnd', []); await b.sleep(250) }
const STATE = `(() => { const g = kk.game
  return { over: !!window.__over, time: g.time, cov: JSON.parse(JSON.stringify(g.cov)), cursor: g.cursor ? g.cursor.t : null,
    sels: g.sels.map(s => s.t), rails: g.rails.map(r => ({ speed: r.speed * g.speed, toys: r.toys.map(t => ({ x: t.x, t: t.t, lock: t.lock })) })) } })()`
const SLOT = [[104, 272.6], [150, 272.6], [196, 272.6]]
// a toy of a rail (kind k: -1 empty spot, null any) far enough from both ends, where it will be after the tap
async function tapToy(k) {
  const s = await b.eval(STATE)
  for (let r = 0; r < 3; r++) {
    const lead = s.rails[r].speed * 0.8 * 40 * 0.2
    const t = s.rails[r].toys.find((t) => !t.lock && t.x - lead > 90 && t.x - lead < 260 && (k === null ? true : t.t === k))
    if (t) { await tap(t.x - lead, 70 + 75 * r - 22); return true }
  }
  return false
}
const ok = (c, m) => console.log(m, c ? 'OK' : 'FAIL')
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.rails)', 60000)
  await b.sleep(1500)
  await tap(...SLOT[0])
  let s = await b.eval(STATE)
  ok(s.cursor !== null && s.cov.takeSlot === 1, 'tap a slot: its toy in hand')
  await b.screenshot(out + '/t_hand.png', { x: 8, y: 8, width: 600, height: 640 })
  for (let i = 0; i < 20 && !(await tapToy(null)); i++) await b.sleep(200)
  s = await b.eval(STATE)
  ok(s.cov.put + s.cov.swap === 1, 'tap a toy of a rail: put / swapped (' + JSON.stringify(s.cov) + ')')
  if (s.cursor !== null) { await tap(...SLOT[0]); s = await b.eval(STATE); ok(s.cov.putSlot === 1, 'tap the empty slot: the toy back in the box') }
  // the end: every toy of the slots on an empty spot of a rail
  for (let i = 0; i < 400; i++) {
    s = await b.eval(STATE)
    if (s.over) break
    if (s.cursor !== null) await tapToy(-1)
    else {
      const k = s.sels.findIndex((t) => t !== -1)
      if (k >= 0 && s.time >= 100) await tap(...SLOT[k])
      else await b.sleep(300)
    }
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
// the replay on a desktop browser (no touch emulation)
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.rails)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 600000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  await b.close()
}
