// Pacifik: cost of a busy scene. Plays a replay from a step at normal speed and times each browser frame (physics:
// kk.updatePhysics, render: renderer.render), with the number of canons, balls and particles on screen.
// usage: GPU=1 HPORT=8811 PORT=9940 node pperf.mjs <replay file> <extra url> <from step> [seconds]
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [file, extra, from, secs = '10'] = process.argv.slice(2)
const data = readFileSync(file, 'utf8').split('\n')[0]
const b = await launch(+(process.env.PORT || 9940))
try {
  await b.goto(HOST + '/game.html?game=pacifik&cls=GamePacifik&seed=123' + extra + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser && kk.replayHud)', 60000)
  await b.eval('kk.setReplayPaused(true)')
  await b.eval(`kk.seekReplay(${+from})`)
  await b.waitFor('kk.seekTarget == null', 120000)
  await b.eval(`(() => {
    const r = kk.renderer, R = r.render.bind(r), G = Object.getPrototypeOf(kk.game), U = G.update
    window.__f = []; let phys = 0, rend = 0
    G.update = function (d) { const t = performance.now(); const x = U.call(this, d); phys += performance.now() - t; return x }
    r.render = function (...a) { const t = performance.now(); const x = R(...a); rend += performance.now() - t; return x }
    let last = performance.now()
    const loop = () => { const now = performance.now(); const g = kk.game
      if (window.__noglow) for (const p of g.root.spr.children) for (const c of p.children) if (c.filters && c.filters.length === 1 && c.filters[0].constructor.name.includes('BoxBlur')) c.renderable = false
      __f.push([now - last, phys, rend, g ? g.balls.filter((b) => b.mc).length : 0]); phys = rend = 0; last = now; requestAnimationFrame(loop) }
    requestAnimationFrame(loop)
  })()`)
  // OFF=canons|glows: switch a family of filters off (cost comparison)
  if (process.env.OFF === 'canons') await b.eval(`(() => { const P = Object.getPrototypeOf(kk.game.laser.mc).constructor; const C = kk.game.canons1.concat(kk.game.canons2).find((c) => c); const Cp = Object.getPrototypeOf(C); Cp.update = function () {} ; for (const c of kk.game.canons1.concat(kk.game.canons2)) if (c && c.mc) c.mc.set_filters([]) })()`)
  if (process.env.OFF === 'glows') await b.eval(`(() => { const r = kk.renderer, R = r.render; for (const p of kk.game.root.spr.children) for (const c of p.children) if (c.filters && c.children.length && !c.texture?.valid) {} ; window.__noglow = true })()`)
  await b.eval('kk.setReplayPaused(false)')
  await b.sleep(+secs * 1000)
  console.log(await b.eval(`(() => { const f = __f.slice(10), q = (a, p) => a.slice().sort((x, y) => x - y)[Math.floor(a.length * p)]
    const dt = f.map((x) => x[0]), ph = f.map((x) => x[1]), re = f.map((x) => x[2])
    return JSON.stringify({ frames: f.length, dt50: q(dt, 0.5).toFixed(1), dt99: q(dt, 0.99).toFixed(1), dtMax: Math.max(...dt).toFixed(1), long: dt.filter((x) => x > 25).length,
      phys50: q(ph, 0.5).toFixed(2), physMax: Math.max(...ph).toFixed(2), rend50: q(re, 0.5).toFixed(2), rend99: q(re, 0.99).toFixed(2), rendMax: Math.max(...re).toFixed(2), balls: Math.max(...f.map((x) => x[3])) }) })()`))
  console.log('canons', await b.eval('kk.game.canons1.concat(kk.game.canons2).filter((c) => c && c.mc).length'), 'clips', await b.eval('kk.game.root.spr.children.reduce((n, p) => n + p.children.length, 0)'))
} finally {
  console.log(b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)).slice(0, 3).join('\n'))
  await b.close()
}
