// Schizo Fuzz decor planes: they scroll by whole periods (bg._x = -(scroll * speed % 500)); on every rendered picture
// their position on screen must keep moving left, the jump back by a period being instant (no slide back).
// usage: node fwrap.mjs [ms]      env: GPU=1, PORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const ms = +(process.argv[2] || 12000)
const b = await launch(+(process.env.PORT || 9872))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const tap = async (t) => { await key('keyDown', 32, ' '); await b.sleep(t); await key('keyUp', 32, ' ') }
try {
  await b.goto(HOST + '/game.html?game=schizofuzz&cls=GameSchizoFuzz&seed=123' + (process.env.JS ? '&js=' + process.env.JS : ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(500); await tap(80); await b.sleep(200); await tap(1500); await b.sleep(400); await tap(80)
  await b.eval(`(() => {
    window.__rec = []
    const r = kk.renderer.render.bind(kk.renderer)
    kk.renderer.render = function (...a) { r(...a); __rec.push(kk.game.bgs.map(m => m.clip.worldTransform.tx)) }
  })()`)
  await b.sleep(ms)
  const rec = JSON.parse(await b.eval('JSON.stringify(__rec)'))
  for (let p = 0; p < 5; p++) {
    let wraps = 0, back = 0, maxBack = 0
    for (let i = 1; i < rec.length; i++) {
      const d = rec[i][p] - rec[i - 1][p]
      if (d > 500) wraps++
      else if (d > 0.5) { back++; maxBack = Math.max(maxBack, d) }
    }
    console.log('bg_plan' + p, 'pictures', rec.length, 'wraps', wraps, '| pictures moving back', back, 'max', maxBack.toFixed(1), 'px')
  }
} finally { await b.close() }
