// Phagocytoz start screen (public/assets/img/gfx/artwork/phagocytoz.jpg, 600 x 600): a moment staged with the game's
// own display (every picture from the SWF), after the old icon of the game (public/assets/img/games/Phagocytoz.png:
// the gold hero and its arrow, blue cells, the dark hole of the background): the hero swimming up-right (the button
// held: the arrow lit), neutral cells of several sizes around it, a hunter coming from the top right, a big cell at the
// bottom left, a score. Debug build, test mode ph (inv=1: the hero is not eaten).
// usage: node part.mjs <out jpg> [background x,y]      env: PORT (default 9954), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { execFileSync } from 'node:child_process'
const out = process.argv[2]
const [bgx, bgy] = (process.argv[3] || '-380,-230').split(',').map(Number)
const b = await launch(+(process.env.PORT || 9954))
const step = (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) { window.__hold = false; kk.updatePhysics(1000 / 32); window.__hold = true } kk.game.display(1); kk.ff.alpha = 1 })()`)
try {
  await b.goto(HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123&test=ph&inv=1')
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero && kk.game.step._hx_index === 0 && kk.game.frameCount > 130)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  // the cells around the hero: [kind (0 neutral, 1 survivor, 2 hunter), dx, dy, ray] in units of the level (the
  // screen shows +-84 around the hero at the zoom of a hero of ray 9)
  const PLACE = [[0, -66, 62, 46], [0, 52, -18, 13], [0, 74, 30, 10], [0, 18, 52, 7], [0, -52, -40, 6], [0, 62, 70, 9],
    [0, -14, -66, 5], [0, -78, -8, 8], [1, 34, -60, 6.5], [2, 82, -74, 19], [0, 30, 82, 4], [0, -30, 20, 3]]
  await b.eval(`(() => { const g = kk.game, h = g.hero
    // cells of the level placed around the hero (kind by class: Neutral, Survivor, Hunter), the others removed
    const all = g.cells.filter((c) => c !== h)
    const used = new Set()
    const K = ['Neutral', 'Survivor', 'Hunter']
    const pick = (k) => { const c = all.find((c) => !used.has(c) && c.__class__ && c.__class__.__name__.endsWith(K[k])); used.add(c); return c }
    for (const [k, dx, dy, r] of ${JSON.stringify(PLACE)}) {
      const c = pick(k); c.x = h.x + dx; c.y = h.y + dy; c.ray = r; c.baseRay = r; c.vx = 0; c.vy = 0; c.nearTimer = 1e9; c.near = []; c.draw()
    }
    // (the others removed: piled up somewhere, their bounces would multiply their speeds without end)
    for (const c of all) if (!used.has(c)) c.kill()
    h.vx = 1.2; h.vy = -0.9
    g.bg.set_x(${bgx}); g.bg.set_y(${bgy})
  })()`)
  // the button held, the mouse up-right of the hero: the arrow lit, the hero pushed that way
  await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + 245 * 2, y: 8 + 75 * 2, button: 'none', buttons: 0 })
  await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + 245 * 2, y: 8 + 75 * 2, button: 'left', buttons: 1, clickCount: 1 })
  await step(2)
  // a score (a cell of 25 just eaten), grown to its size (the McScore timeline)
  await b.eval(`(() => { const g = kk.game, h = g.hero
    const fake = (dx, dy, r) => ({ baseRay: r, sprite: { get_x: () => h.x + dx, get_y: () => h.y + dy } })
    h.scoreCell(fake(-30, -24, 8)) })()`)
  await step(9)
  // (no KadoKadeo bar under the game)
  await b.eval('if (kk.bottomBar) kk.bottomBar.visible = false')
  await b.sleep(400)
  const png = gameDir('phagocytoz', 'art') + '/art.png'
  await b.screenshot(png, { x: 8, y: 8, width: 600, height: 600 })
  execFileSync('python3', ['-c', `from PIL import Image; Image.open('${png}').convert('RGB').save('${out}', quality=92)`])
  console.log('artwork', out)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
