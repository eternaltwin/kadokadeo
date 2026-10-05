// Schizo Fuzz smoothness: launches the squirrel with real keys, then on every rendered picture records the time shown
// (frame + alpha), the hero and the items on screen. Their speed against the time shown must be steady (40 Flash
// frames per second shown at 1.25 per step, see MC.hx): a jerk is a picture whose speed is far from its neighbours'.
// usage: node fsmooth.mjs [ms]      env: GPU=1 (real GPU), PORT, DUMP (file for the raw records)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const ms = +(process.argv[2] || 10000)
const b = await launch(+(process.env.PORT || 9870))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const tap = async (t) => { await key('keyDown', 32, ' '); await b.sleep(t); await key('keyUp', 32, ' ') }
try {
  await b.goto(HOST + '/game.html?game=schizofuzz&cls=GameSchizoFuzz&seed=123')
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(500); await tap(80); await b.sleep(200); await tap(900); await b.sleep(500); await tap(80)
  await b.waitFor('kk.game.state._hx_index == 5', 10000)
  await b.eval(`(() => {
    window.__rec = []
    const ids = new WeakMap(); let next = 1
    const r = kk.renderer.render.bind(kk.renderer)
    kk.renderer.render = function (...a) {
      r(...a)
      const g = kk.game, h = g.hero && !g.hero.removed ? g.hero.clip.worldTransform : null
      const its = g.items.filter(o => !o.mc.removed).map(o => { if (!ids.has(o)) ids.set(o, next++); return [ids.get(o), o.mc.clip.worldTransform.tx] })
      __rec.push([performance.now(), kk.replay.getCurrentFrame() + kk.ff.alpha, h ? h.tx : null, h ? h.ty : null, its])
    }
  })()`)
  await b.sleep(ms)
  const rec = JSON.parse(await b.eval('JSON.stringify(__rec)'))
  if (process.env.DUMP) (await import('fs')).writeFileSync(process.env.DUMP, JSON.stringify(rec))
  const dts = rec.slice(1).map((r, i) => r[0] - rec[i][0]).sort((x, y) => x - y)
  console.log('pictures', rec.length, '| median interval', dts[dts.length >> 1].toFixed(1), 'ms, max', dts[dts.length - 1].toFixed(1))
  // speeds per series (px per step shown), a jerk: far from the median of the 4 neighbours
  const jerks = (series, name) => {
    let n = 0, bad = 0
    const ex = []
    for (const s of series) {
      for (let k = 2; k < s.length - 2; k++) {
        const around = [s[k - 2].v, s[k - 1].v, s[k + 1].v, s[k + 2].v].sort((x, y) => x - y)
        const med = (around[1] + around[2]) / 2
        n++
        if (Math.abs(s[k].v - med) > Math.max(4, Math.abs(med) * 0.35)) { bad++; if (ex.length < 6) ex.push({ v: +s[k].v.toFixed(1), med: +med.toFixed(1), ds: +s[k].ds.toFixed(2) }) }
      }
    }
    console.log(name + ': samples', n, 'jerks', bad, ex.length ? JSON.stringify(ex) : '')
  }
  const speeds = (get) => {
    const out = []
    for (let i = 1; i < rec.length; i++) {
      const a = get(rec[i - 1]), c = get(rec[i]), ds = rec[i][1] - rec[i - 1][1]
      if (a == null || c == null || ds <= 0.05) continue
      out.push({ v: (c - a) / ds, ds })
    }
    return out
  }
  jerks([speeds((r) => r[2])], 'hero x')
  jerks([speeds((r) => r[3])], 'hero y')
  const byId = new Map()
  for (let i = 1; i < rec.length; i++) {
    const prev = new Map(rec[i - 1][4]), ds = rec[i][1] - rec[i - 1][1]
    for (const [id, x] of rec[i][4]) {
      // (on screen only: the items are created far to the right, their first pictures are not shown)
      if (!prev.has(id) || ds <= 0.05 || x < -60 || x > 660) continue
      if (!byId.has(id)) byId.set(id, [])
      byId.get(id).push({ v: (x - prev.get(id)) / ds, ds })
    }
  }
  jerks([...byId.values()], 'items x')
} finally { await b.close() }
