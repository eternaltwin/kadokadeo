// steps a game by hand with keys held on chosen Flash-frame ranges, printing the state each step
// usage: node rep.mjs "<code>:<from step>-<to step>,..." <steps>     env: PORT, HPORT, EXTRA
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const plan = process.argv[2].split(',').map((p) => { const [c, r] = p.split(':'); const [a, z] = r.split('-').map(Number); return { c: +c, a, z } })
const N = +process.argv[3]
const b = await launch(+(process.env.PORT || 9864))
const NAMES = { 37: 'ArrowLeft', 38: 'ArrowUp', 39: 'ArrowRight', 40: 'ArrowDown', 32: 'Space' }
const ev = (type, c) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: c, nativeVirtualKeyCode: c, key: NAMES[c], code: NAMES[c] })
try {
  await b.goto(HOST + '/game.html?game=digestomax&cls=GameDigestomax&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.eval('kk.ff.onTick = function () {}')
  for (let i = 0; i < N; i++) {
    for (const p of plan) { if (p.a === i) await ev('keyDown', p.c); if (p.z === i) await ev('keyUp', p.c) }
    await b.sleep(20)
    const s = await b.eval('kk.updatePhysics(1000 / 32); JSON.stringify(kk.game.debugBot())', 5000)
    const o = JSON.parse(s)
    if (!process.env.Q || i % 10 === 0) console.log(i, o.frame, o.hx, o.hy, o.ox.toFixed(2), o.stomach.join(''), o.idle)
  }
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|unknown/i.test(l)).slice(0, 8).join('\n').slice(0, 3000))
  await b.close()
}
