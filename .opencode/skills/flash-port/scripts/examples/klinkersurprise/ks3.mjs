// Klinker Surprise: a bot plays a whole game with real mouse events, then its replay is played and the end states
// compared.
// The map scrolls while the pointer is more than 50 Flash pixels from the centre of the stage: the bot brings the cell it
// wants near the centre that way (button released), then presses on it and drags over the next cells of its path (while
// the map is pressed, the cell under the pointer is taken at every frame). It links the two generators of each colour by
// a path found on the wrapping grid (through the path of another colour now and then: it is cut), gives a run up now
// and then (a press on its start generator) and frees a linked colour (a press on a lit generator).
// usage: node ks3.mjs <rng seed> [replay speed] [shots dir]
//        env: EXTRA (url params: &test=ks&timer=900&map=2, see harness/modes/klinkersurprise.js), PORT, HPORT,
//        COVER=1 (gives up, frees and cuts much more often), PERF=1 (with GPU=1: shaders compiled, big textures uploaded
//        and long frames during the game, like harness/shaders.mjs and hitch.mjs), TOUCH=1 (an emulated touch screen:
//        a finger cannot hover, the pointer jumps where it touches; a scroll is a tap out of the dead zone, the
//        pointer stays there until the next touch; the replay is watched with the mouse)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
let rs = +(process.argv[2] || 1)
const speed = +(process.argv[3] || 8)
const shots = process.argv[4]
const rnd = (n) => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 16) % n }
const URL0 = HOST + '/game.html?game=klinkersurprise&cls=GameKlinkerSurprise&seed=123' + (process.env.EXTRA || '')
const PORT = +(process.env.PORT || 9863)
const OX = 8, OY = 8   // the canvas in the page
const COVER = !!process.env.COVER
// one chance in: freeing a linked colour, giving a run up, a path cutting another colour's
const P_FREE = COVER ? 5 : 25, P_GIVEUP = COVER ? 4 : 45, P_CUT = COVER ? 1 : 3
let b = await launch(PORT)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
// pointer in Flash pixels of the stage (x2 on the canvas)
let px = 150, py = 150, held = false
const TOUCH = !!process.env.TOUCH
const mouse = (type, x, y, down) => b.send('Input.dispatchMouseEvent', { type, x: OX + x * 2, y: OY + y * 2, button: type === 'mouseMoved' && !down ? 'none' : 'left', buttons: down ? 1 : 0, clickCount: 1, pointerType: 'mouse' })
const touch = (type, x, y) => b.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x: OX + x * 2, y: OY + y * 2 }] })
const moveTo = async (x, y) => {
  if (TOUCH && !held) { px = x; py = y; return }
  const n = 2 + rnd(3)
  for (let i = 1; i <= n; i++) {
    if (TOUCH) await touch('touchMove', px + (x - px) * i / n, py + (y - py) * i / n)
    else await mouse('mouseMoved', px + (x - px) * i / n, py + (y - py) * i / n, held)
    await sleep(8 + rnd(14))
  }
  px = x; py = y
}
const press = async () => { if (TOUCH) await touch('touchStart', px, py); else await mouse('mousePressed', px, py, true); held = true }
const release = async () => { if (TOUCH) await touch('touchEnd', px, py); else await mouse('mouseReleased', px, py, false); held = false }
const click = async () => { await press(); await sleep(30 + rnd(60)); await release() }

const EMPTY = 0, PAINT = 50
const DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]]
const hmod = (n, m) => { while (n > m) n -= 2 * m; while (n < -m) n += 2 * m; return n }
const STATE = `(() => { const g = kk.game; if (!g || !g.map) return null
  return { over: !!window.__over, step: g.step._hx_index, level: g.level, size: g.size, n: g.xmax, zw: g.zw,
    mx: g.map._x, my: g.map._y, grid: g.grid, colorId: g.colorId, path: g.path, free: g.free.length,
    archive: [0, 1, 2, 3, 4, 5, 6, 7].map(i => g.archive[i] ? g.archive[i].length : -1),
    gens: g.generators.map(x => [x.px, x.py, x.type]), timer: g.levelTimer } })()`
