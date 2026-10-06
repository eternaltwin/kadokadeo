// Cyclopean: screenshots of a game at a few frames (loading, start, playing with keys held).
// usage: HPORT=<server> node c0.mjs [devtools port] [extra url]
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const port = +(process.argv[2] || 9871)
const extra = process.argv[3] || ''
const out = gameDir('cyclopean', 'shots')
const b = await launch(port)
await b.goto(HOST + '/game.html?game=cyclopean&cls=GameCyclopean&seed=123' + extra)
await b.waitFor('!!(window.kk && kk.game)', 60000)
const frame = () => b.eval('kk.game.frameCount')
const shot = async (n) => { await b.screenshot(out + '/' + n + '.png', { x: 8, y: 8, width: 600, height: 600 }); console.log('shot', n, await frame()) }
const waitF = async (f) => { while ((await frame()) < f) await new Promise(r => setTimeout(r, 50)) }
await waitF(40); await shot('a_load')
await waitF(103); await shot('b_start')
await waitF(160); await shot('c_play')
const key = async (type, code, key) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key, code: key })
await key('keyDown', 39, 'ArrowRight')
await waitF(260); await shot('d_right')
await key('keyUp', 39, 'ArrowRight')
await key('keyDown', 37, 'ArrowLeft')
await waitF(400); await shot('e_left')
await key('keyUp', 37, 'ArrowLeft')
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH|rror/.test(l)).slice(0, 10))
console.log(await b.eval('JSON.stringify({bx: kk.game.ball.x, by: kk.game.ball.y, t: kk.game.gameTimer, out: kk.game.outList.length, el: kk.game.eList.length})'))
await b.close()
