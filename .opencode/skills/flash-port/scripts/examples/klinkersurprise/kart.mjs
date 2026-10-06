// Klinker Surprise: the game scene of the start screen (artwork), drawn by the port: a level of the debug build with
// its colours linked by paths (BFS on the wrapping grid), the last colour being painted (the white of the plasma on
// its last cells), the interface hidden, the game loop stopped. Composed into the artwork by kart.py.
// usage: node kart.mjs <out png> [level] [map] [selector x] [selector y]     env: HPORT, PORT, GPU=1
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const out = process.argv[2]
const level = +(process.argv[3] || 3), map = +(process.argv[4] || 1)
const sx = process.argv[5], sy = process.argv[6]
const b = await launch(+(process.env.PORT || 9879))
try {
  await b.goto(HOST + '/game.html?game=klinkersurprise&cls=GameKlinkerSurprise&seed=123&test=ks&map=' + map)
  await b.waitFor('!!(window.kk && kk.game && kk.game.map)', 60000)
  await b.sleep(500)
  const r = await b.eval(`(() => {
    kk.ff.onTick = () => {}
    const g = kk.game
    while (g.level < ${level}) { g.map.removeMovieClip(); g.initZone() }
    g.mcInter._visible = false
    ${sx !== undefined ? `g.selector.x = ${sx}; g.selector.y = ${sy};` : ''}
    g.selector.vx = 0; g.selector.vy = 0
    for (let i = 0; i < 4; i++) kk.updatePhysics(1000 / 32)
    const n = g.xmax, W = (v) => ((v % n) + n) % n, D = [[1, 0], [0, 1], [-1, 0], [0, -1]]
    const plan = (c) => {
      const gs = g.generators.filter((x) => x.type === c)
      if (gs.length < 2) return null
      const [A, B] = gs, key = (x, y) => x + ',' + y
      const near = new Set(D.map((d) => key(W(B.px + d[0]), W(B.py + d[1]))))
      const prev = new Map([[key(A.px, A.py), null]]), open = [[A.px, A.py]]
      while (open.length) {
        const [x, y] = open.shift()
        if (prev.get(key(x, y)) !== null && near.has(key(x, y))) {
          const p = []; let k = key(x, y)
          while (prev.get(k) !== null) { p.unshift(k.split(',').map(Number)); k = prev.get(k) }
          return { A, p: p.filter((q) => q[0] !== A.px || q[1] !== A.py) }
        }
        for (const d of D) {
          const nx = W(x + d[0]), ny = W(y + d[1])
          if (g.grid[nx][ny] !== 0 || prev.has(key(nx, ny))) continue
          prev.set(key(nx, ny), key(x, y)); open.push([nx, ny])
        }
      }
      return null
    }
    const cols = [...new Set(g.generators.map((x) => x.type))]
    const done = []
    cols.forEach((c, i) => {
      const pl = plan(c)
      if (!pl) return
      const last = i === cols.length - 1
      // the last colour: painted by the game, but its last cell left (the level would end)
      g.colorId = c
      g.path = [[pl.A.px, pl.A.py]]
      const cells = last ? pl.p.slice(0, Math.max(1, pl.p.length - 1)) : pl.p
      const fresh = last ? 2 : 0
      for (const q of cells.slice(0, cells.length - fresh)) if (g.colorId === c) g.paint(q[0], q[1])
      if (last) {
        // the plasma of the other cells fades out, the last two cells are painted just before the picture
        for (let i = 0; i < 40; i++) kk.updatePhysics(1000 / 32)
        for (const q of cells.slice(cells.length - fresh)) { g.paint(q[0], q[1]); for (let i = 0; i < 2; i++) kk.updatePhysics(1000 / 32) }
      }
      done.push([c, cells.length, last])
    })
    return JSON.stringify({ level: g.level, size: g.size, n, done, gens: g.generators.map((x) => [x.px, x.py, x.type]) })
  })()`)
  console.log(r)
  await b.sleep(400)
  await b.screenshot(out, { x: 8, y: 8, width: 600, height: 600 })
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