// the centre of the copy of a cell nearest to the centre of the stage (Flash pixels)
const screen = (s, c) => [150 + hmod(s.mx + (c[0] + 0.5) * s.size - 150, s.zw / 2), 150 + hmod(s.my + (c[1] + 0.5) * s.size - 150, s.zw / 2)]
const wrap = (s, x, y) => [((x % s.n) + s.n) % s.n, ((y % s.n) + s.n) % s.n]
const key = (c) => c[0] + ',' + c[1]

// the cheapest path of empty cells (or cells of another colour, which the run cuts, at a higher cost) from `from`
// (a generator of colour c, or the last cell of the run) to a cell next to the other generator of c
function plan(s, c, from, other, cut) {
  const near = new Set(DIR.map((d) => key(wrap(s, other[0] + d[0], other[1] + d[1]))))
  const dist = new Map([[key(from), 0]]), prev = new Map()
  let open = [from]
  while (open.length) {
    open.sort((a, b) => dist.get(key(a)) - dist.get(key(b)))
    const cur = open.shift()
    const kc = key(cur)
    if (kc !== key(from) && near.has(kc)) {
      const out = [cur]
      let k = kc
      while (prev.has(k) && prev.get(k) !== key(from)) { k = prev.get(k); out.unshift(k.split(',').map(Number)) }
      return out
    }
    for (const d of DIR) {
      const nb = wrap(s, cur[0] + d[0], cur[1] + d[1])
      const t = s.grid[nb[0]][nb[1]]
      let cost
      if (t === EMPTY) cost = 1
      else if (cut && t >= PAINT && t !== PAINT + c) cost = COVER ? 0.5 : 4
      else continue
      const nd = dist.get(kc) + cost
      if (!dist.has(key(nb)) || nd < dist.get(key(nb))) { dist.set(key(nb), nd); prev.set(key(nb), kc); open.push(nb) }
    }
  }
  return null
}

