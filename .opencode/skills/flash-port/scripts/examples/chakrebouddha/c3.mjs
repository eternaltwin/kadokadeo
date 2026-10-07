// Chakre Bouddha: a bot plays a whole game with real mouse (or touch) events and key releases, then its replay is
// played and the end states compared.
// The bot clicks (anywhere on the stage) when a chakra lights up, after a reaction time drawn between fast (inside the
// first quarter of the chakra's time: a "high", energy + neon, combos of 7 give the SUPRA bonus) and slow; now and then
// it clicks with nothing to touch (energy lost), clicks twice, clicks the bar under the stage (not the stage: ignored),
// lets a chakra go, releases a key (Key.onKeyUp of the original: a replay event). It gets clumsier with time, so the
// game ends (no energy left).
// usage: node c3.mjs <rng seed> [replay speed] [shots dir]
//        env: PORT, HPORT, EXTRA (url params), TOUCH=1 (an emulated touch screen; the replay is watched with the mouse),
//        PERF=1 (with GPU=1: shaders compiled, big textures uploaded and long frames during the game), COVER=1 (waits in
//        the page for the next lit chakra and clicks at once: highs in a row, combos and the SUPRA bonus)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=chakrebouddha&cls=GameChakreBouddha&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9865)
const OX = 8, OY = 8   // the canvas in the page
const TOUCH = !!process.env.TOUCH
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const mouse = (type, x, y) => b.send('Input.dispatchMouseEvent', { type, x: OX + x * 2, y: OY + y * 2, button: 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const touch = (type, x, y) => b.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x: OX + x * 2, y: OY + y * 2 }] })
// a click at (x, y) in Flash pixels (y >= 300: the bar under the stage)
const click = async (x, y) => {
  if (TOUCH) { await touch('touchStart', x, y); await sleep(30 + rnd(50)); await touch('touchEnd', x, y); return }
  await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: OX + x * 2, y: OY + y * 2, button: 'none', pointerType: 'mouse' })
  await mouse('mousePressed', x, y)
  await sleep(30 + rnd(50))
  await mouse('mouseReleased', x, y)
}
const KEYS = [[32, ' ', 'Space'], [65, 'a', 'KeyA'], [112, 'F1', 'F1'], [37, 'ArrowLeft', 'ArrowLeft']]
const keyTap = async () => {
  const [kc, key, code] = KEYS[rnd(KEYS.length)]
  await b.send('Input.dispatchKeyEvent', { type: 'keyDown', windowsVirtualKeyCode: kc, nativeVirtualKeyCode: kc, key, code })
  await sleep(40 + rnd(60))
  await b.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: kc, nativeVirtualKeyCode: kc, key, code })
}
const STATE = `(() => { const g = kk.game; if (!g || !g.chakras) return null
  const s = g.activatedStep; const i = s == null ? -1 : s._hx_index
  const c = i >= 0 && i < 7 ? g.chakras[i] : null
  return { over: !!window.__over, i, lock: g.chakraLock, started: g.started, cycles: c ? c.cycles : 0,
    trap: c ? c.trap : false, f: g.frameCount, energy: g.mcEnergy.mask._y } })()`

// COVER: resolves when a chakra lights up (or after 3 s)
const WAIT = `new Promise((res) => { const t0 = performance.now(); const f = () => { const g = kk.game
  const s = g && g.activatedStep; const i = s == null ? -1 : s._hx_index
  if (!g || window.__over || (i >= 0 && i < 7 && !g.chakraLock) || performance.now() - t0 > 3000) res(1); else requestAnimationFrame(f) }; f() })`
