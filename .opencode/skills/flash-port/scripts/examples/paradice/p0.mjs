// Paradice smoke test: loads the game, moves the row and validates with real key presses, screenshots every second.
// usage: node p0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9740))
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
const tap = async (code, k, ms) => { await key('keyDown', code, k); await b.sleep(ms); await key('keyUp', code, k) }
try {
  await b.goto(HOST + '/game.html?game=paradice&cls=GameParadice&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.ground)', 60000)
  for (let s = 0; s < secs; s++) {
    await b.screenshot(gameDir('paradice', 'shots') + `/${pre}${String(s).padStart(2, '0')}.png`, { x: 8, y: 8, width: 600, height: 600 })
    if (s % 3 === 0) await tap(39, 'ArrowRight', 300)
    else if (s % 3 === 1) await tap(37, 'ArrowLeft', 150)
    else await tap(38, 'ArrowUp', 100)
    await b.sleep(600)
    console.log(await b.eval('JSON.stringify({step: kk.game.step, play: kk.game.play, gstep: kk.game.ground.step, score: kk.score.get()})'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
