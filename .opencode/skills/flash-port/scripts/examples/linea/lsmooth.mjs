// Linea smoothness: every rendered picture, the squares on screen (their speed against the time shown must stay
// 1.25 Flash frames of scroll per step) and the head of the trail (where the bitmap is cut: it must not shake).
// usage: node lsmooth.mjs [ms]      env: GPU=1 (real GPU), PORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const ms = +(process.argv[2] || 8000)
const b = await launch(+(process.env.PORT || 9880))
try {
  await b.goto(HOST + '/game.html?game=linea&cls=GameLinea&seed=123')
  await b.waitFor('!!(window.kk && kk.game && kk.game.step == 2)', 60000)
  await b.eval(`(() => {
    window.__rec = []
    const ids = new WeakMap(); let next = 1
    const r = kk.renderer.render.bind(kk.renderer)
    kk.renderer.render = function (...a) {
      r(...a)
      const g = kk.game, t = g.dotter.plane.sprite
      if (g.step != 2) return
      const objs = g.objects.filter(o => o && !o.removed).map(o => { if (!ids.has(o)) ids.set(o, next++); return [ids.get(o), o.spr.worldTransform.tx] })
      __rec.push([performance.now(), kk.replay.getCurrentFrame() + kk.ff.alpha, t.worldTransform.tx + t.texture.frame.width * t.worldTransform.a, objs, g.scroll])
    }
  })()`)
  await b.sleep(ms)
  const rec = JSON.parse(await b.eval('JSON.stringify(__rec)'))
  if (process.env.DUMP) (await import("fs")).writeFileSync(process.env.DUMP, JSON.stringify(rec))
  // squares: on-screen px per step shown; expected 1.25 * scroll * 2 (x2)
  const last = new Map()
  const v = []
  for (const [t, s, head, objs, scroll] of rec) {
    for (const [id, x] of objs) {
      const p = last.get(id)
      // (not its first pictures: created off screen)
      if (p && p[2] > 2 && s - p[0] > 0.05) v.push({ v: (x - p[1]) / (s - p[0]), want: -1.25 * scroll * 2 })
      last.set(id, [s, x, p ? p[2] + 1 : 0])
    }
  }
  const dev = v.map(e => Math.abs(e.v - e.want) / Math.abs(e.want))
  dev.sort((a, c) => a - c)
  const bad = dev.filter(d => d > 0.1).length
  console.log('pictures', rec.length, '| square speed samples', v.length, 'median dev', (dev[dev.length >> 1] * 100).toFixed(2) + '%',
    'p95', (dev[Math.floor(dev.length * 0.95)] * 100).toFixed(2) + '%', 'off by >10%:', bad)
  const heads = rec.map(r => r[2])
  let jumps = 0, maxd = 0
  for (let i = 1; i < heads.length; i++) { const d = Math.abs(heads[i] - heads[i - 1]); maxd = Math.max(maxd, d); if (d > 2) jumps++ }
  console.log('trail head on screen: max move between pictures', maxd.toFixed(2), 'px, moves > 2 px:', jumps, '(no key held: should stay put)')
} finally { await b.close() }
