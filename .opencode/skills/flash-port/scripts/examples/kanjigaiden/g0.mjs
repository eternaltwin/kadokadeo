// Kanji Gaiden smoke test: loads the game, turns left and right, throws, screenshots every half second.
// usage: node g0.mjs [seconds] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const secs = +(process.argv[2] || 8)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9861))
const KEYS = { space: [32, ' ', 'Space'], left: [37, 'ArrowLeft', 'ArrowLeft'], right: [39, 'ArrowRight', 'ArrowRight'] }
const key = (type, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: KEYS[k][0], nativeVirtualKeyCode: KEYS[k][0], key: KEYS[k][1], code: KEYS[k][2] })
const shot = (n) => b.screenshot(gameDir('kanjigaiden', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
try {
  await b.goto(HOST + '/game.html?game=kanjigaiden&cls=GameKanjiGaiden&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  await b.sleep(600)
  await shot('00start')
  console.log(await b.eval('JSON.stringify(window.__state)'))
  for (let s = 0; s < secs * 2; s++) {
    if (s % 6 === 0) await key('keyDown', 'space')
    if (s % 6 === 2) await key('keyUp', 'space')
    if (s % 8 === 3) await key('keyDown', s % 16 < 8 ? 'left' : 'right')
    if (s % 8 === 5) { await key('keyUp', 'left'); await key('keyUp', 'right') }
    await b.sleep(500)
    await shot(String(s + 10))
    console.log(await b.eval('JSON.stringify(window.__state)'))
  }
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
