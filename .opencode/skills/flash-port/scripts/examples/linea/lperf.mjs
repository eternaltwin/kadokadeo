// Linea: cost of a game step (1 or 2 Flash frames + the display) and of a rendered picture, measured while a bot
// replay plays (several lines, crashes, particles). usage: node lperf.mjs <replay file of l3.mjs> [extra url]
//   env: GPU=1 (real GPU), PORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data] = readFileSync(process.argv[2], 'utf8').split('\n')
const b = await launch(+(process.env.PORT || 9890))
try {
  await b.goto(HOST + '/game.html?game=linea&cls=GameLinea&seed=123' + (process.argv[3] || '') + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.dotter)', 60000)
  await b.eval(`(() => {
    window.__phys = []; window.__rend = []
    // (the fixed-rate loop keeps its own reference to updatePhysics)
    const up = kk.ff.update
    kk.ff.update = function (dt) { const t = performance.now(); up(dt); __phys.push(performance.now() - t) }
    window.__game = []; window.__trail = []
    const P = Object.getPrototypeOf(kk.game)
    const gu = P.update; P.update = function (d) { const t = performance.now(); gu.call(this, d); __game.push(performance.now() - t) }
    const T = Object.getPrototypeOf(kk.game.dotter.plane)
    const ct = T.colorTransform; T.colorTransform = function (m, o) { const t = performance.now(); ct.call(this, m, o); __trail.push(performance.now() - t) }
    const r = kk.renderer.render.bind(kk.renderer)
    kk.renderer.render = function (...a) { const t = performance.now(); r(...a); __rend.push(performance.now() - t) }
  })()`)
  await b.waitFor('!!window.__over', 300000)
  const st = (a) => { a = a.slice().sort((x, y) => x - y); return `n ${a.length} median ${a[a.length >> 1].toFixed(3)} ms, p99 ${a[Math.floor(a.length * 0.99)].toFixed(3)}, max ${a[a.length - 1].toFixed(2)}` }
  console.log('step   ', st(JSON.parse(await b.eval('JSON.stringify(__phys)'))))
  console.log('game.update', st(JSON.parse(await b.eval('JSON.stringify(__game)'))))
  console.log('  colorTransform', st(JSON.parse(await b.eval('JSON.stringify(__trail)'))))
  console.log('render ', st(JSON.parse(await b.eval('JSON.stringify(__rend)'))))
} finally { await b.close() }
