// Judo Commando on a touch screen: floating joystick (left half: run, up, crouch) and the jump button (Space); then
// the replay of that game on a desktop browser must give the same end state.
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('judocommando', 'check', 'touch')
const URL0 = HOST + '/game.html?game=judocommando&cls=GameJudoCommando&seed=123&test=jc&frames=1500&inv=1&chrono=5000'
const PORT = +(process.env.PORT || 9898)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const H = (f) => b.eval('kk.game.hero ? (' + f + ') : null')
const ST = 'kk.game.hero.state ? kk.game.hero.state._hx_name : null'
const X = 'kk.game.hero.px + kk.game.hero.ox'
const joy = async (dx, dy, ms) => {
  await touch('touchStart', [P(130, 450, 1)])
  await b.sleep(80)
  await touch('touchMove', [P(130 + dx, 450 + dy, 1)])
  await b.sleep(ms)
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && window.__state && window.__state.step == "Play")', 60000)
  await b.sleep(1500)
  console.log('hero', await H(ST), await H(X))
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  // (a soldier walks into the hero at the start: grappled, the push is a throw, ippon seoi or osoto gari)
  const g0 = await H(ST)
  const x0 = await H(X)
  await joy(60, 0, 500)
  const x1 = await H(X)
  const thrown = g0 === 'Grapple' && (await b.eval('kk.game.playInfo._t[0] + kk.game.playInfo._t[5]')) > 0
  console.log('joystick right: hero x', x0.toFixed(2), '->', x1.toFixed(2), x1 > x0 + 0.5 ? 'OK' : thrown ? 'OK (a throw: the hero was grappling)' : 'FAIL')
  await b.screenshot(out + '/t_joy.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  await b.sleep(200)
  await joy(-60, 0, 400)
  const x2 = await H(X)
  console.log('joystick left: hero x', x1.toFixed(2), '->', x2.toFixed(2), x2 < x1 - 0.5 ? 'OK' : 'FAIL')
  await touch('touchEnd', [])
  await b.sleep(300)
  await joy(0, 70, 300)
  const s1 = await H(ST)
  console.log('joystick down: hero', s1, s1 === 'Crouch' ? 'OK' : 'FAIL')
  await touch('touchEnd', [])
  await b.sleep(300)
  await joy(0, -70, 120)
  const up = await H('kk.game.hero.up || kk.game.hero.lockUp')
  console.log('joystick up: up key', up, up ? 'OK' : 'FAIL')
  await touch('touchEnd', [])
  await b.sleep(300)
  // the jump button
  await touch('touchStart', [P(600 - 18 - 46, 640 - 30 - 46, 2)])
  await b.sleep(150)
  const s2 = await H(ST)
  console.log('jump button: hero', s2, s2 === 'Fly' ? 'OK' : 'FAIL')
  await b.screenshot(out + '/t_jump.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver.slice(0, 200), 'replay chars', data.length)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
b = await launch(PORT)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
