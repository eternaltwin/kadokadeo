// Opalus Factory start screen candidates: the game after the door (a group of the hero hovered), then shots while its
// coins fly to their hole (the points rise, blockHole sparks). The chosen one is $KKP_WORK/opalusfactory/art/<name>.png,
// written as public/assets/img/gfx/artwork/opalusfactory.jpg by opalusfactory_artwork.py.
// usage: node oart.mjs      env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9879))
const dir = gameDir('opalusfactory', 'art')
const shot = (n) => b.screenshot(dir + `/${n}.png`, { x: 8, y: 8, width: 600, height: 600 })
const CASES = `(() => { const g = kk.game; const out = [];
  for (const l of g.roll) for (const c of l.line) if (g.canBePlayed(c)) { const p = g.getCasePos(c);
    out.push({ x: p.x, y: p.y, id: c.coin ? c.coin.id : -1, n: c.links ? c.links.length : 0 }) }
  return JSON.stringify(out) })()`
try {
  await b.goto(HOST + '/game.html?game=opalusfactory&cls=GameOpalusFactory&seed=123')
  await b.waitFor('!!(window.kk && kk.game && kk.game.roll)', 60000)
  await b.sleep(2200)
  const cs = JSON.parse(await b.eval(CASES)).sort((a, b) => b.n - a.n)
  const c = cs[0]
  await b.move(8 + c.x * 2, 8 + c.y * 2)
  await b.sleep(300)
  await shot('a0')
  await b.click(8 + c.x * 2, 8 + c.y * 2)
  for (let i = 1; i <= 8; i++) { await b.sleep(90); await shot('a' + i) }
} finally {
  await b.close()
}
