// Magmax on a touch screen: the floating joystick (left side) moves the hero in 8 directions, the button (bottom
// right) fires, both at once strafe; then the replay of that game on a desktop browser must give the same end state.
// The game ends by its own code at frame 900 (test mode mx: hero invulnerable until then).
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('magmax', 'check', 'touch')
const URL0 = HOST + '/game.html?game=magmax&cls=GameMagmax&seed=123&test=mx&inv=1&frames=900'
const PORT = +(process.env.PORT || 9545)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y, id) => ({ x: x + 8, y: y + 8, id, radiusX: 4, radiusY: 4, force: 1 })
const HERO = 'JSON.stringify([kk.game.hero.x, kk.game.hero.y, kk.game.tirs.filter(t => !t.fromMonster).length, kk.game.hero.tang])'
const FIRE = [532, 552]
const act = async (name, dx, dy, fire, ms, check) => {
  const s0 = JSON.parse(await b.eval(HERO))
  // the fire button first (a frame moving without fire turns the hero)
  const pts = []
  if (fire) { pts.push(P(FIRE[0], FIRE[1], 2)); await touch('touchStart', pts); await b.sleep(60) }
  if (dx || dy) { pts.push(P(150, 420, 1)); await touch('touchStart', pts); await b.sleep(60); pts[pts.length - 1] = P(150 + dx, 420 + dy, 1); await touch('touchMove', pts) }
  await b.sleep(ms)
  const s1 = JSON.parse(await b.eval(HERO))
  await b.screenshot(out + '/t_' + name + '.png', { x: 8, y: 8, width: 600, height: 640 })
  await touch('touchEnd', [])
  console.log(name.padEnd(10), 'hero', s0.slice(0, 2).map(Math.round), '->', s1.slice(0, 2).map(Math.round), 'shots', s1[2], check(s1[0] - s0[0], s1[1] - s0[1], s1[2], s1[3]) ? 'OK' : 'FAIL')
  await b.sleep(200)
}
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  console.log('overlay', await b.eval('!!kk.touchOverlay'))
  await act('up', 0, -70, false, 300, (dx, dy) => dy < -15 && Math.abs(dx) < 1)
  await act('down', 0, 70, false, 300, (dx, dy) => dy > 15)
  await act('right', 70, 0, false, 300, (dx, dy) => dx > 15 && Math.abs(dy) < 1)
  await act('left', -70, 0, false, 300, (dx, dy) => dx < -15)
  await act('down-left', -60, 60, false, 300, (dx, dy) => dx < -10 && dy > 10)
  await act('fire', 0, 0, true, 500, (dx, dy, n) => n > 0)
  // strafe: moving up while firing keeps the direction of the last move (down-left)
  await act('strafe', 0, -70, true, 500, (dx, dy, n, tang) => dy < -15 && n > 0 && Math.abs(tang - 3 * Math.PI / 4) < 1e-9)
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, 'replay chars', data.length)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
// replay on a desktop browser (no touch)
b = await launch(PORT)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
