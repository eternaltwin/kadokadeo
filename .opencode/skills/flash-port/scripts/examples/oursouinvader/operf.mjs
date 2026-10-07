// Oursouinvader performance: browser frames per second, render and physics time per frame during a live game (the
// hero shoots and moves). Run it with GPU=1 for the real numbers (the software renderer is far slower).
// usage: node operf.mjs [seconds]     env: PORT (default 9964), HPORT, GPU, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 10)
const b = await launch(+(process.env.PORT || 9964))
const key = (type, code, k, c) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c })
try {
  await b.goto(HOST + '/game.html?game=oursouinvader&cls=GameOursouinvader&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval(`(() => {
    const sys = PIXI.Ticker.system, R = kk.renderer
    window.__fr = []
    let cur = null
    sys.add(() => { cur = { t: performance.now(), rend: 0 } }, null, 1000)
    sys.add(() => { if (cur) cur.phys = performance.now() - cur.t }, null, -1000)
    const render = R.render.bind(R)
    R.render = function (...a) { const t = performance.now(); render(...a); if (cur) cur.rend += performance.now() - t }
    kk.ticker.add(() => { if (cur) { cur.total = performance.now() - cur.t; cur.m = kk.game.monsterList.length; __fr.push(cur); cur = null } }, null, -1000)
  })()`)
  await key('keyDown', 32, ' ', 'Space')
  const t0 = Date.now()
  let i = 0
  while (Date.now() - t0 < secs * 1000) {
    const k = i++ % 2 ? [37, 'ArrowLeft'] : [39, 'ArrowRight']
    await key('keyDown', k[0], k[1], k[1]); await b.sleep(400); await key('keyUp', k[0], k[1], k[1])
    await b.sleep(100)
  }
  const fr = await b.eval('__fr')
  const st = await b.eval('JSON.stringify(window.__state)')
  const avg = (a) => a.reduce((s, v) => s + v, 0) / Math.max(1, a.length)
  const dur = (fr[fr.length - 1].t - fr[0].t) / 1000
  const rend = fr.map(f => f.rend), tot = fr.map(f => f.total)
  rend.sort((a, c) => a - c); tot.sort((a, c) => a - c)
  console.log(JSON.stringify({ gpu: !!process.env.GPU, fps: +(fr.length / dur).toFixed(1), frames: fr.length,
    rendAvg: +avg(rend).toFixed(2), rend95: +rend[Math.floor(rend.length * 0.95)].toFixed(2), rendMax: +rend[rend.length - 1].toFixed(2),
    totAvg: +avg(tot).toFixed(2), totMax: +tot[tot.length - 1].toFixed(2), monsters: fr[fr.length - 1].m }))
  console.log(st)
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
