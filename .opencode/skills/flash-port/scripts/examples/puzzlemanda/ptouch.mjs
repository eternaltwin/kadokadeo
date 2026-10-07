// Puzzle-Manda on a touch screen (a finger is the mouse, the touch mode of Buttons): a tap starts the snake, a finger
// dragged along the path moves it (Cell.tryNeighbour) and its release cancels nothing, a tap on the next fruit moves it
// there, a tap away from the snake cancels it; then the replay of that game on a desktop browser must give the same end
// state.
// usage: node ptouch.mjs     env: PORT (default 9992), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const out = gameDir('puzzlemanda', 'check', 'touch')
const URL0 = HOST + '/game.html?game=puzzlemanda&cls=GamePuzzleManda&seed=123&test=pm&time=500'
const PORT = +(process.env.PORT || 9992)
let b = await launch(PORT)
let data, liveOver
const touch = (type, pts) => b.send('Input.dispatchTouchEvent', { type, touchPoints: pts })
const P = (x, y) => ({ x: 8 + x * 2, y: 8 + y * 2, id: 1, radiusX: 4, radiusY: 4, force: 1 })
const ST = `(() => { const G = GamePuzzleManda; const H = G.grid.length, W = G.grid[0].length;
  return JSON.stringify({ locked: G.locked(), eaten: G.suite.tmpList.length, level: kk.game.debugState().level,
    path: G.suite.list.map(c => ({ x: c.x * 30 + (300 - W * 30) / 2 + 15, y: c.y * 30 + 60 + (240 - H * 30) / 2 + 15 })) }) })()`
const st = async () => JSON.parse(await b.eval(ST))
async function unlocked() { for (let i = 0; i < 300; i++) { const s = await st(); if (!s.locked) return s; await b.sleep(30) } }
async function tap(p) { await touch('touchStart', [P(p.x, p.y)]); await b.sleep(70); await touch('touchEnd', []); await b.sleep(200) }
const shot = (n) => b.screenshot(`${out}/${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
const check = (name, ok, s) => console.log(ok ? 'OK  ' : 'FAIL', name, JSON.stringify({ eaten: s.eaten, level: s.level }))
try {
  await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  let s = await unlocked()
  const p = s.path
  // a tap on the first fruit: the snake starts
  await tap(p[0])
  s = await unlocked()
  check('tap starts', s.eaten == 1, s)
  await shot('t1start')
  // a finger dragged from the head to the next two fruits: the snake follows, the release cancels nothing
  await touch('touchStart', [P(p[0].x, p[0].y)])
  for (let k = 1; k <= 2; k++) {
    for (let i = 1; i <= 6; i++) { await touch('touchMove', [P(p[k - 1].x + (p[k].x - p[k - 1].x) * i / 6, p[k - 1].y + (p[k].y - p[k - 1].y) * i / 6)]); await b.sleep(25) }
    await b.sleep(300)
  }
  await shot('t2drag')
  await touch('touchEnd', [])
  await b.sleep(300)
  s = await unlocked()
  check('drag follows, release keeps', s.eaten == 3, s)
  // a tap on the next fruit (the 4th; a sequence of 4 ends the level with it)
  await tap(p[3])
  s = await unlocked()
  check('tap on the next fruit', s.eaten == 4 || (p.length == 4 && s.level == 2), s)
  await shot('t3tap')
  // a tap away from the snake: cancel (a new level: start one first)
  if (s.eaten == 0) { await tap(s.path[0]); s = await unlocked() }
  const before = s.eaten
  await tap({ x: 30, y: 150 })
  s = await unlocked()
  check('tap away cancels (' + before + ' eaten)', before > 0 && s.eaten == 0, s)
  await shot('t4cancel')
  // the whole sequence by taps, then the time runs out
  const lv = s.level
  for (const q of s.path) { await tap(q); await unlocked() }
  s = await unlocked()
  check('level by taps', s.level == lv + 1, s)
  await b.waitFor('!!window.__over', 300000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('desktop replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  await b.close()
}
