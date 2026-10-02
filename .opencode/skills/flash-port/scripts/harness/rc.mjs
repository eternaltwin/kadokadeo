// Replay compatibility across versions of the shared code.
//   node rc.mjs record <out.jsonl> <port> <game:Class>...   live game with random keys + mouse (game over at frame N),
//       then its replay with the same build: state at 60 % (seek) and end score -> one JSON line per game
//   node rc.mjs check <in.jsonl> <port>                      the recorded replays played by the current build:
//       same state at 60 % and same end score
import fs from 'fs'
import { launch } from './cdp.mjs'
const [mode, file] = [process.argv[2], process.argv[3]]
const PORT = +(process.argv[4] || 9341)
const FRAMES = 900
const KEYS = [[37, 'ArrowLeft'], [38, 'ArrowUp'], [39, 'ArrowRight'], [40, 'ArrowDown'], [32, 'Space'], [13, 'Enter'], [17, 'ControlLeft'],
  [87, 'KeyW'], [65, 'KeyA'], [83, 'KeyS'], [68, 'KeyD'], [16, 'ShiftLeft']]
const url = (pkg, cls) => `http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&test=generic&frames=${FRAMES}`
const FP = `(() => {
  const acc = []
  const walk = (o) => { for (const c of o.children || []) {
    const s = c._curState
    if (s) acc.push([s.x, s.y, s.rotation, s.xscale, s.yscale, s.alpha].map(v => Math.round(v * 100)).join(',') + ',' + (c._currentframe | 0) + (c.visible ? 'v' : 'h'))
    else acc.push([c.x, c.y].map(v => Math.round(v * 100)).join(',') + (c.visible ? 'v' : 'h') + (c.text != null ? c.text : ''))
    walk(c) } }
  if (kk.gameRoot) walk(kk.gameRoot)
  let h = 2166136261; const str = acc.join('|')
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 }
  return JSON.stringify({ f: kk.replay.getCurrentFrame(), score: document.getElementById('score').textContent, n: acc.length, h })
})()`

async function live(pkg, cls, seed) {
  let rs = seed
  const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
  const b = await launch(PORT)
  const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
  const mouse = (type, x, y, buttons = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x, y: 8 + y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1 })
  try {
    await b.goto(url(pkg, cls))
    await b.waitFor('!!(window.kk && kk.game)', 60000)
    await b.eval('kk.setReplaySpeed(3)')
    const t0 = Date.now()
    while (!(await b.eval('!!window.__logs.find(l => l.includes("Replay data:"))'))) {
      if (Date.now() - t0 > 240000) throw new Error('no game over')
      const r = rnd(10)
      if (r < 5) { const [c, k] = KEYS[rnd(KEYS.length)]; await key('keyDown', c, k); await b.sleep(30 + rnd(150)); await key('keyUp', c, k) }
      else if (r < 8) { const x = rnd(600), y = 40 + rnd(540); await mouse('mouseMoved', x, y); await mouse('mousePressed', x, y, 1); await b.sleep(20 + rnd(60)); await mouse('mouseReleased', x, y) }
      else { for (let i = 0; i < 6; i++) { await mouse('mouseMoved', rnd(600), rnd(600)); await b.sleep(15) } }
    }
    return {
      live: await b.eval(`document.getElementById('score').textContent`),
      data: (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
    }
  } finally { await b.close() }
}

async function watch(pkg, cls, data, f60) {
  const b = await launch(PORT)
  const out = {}
  try {
    await b.goto(url(pkg, cls) + '&seed=123&replay=' + encodeURIComponent(data))
    await b.waitFor('!!(window.kk && kk.game && kk.replay.isPlayingReplay())', 60000)
    await b.eval('kk.setReplayPaused(true)')
    out.len = await b.eval('kk.getReplayLength()')
    if (f60 == null) f60 = Math.round(out.len * 0.6)
    out.f60 = f60
    await b.eval(`kk.seekReplay(${f60})`)
    await b.waitFor('kk.seekTarget == null', 180000)
    out.fp60 = await b.eval(FP)
    await b.eval('kk.setReplaySpeed(8)'); await b.eval('kk.setReplayPaused(false)')
    await b.waitFor('kk.gameOverScreen != null || kk.game == null', 180000)
    out.end = await b.eval(`document.getElementById('score').textContent`)
    const errs = b.consoleLines.filter(l => /EXCEPTION|CRASH/i.test(l))
    if (errs.length) out.errors = errs.slice(0, 2).map(e => e.slice(0, 300))
  } finally { await b.close() }
  return out
}

if (mode === 'record') {
  for (const gc of process.argv.slice(5)) {
    const [pkg, cls] = gc.split(':')
    const r = { game: pkg, cls }
    try {
      Object.assign(r, await live(pkg, cls, 11))
      Object.assign(r, await watch(pkg, cls, r.data))
      r.match = r.end === r.live ? 'MATCH' : 'MISMATCH'
    } catch (e) { r.error = e.message.slice(0, 200) }
    fs.appendFileSync(file, JSON.stringify(r) + '\n')
    console.log(r.game, r.match || r.error, 'chars', r.data && r.data.length)
  }
} else {
  for (const line of fs.readFileSync(file, 'utf8').split('\n').filter(Boolean)) {
    const r = JSON.parse(line)
    if (!r.data) continue
    try {
      const w = await watch(r.game, r.cls, r.data, r.f60)
      console.log(r.game, 'state 60%', w.fp60 === r.fp60 ? 'SAME' : 'DIFF ' + w.fp60 + ' / ' + r.fp60,
        '| end', w.end === r.live ? 'MATCH' : 'MISMATCH ' + w.end + ' / ' + r.live, w.errors ? w.errors : '')
    } catch (e) { console.log(r.game, 'ERROR', e.message.slice(0, 200)) }
  }
}
