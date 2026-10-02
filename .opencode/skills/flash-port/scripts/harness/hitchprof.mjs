// What happens in the long frames of a live game: CPU profile aligned on the frames (a marker gives the clock offset),
// self time by function inside each frame longer than LIMIT ms.   node hitchprof.mjs <game> <Class> [ms]
import { launch } from './cdp.mjs'
const [pkg, cls, ms = '30000'] = process.argv.slice(2)
const LIMIT = +(process.env.LIMIT || 10)
const b = await launch(+(process.env.PORT || 9404))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
try {
  await b.goto(`http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&seed=${process.env.SEED || 123}&js=${process.env.JS || pkg}${process.env.EXTRA || ''}`)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  if (process.env.INIT) { await b.waitFor('!!(kk.game && kk.game.hero)', 60000); await b.eval(process.env.INIT) }
  await b.eval(`(() => {
    const sys = PIXI.Ticker.system, app = kk.ticker
    window.__fr = []
    let cur = null
    sys.add(() => { cur = { t: performance.now() } }, null, 1000)
    sys.add(() => { if (cur) cur.pe = performance.now() }, null, -1000)
    app.add(() => { if (cur) { cur.e = performance.now(); __fr.push(cur); cur = null } }, null, -1000)
    window.__markerFn = function __markerFn() { const t = performance.now(); while (performance.now() - t < 4) {} return t }
  })()`)
  await b.send('Profiler.enable'); await b.send('Profiler.setSamplingInterval', { interval: 100 }); await b.send('Profiler.start')
  const markT = await b.eval('__markerFn()')
  await key('keyDown', 39, 'ArrowRight')
  const t0 = Date.now()
  let i = 0
  while (Date.now() - t0 < +ms) {
    i++
    await key('keyDown', 38, 'ArrowUp'); await b.sleep(200); await key('keyUp', 38, 'ArrowUp')
    if (i % 2) { await key('keyDown', 32, 'Space'); await b.sleep(50); await key('keyUp', 32, 'Space') }
    await b.sleep(700)
  }
  await key('keyUp', 39, 'ArrowRight')
  const { profile } = await b.send('Profiler.stop', {}, 120000)
  const fr = JSON.parse(await b.eval('JSON.stringify(__fr)'))
  const byId = new Map(profile.nodes.map(n => [n.id, n]))
  let ts = profile.startTime
  const samples = profile.samples.map((id, k) => { ts += profile.timeDeltas[k]; return [ts / 1000, byId.get(id)] })
  const mk = samples.find(([, n]) => n.callFrame.functionName === '__markerFn')
  const off = mk[0] - markT // profile ms - performance.now ms
  const name = (n) => (n.callFrame.functionName || '(anonyme)') + ' ' + n.callFrame.url.split('/').pop() + ':' + n.callFrame.lineNumber
  const longs = fr.filter(f => f.e - f.t > LIMIT)
  console.log(pkg, 'frames', fr.length, 'long (>' + LIMIT + ' ms)', longs.length)
  for (const f of longs.slice(0, 12)) {
    const self = new Map()
    for (const [t, n] of samples) if (t >= f.t + off - 0.2 && t <= f.e + off + 0.2) self.set(name(n), (self.get(name(n)) || 0) + 0.1)
    const top = [...self.entries()].sort((a, c) => c[1] - a[1]).slice(0, 8)
    console.log('  frame of', (f.e - f.t).toFixed(1), 'ms (simulation', (f.pe - f.t).toFixed(1), 'ms):', top.map(([k, v]) => v.toFixed(1) + ' ' + k).join(' | '))
  }
} finally { await b.close() }
