// Happy Pti Tank: heap and display tree size while a game is played (arrows in a square, mouse held).
// usage: node hmem.mjs [seconds]     env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 60)
const b = await launch(+(process.env.PORT || 9937))
const KEYS = { up: [38, 'ArrowUp'], down: [40, 'ArrowDown'], left: [37, 'ArrowLeft'], right: [39, 'ArrowRight'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][1] })
const PROBE = `(() => { let n = 0; const walk = (o) => { n++; for (const c of o.children || []) walk(c) }; walk(kk.app ? kk.app.stage : kk.stage)
  let m = 0; const mw = (o) => { m++; for (const c of o.children || []) mw(c) }; mw(kk.game)
  return JSON.stringify({ heap: Math.round(performance.memory.usedJSHeapSize / 1e6), pixi: n, model: m, st: window.__state && window.__state.frame }) })()`
try {
  await b.goto(HOST + '/game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123')
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 300, y: 100, button: 'left', buttons: 1, clickCount: 1 })
  for (let s = 0; s < secs; s++) {
    const k = ['right', 'down', 'left', 'up'][Math.floor(s / 4) % 4]
    if (s % 4 === 0) { for (const kk of Object.keys(KEYS)) await key('keyUp', kk); await key('keyDown', k) }
    await b.sleep(1000)
    if (s % 5 === 4) console.log(s + 1, await b.eval(PROBE))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 2000))
  await b.close()
}