const stats = { presses: 0, scrolls: 0, giveUps: 0, frees: 0, cutPlans: 0, levels: 0 }
let live, data, liveOver, t = 0, cut = false, lastLevel = 0
try {
  if (TOUCH) await b.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 })
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game && kk.game.map)', 60000)
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
  let snap = 0
  for (; ; t++) {
    const s = await b.eval(STATE)
    if (!s || s.over) break
    if (shots && t % 25 === 0 && snap < 80) await b.screenshot(shots + '/k' + String(snap++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 640 })
    if (s.level !== lastLevel) { lastLevel = s.level; stats.levels++ }
    if (s.step !== 0) {
      // between two levels: the pointer rests near the centre, the button up
      if (held) await release()
      if (rnd(4) === 0) await moveTo(130 + rnd(40), 130 + rnd(40))
      await sleep(60)
      continue
    }
    let target = null, then = null
    if (s.colorId == null) {
      const linked = s.gens.filter((g) => s.archive[g[2]] >= 0)
      const todo = [...new Set(s.gens.filter((g) => s.archive[g[2]] < 0).map((g) => g[2]))]
      const c = todo.length ? todo[rnd(todo.length)] : null
      const pair = c === null ? [] : s.gens.filter((g) => g[2] === c)
      cut = s.free === 0 && rnd(P_CUT) === 0
      const p = pair.length === 2 ? plan(s, c, pair[0], pair[1], cut) : null
      if (p && cut && p.some((q) => s.grid[q[0]][q[1]] >= PAINT)) stats.cutPlans++
      if ((!p || rnd(P_FREE) === 0) && linked.length && s.free === 0) {
        // a press on a lit generator: its path is freed
        target = linked[rnd(linked.length)]
        then = 'free'
      } else if (p) {
        target = p[0]
        // the pointer on the side of the start generator in the cell (getTargetDir picks the generator it points to)
        then = [pair[0][0] - p[0][0], pair[0][1] - p[0][1]].map((v) => hmod(v, s.n / 2))
      } else {
        await sleep(80)
        continue
      }
    } else {
      const last = s.path[s.path.length - 1]
      const other = s.gens.find((g) => g[2] === s.colorId && (g[0] !== s.path[0][0] || g[1] !== s.path[0][1]))
      const p = other && plan(s, s.colorId, last, other, cut && s.free === 0)
      if (!p || (s.path.length >= 3 && rnd(P_GIVEUP) === 0)) {
        // a press on the start generator: the run is given up
        target = s.path[0]
        then = 'giveup'
      } else {
        target = p[0]
      }
    }
    const [sx, sy] = screen(s, target)
    const dx = sx - 150, dy = sy - 150
    if (Math.abs(dx) > 38 || Math.abs(dy) > 38) {
      // scroll: the pointer out of the dead zone, on the side of the cell
      if (held) await release()
      const ax = Math.abs(dx) > 38 ? 150 + Math.sign(dx) * (52 + Math.min(45, Math.abs(dx) * 0.4)) : 150
      const ay = Math.abs(dy) > 38 ? 150 + Math.sign(dy) * (52 + Math.min(45, Math.abs(dy) * 0.4)) : 150
      await moveTo(ax, ay)
      // (a finger: a tap there, the pointer stays)
      if (TOUCH) { await press(); await sleep(30 + rnd(40)); await release() }
      stats.scrolls++
      await sleep(50)
      continue
    }
    if (then === 'free' || then === 'giveup') {
      if (held) await release()
      await moveTo(sx + rnd(11) - 5, sy + rnd(11) - 5)
      await sleep(70)
      await click()
      stats[then === 'free' ? 'frees' : 'giveUps']++
      await sleep(120)
      continue
    }
    const off = Array.isArray(then) ? then.map((v) => v * s.size * 0.3) : [rnd(9) - 4, rnd(9) - 4]
    await moveTo(sx + off[0], sy + off[1])
    if (!held) {
      await sleep(70)
      await press()
      stats.presses++
    }
    await sleep(40 + rnd(40))
  }
  if (held) await release()
  await b.waitFor('!!window.__over', 120000)
  await b.waitFor('!!(window.__logs.find(l => l.includes("Replay data:")))', 60000)
  liveOver = await b.eval('JSON.stringify(window.__over)')
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
  console.log('live', liveOver, JSON.stringify(stats), 'actions', t, 'replay chars', data.length)
  if (process.env.PERF) {
    console.log('shaders', await b.eval('JSON.stringify(__progs)'))
    console.log('uploads', await b.eval('JSON.stringify(__ups)'))
    console.log('frames', await b.eval(`(() => { const f = __fr.slice(30), t = f.map((x) => x[0]).sort((a, b) => a - b), q = (p) => t[Math.floor(t.length * p)]
      return JSON.stringify({ n: f.length, p50: q(0.5), p99: q(0.99), max: t[t.length - 1], long: f.filter((x) => x[0] > 25).slice(0, 12), physMax: Math.max(...f.map((x) => x[1])), rendMax: Math.max(...f.map((x) => x[2])) }) })()`))
  }
  writeFileSync(gameDir('klinkersurprise', 'replays') + '/k_replay_' + process.argv[2] + (TOUCH ? 't' : '') + '.txt', data + '\n' + liveOver)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
b = await launch(PORT + 50)
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.map)', 60000)
  await b.eval(`kk.setReplaySpeed(${speed})`)
  await b.waitFor('!!window.__over', 900000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  console.log('replay', rep, rep === liveOver ? 'MATCH' : 'MISMATCH')
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
