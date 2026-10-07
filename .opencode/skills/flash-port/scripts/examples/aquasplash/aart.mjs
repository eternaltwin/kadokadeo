// Aqua Splash: the start screen (public/assets/img/gfx/artwork/aquasplash.jpg) is a moment of a chain staged in the
// game itself (debug build): a board of big slimes, a chain started at (2, 3), one picture every 3 Flash frames
// (f<frame>.png); the one kept was f42.png, saved as a 600 x 600 jpg (quality 90).
// usage: node aart.mjs <out prefix>     env: HPORT, PORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const out = process.argv[2]
const b = await launch(+(process.env.PORT || 9969))
try {
  await b.goto(HOST + '/game.html?game=aquasplash&cls=GameAquaSplash&seed=123')
  await b.waitFor('!!(window.kk && kk.game && kk.game.mcTime)', 60000)
  await b.sleep(400)
  const G = '4342143414241434443442243434134422434'
  await b.eval(`kk.ff.onTick = function () {}; const g = kk.game; const G = '${G}';
    g.allSlimes.forEach((s, i) => { s.growTo(+G[i]) });
    g.mcPlays.forEach((m, i) => m.gotoAndStop(i < 9 ? 2 : 1)); g.plays = 9;
    g.debugFrames(12);
    const s = g.allSlimes.find(s => s.pos.x === 2 && s.pos.y === 3); s.grow = 5; g.initSploutch(s); kk.ff.alpha = 1`)
  for (let i = 0; i < 8; i++) {
    await b.eval('kk.game.debugFrames(3); kk.ff.alpha = 1')
    await b.sleep(150)
    await b.screenshot(out + (await b.eval('kk.game.frameCount')) + '.png', { x: 8, y: 8, width: 600, height: 600 })
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
