// Cyclopean start screen (public/assets/img/gfx/artwork/cyclopean.jpg, 600x600): the game drawing a scene set up in
// the page (debug build): the start of a game in the pentacle, a few bonuses and balls around the chick, the
// sparkles of the start, without the minimap and the time gauge.
// usage: HPORT=<server> node c4.mjs <out.jpg> [devtools port]
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { execFileSync } from 'node:child_process'
import { writeFileSync } from 'node:fs'
const out = process.argv[2]
const b = await launch(+(process.argv[3] || 9886))
await b.goto(HOST + '/game.html?game=cyclopean&cls=GameCyclopean&seed=123')
await b.waitFor('!!(window.kk && kk.game)', 60000)
await b.eval('kk.ff.onTick = () => {}')
await b.eval(`(() => { while (kk.game.step !== 1) kk.updatePhysics(1000 / 32)
  const g = kk.game, E = g.eList[0].__proto__.__class__, C = 800
  // bonuses on free spots around the chick: gems, time, eggs
  const put = [[0, -95, -30], [1, 70, -75], [2, 105, 40], [3, -60, 85], [4, -110, 15], [4, 30, 105], [0, 125, -15]]
  for (const [id, dx, dy] of put) { const e = new E(C + dx, C + dy, id); if (id === 4) e.sid = dx < 0 ? 2 : 5 }
  for (const [c, dx, dy] of [[2, -35, -40], [5, 40, -30], [7, 20, 45]]) { const bl = g.genBille(C + dx, C + dy); bl.setColor(c) }
  g.minimap.spr.visible = false; g.mcInter.spr.visible = false
  for (let i = 0; i < 12; i++) kk.updatePhysics(1000 / 32)
  g.minimap.spr.visible = false; g.mcInter.spr.visible = false })()`)
await b.sleep(300)
// the game's display only (not the bar of KadoKadeo under it), 600 x 600
const data = await b.eval(`(() => { const r = kk.renderer, rt = PIXI.RenderTexture.create({ width: 600, height: 600, resolution: 1 })
  kk.game.root.spr.updateGraphics(1); r.render(kk.game.root.spr, { renderTexture: rt, clear: true })
  const d = r.extract.base64(rt); rt.destroy(true); return d })()`)
const png = out.replace(/\.jpg$/, '.png')
writeFileSync(png, Buffer.from(data.split(',')[1], 'base64'))
execFileSync('python3', ['-c', `from PIL import Image; Image.open('${png}').convert('RGB').save('${out}', quality=92)`])
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH|rror/.test(l)).slice(0, 5))
await b.close()