const COVER = !!process.env.COVER
const stats = { clicks: 0, fast: 0, slow: 0, wild: 0, doubles: 0, bar: 0, letGo: 0, traps: 0, keys: 0 }
let data, liveOver, t = 0
try {
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.chakras)', 60000)
  if (process.env.PERF) await b.eval(`(() => {
    const S = kk.renderer.shader
    window.__progs = []
    const gen = S.generateShader.bind(S)
    S.generateShader = function (shader) { const t = performance.now(); const r = gen(shader); __progs.push({ ms: +(performance.now() - t).toFixed(1), frame: kk.replay.getCurrentFrame(), name: shader.program.name || '' }); return r }
    window.__ups = []
    const gl = kk.renderer.gl
    for (const fn of ['texImage2D', 'texSubImage2D']) {
      const o = gl[fn].bind(gl)
      gl[fn] = function (...a) { const t = performance.now(); const r = o(...a); const src = a[a.length - 1]; const w = src && src.width != null ? src.width : a[3], h = src && src.height != null ? src.height : a[4]; if (w * h >= 64 * 64) __ups.push({ fn, ms: +(performance.now() - t).toFixed(1), frame: kk.replay.getCurrentFrame(), size: w + 'x' + h }); return r }
    }
    const sys = PIXI.Ticker.system, app = kk.ticker, R = kk.renderer
    window.__fr = []
    let cur = null
    sys.add(() => { cur = { t: performance.now(), phys: 0, rend: 0, f0: kk.replay.getCurrentFrame() }; cur.ps = performance.now() }, null, 1000)
    sys.add(() => { if (cur) cur.phys = performance.now() - cur.ps }, null, -1000)
    const render = R.render.bind(R)
    R.render = function (...a) { const t = performance.now(); render(...a); if (cur) cur.rend += performance.now() - t }
    app.add(() => { if (cur) { cur.total = performance.now() - cur.t; if (__fr.length < 100000) __fr.push([+cur.total.toFixed(1), +cur.phys.toFixed(1), +cur.rend.toFixed(1), cur.f0]); cur = null } }, null, -1000)
  })()`)
  let snap = 0, seen = -2, plan = null
  const t0 = Date.now()
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 20 === 0 && snap < 80) await b.screenshot(shots + '/c' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    // clumsier with time (seconds)
    const age = (Date.now() - t0) / 1000
    if (rnd(60) === 0) { await keyTap(); stats.keys++ }
    if (s.i >= 0 && s.i < 7 && !s.lock) {
      if (seen !== s.i) {
        // a new chakra: when to click (ms after it lit up), or never
        seen = s.i
        const p = COVER ? 100 - rnd(100) * 0.15 : rnd(100)
        const miss = Math.min(40, 5 + age / 4)
        if (s.trap && rnd(2) === 0) plan = { at: 300 + rnd(400), trap: true }
        else if (s.trap || p < miss) { plan = null; stats.letGo++ }
        else if (COVER && p > 86.5) plan = { at: 0 }
        else if (p < miss + 45) plan = { at: rnd(250) }
        else plan = { at: 250 + rnd(1000) }
        plan && (plan.t = Date.now())
      }
      if (plan && Date.now() - plan.t >= plan.at) {
        if (plan.at === 0 && TOUCH) { await touch('touchStart', 150, 150); await touch('touchEnd', 150, 150) }
        else if (plan.at === 0) { await mouse('mousePressed', 150, 150); await mouse('mouseReleased', 150, 150) }
        else await click(20 + rnd(260), 20 + rnd(260))
        stats.clicks++
        if (plan.trap) stats.traps++; else if (plan.at < 250) stats.fast++; else stats.slow++
        if (rnd(8) === 0) { await sleep(40 + rnd(200)); await click(20 + rnd(260), 20 + rnd(260)); stats.doubles++ }
        plan = null
      }
    } else {
      if (s.i < 0) seen = -2
      // nothing to touch: a wild click now and then (more and more), or a click on the bar
      if (s.started && rnd(Math.max(40, 400 - age * 3)) === 0) { await click(20 + rnd(260), 20 + rnd(260)); stats.wild++ }
      else if (rnd(300) === 0) { await click(20 + rnd(260), 302 + rnd(15)); stats.bar++ }
    }
    if (COVER && !(s.i >= 0 && s.i < 7 && !s.lock)) await b.eval(WAIT)
    else await sleep(15 + rnd(20))
  }
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'polls', t, 'replay chars', data.length)
  if (process.env.PERF) {
    console.log('shaders', await b.eval('JSON.stringify(__progs)'))
    console.log('uploads', await b.eval('JSON.stringify(__ups)'))
    console.log('frames', await b.eval(`(() => { const f = __fr.slice(30), t = f.map((x) => x[0]).sort((a, b) => a - b), q = (p) => t[Math.floor(t.length * p)]
      return JSON.stringify({ n: f.length, p50: q(0.5), p99: q(0.99), max: t[t.length - 1], long: f.filter((x) => x[0] > 25).slice(0, 12), physMax: Math.max(...f.map((x) => x[1])), rendMax: Math.max(...f.map((x) => x[2])) }) })()`))
  }
  writeFileSync(gameDir('chakrebouddha', 'replays') + '/c_replay_' + process.argv[2] + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.chakras)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
