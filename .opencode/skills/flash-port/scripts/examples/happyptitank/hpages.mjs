// The pages of pages.json drawn by the game's display (debug build: window.HPT), every timeline stopped on the
// frame given (nested clips on their first frame): $KKP_WORK/happyptitank/check/run<i>.png, compared with the SWF
// renders of ref.py by tools/cmp_pages.py.
// usage: node hpages.mjs      env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const pages = JSON.parse(readFileSync(new URL('./pages.json', import.meta.url)))
const out = gameDir('happyptitank', 'check')
const b = await launch(+(process.env.PORT || 9937))
try {
  for (let pi = 0; pi < pages.length; pi++) {
    await b.goto(HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123&test=ht&art=1')
    await b.waitFor('!!(window.kk && kk.game && window.HPT)', 60000)
    await b.eval('kk.ff.onTick = function () {}')
    await b.eval(`(() => { const g = kk.game, R = g.parent; g.visible = false
      const bg = new PIXI.Graphics(); bg.beginFill(0x335566); bg.drawRect(-10, -10, 320, 340); bg.endFill(); g.stageView().addChildAt(bg, 0)
      const stopAll = (o) => { if (o.stop) o.stop(); for (const c of o.children || []) stopAll(c) }
      for (const [sid, f, x, y, sc] of ${JSON.stringify(pages[pi])}) {
        const m = new HPT.MovieClip(sid); m.gotoAndStop(f); stopAll(m)
        m.set_x(x); m.set_y(y); m.set_scaleX(sc); m.set_scaleY(sc); R.addChild(m)
      } })()`)
    await b.eval('for (let i = 0; i < 3; i++) kk.updatePhysics(1000 / 32); kk.ff.alpha = 1')
    await b.sleep(300)
    await b.screenshot(out + '/run' + pi + '.png', { x: 8, y: 8, width: 600, height: 640 })
    console.log('run' + pi)
  }
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
