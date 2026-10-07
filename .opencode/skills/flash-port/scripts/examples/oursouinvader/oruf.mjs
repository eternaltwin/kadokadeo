// The same key script on the original in Ruffle (ruffle/ruffle_site.sh) and on the port (harness), screenshots at the
// same moments: the run-time effects a render of the SWF cannot show (bubble bitmaps, the "VAGUE n" title, glows,
// score popups). The original's random cannot be seeded: the waves differ, the pictures are compared, not the games.
// usage: node oruf.mjs <ruffle | port> <out prefix> "<commands>"
//   commands (;): "l" / "r" / "f" hold left / right / fire, "-l" "-r" "-f" release, "w <ms>" wait, "s" screenshot
// env: RPORT (Ruffle site, default 8808), HPORT (harness), PORT (DevTools, default 9963), GPU=1 (Ruffle is slow without)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const [which, out, script] = process.argv.slice(2)
const b = await launch(+(process.env.PORT || 9963))
const K = { l: [37, 'ArrowLeft', 'ArrowLeft'], r: [39, 'ArrowRight', 'ArrowRight'], f: [32, ' ', 'Space'] }
const key = (type, [code, k, c]) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: c })
let n = 0
try {
  if (which === 'ruffle') {
    await b.goto('http://127.0.0.1:' + (process.env.RPORT || 8808) + '/ref.html?swf=ref.swf')
    await b.waitFor('!!(window.__loaded || window.__err)', 60000)
    await b.eval('window.__player.focus()')
  } else {
    await b.goto(HOST + '/game.html?game=oursouinvader&cls=GameOursouinvader&seed=123' + (process.env.EXTRA || ''))
    await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  }
  for (const c of script.split(';').map((s) => s.trim()).filter(Boolean)) {
    const [op, arg] = c.split(/\s+/)
    if (op === 's') { await b.screenshot(out + '_' + String(n++).padStart(2, '0') + '.png', { x: 8, y: 8, width: 600, height: 600 }); continue }
    if (op === 'w') { await b.sleep(+arg); continue }
    if (op[0] === '-') await key('keyUp', K[op[1]])
    else await key('keyDown', K[op])
  }
  if (which === 'ruffle') console.log(await b.eval('window.__err || "ok"'))
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|panic|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 3).join('\n').slice(0, 1500))
  await b.close()
}
