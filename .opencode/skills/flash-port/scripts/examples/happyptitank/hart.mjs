// Happy Pti Tank start screen (public/assets/img/gfx/artwork/happyptitank.jpg, 600 x 600): a moment staged with the
// game's own display (every picture from the SWF), after the old icon of the game (a blue tank, a chain of burgers,
// flowers): the tank driven over the first coloured circles, a burger chain with its smoke coming down on it, three
// shots, the flowers of a burger destroyed, a falling missile and an option. No interface, no target (test mode
// art=1). Debug build (window.HPT: the classes).
// usage: node hart.mjs <out jpg>      env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { execFileSync } from 'node:child_process'
const out = process.argv[2]
const b = await launch(+(process.env.PORT || 9937))
const step = (n, js = '') => b.eval(`(() => { for (let i = 0; i < ${n}; i++) { ${js}; kk.updatePhysics(1000 / 32) } kk.ff.alpha = 1 })()`)
try {
  await b.goto(HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123&test=ht&art=1&inv=1&tc=5')
  await b.waitFor('!!(window.kk && kk.game && window.HPT)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  // the tank driven to x 300 (the circles of radius 64, 125 and 216 crossed: coloured), then still, up-right
  await step(130, 'const t = kk.game.tank; if (t.get_x() < 300) t.set_x(t.get_x() + 2.4)')
  await b.eval(`(() => { const t = kk.game.tank; t.angle = -Math.PI / 4; t.set_rotation(-45 - 180) })()`)
  // the mouse on the burgers (the canon aims at them): stage (215, 75) = screen (8 + 430, 8 + 150)
  await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + 430, y: 8 + 150, button: 'none', buttons: 0 })
  await step(4)
  const S = `const g = kk.game, L = g.gameLayer, t = g.tank, tx = t.get_x(), ty = t.get_y()`
  // a missile falling on the left (it lands in 30 frames: 28 frames before the picture, its feet 20 pixels above its cross)
  await b.eval(`(() => { ${S}; new HPT.XMissile(tx - 95, ty - 55) })()`)
  await step(14)
  // a burger destroyed at the bottom left: its flowers bloom
  await b.eval(`(() => { ${S}; const f = new HPT.Foe(); f.set_x(tx - 70); f.set_y(ty + 70); L.addChild(f); new HPT.EnemyDeathAnim(f) })()`)
  await step(14)
  // the burger chain coming from the top right, its smoke, three shots, an option
  await b.eval(`(() => { ${S}
    const P = [[150, -150], [128, -128], [108, -104], [92, -78], [80, -50]]
    for (let i = 0; i < P.length; i++) {
      const f = new HPT.Foe(); f.set_x(tx + P[i][0]); f.set_y(ty + P[i][1])
      const a = Math.atan2(ty - (ty + P[i][1]), tx - (tx + P[i][0])); f.set_rotation(a * 180 / Math.PI + 180); L.addChild(f)
      const s = new HPT.FoeBack(f); s.set_x(f.get_x() + 9); s.set_y(f.get_y() - 10)
    }
    for (const [d, c] of [[30, 2], [55, 5], [80, 7]]) {
      const v = { x: Math.cos(-0.82), y: Math.sin(-0.82) }, s = new HPT.Shot(v, c)
      s.set_x(tx + v.x * d); s.set_y(ty + v.y * d); s.set_rotation(-0.82 * 180 / Math.PI - 180); L.addChild(s)
    }
    const o = new HPT.OptSpeed(); o.set_x(tx + 85); o.set_y(ty + 75); L.addChild(o) })()`)
  await step(3)
  await b.sleep(300)
  const png = gameDir('happyptitank', 'art') + '/art.png'
  await b.screenshot(png, { x: 8, y: 8, width: 600, height: 600 })
  execFileSync('python3', ['-c', `from PIL import Image; Image.open('${png}').convert('RGB').save('${out}', quality=92)`])
  console.log('artwork', out)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
