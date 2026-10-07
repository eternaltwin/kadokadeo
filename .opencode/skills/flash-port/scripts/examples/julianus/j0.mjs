// Julianus: screenshots of a game at a few frames (start, the hero following the mouse, blowing).
// usage: HPORT=<server> node j0.mjs [devtools port] [extra url]
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const port = +(process.argv[2] || 9871)
const extra = process.argv[3] || ''
const out = gameDir('julianus', 'shots')
const b = await launch(port)
await b.goto(HOST + '/game.html?game=julianus&cls=GameJulianus&seed=123' + extra)
await b.move(8 + 200, 8 + 300)
await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
const frame = () => b.eval('kk.game.frameCount')
const shot = async (n) => { await b.screenshot(out + '/' + n + '.png', { x: 8, y: 8, width: 600, height: 600 }); console.log('shot', n, await frame()) }
const waitF = async (f) => { while ((await frame()) < f) await new Promise(r => setTimeout(r, 20)) }
await waitF(3); await shot('a_start')
await waitF(60); await shot('b_60')
// the mouse goes behind the bubble, then blows
const st = JSON.parse(await b.eval('JSON.stringify({x: kk.game.bulles[0].px, y: kk.game.bulles[0].py})'))
await b.move(8 + (st.x - 40) * 2, 8 + st.y * 2)
await waitF(100); await shot('c_behind')
await b.mouse('mousePressed', 8 + (st.x - 40) * 2, 8 + st.y * 2)
await waitF(110); await shot('d_blow')
await waitF(160); await shot('e_blow')
await b.mouse('mouseReleased', 8 + (st.x - 40) * 2, 8 + st.y * 2)
await waitF(400); await shot('f_400')
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH|rror/.test(l)).slice(0, 10))
console.log(await b.eval('JSON.stringify({hx: kk.game.hero.px, hy: kk.game.hero.py, n: kk.game.bulles.length, pics: kk.game.pics.length, score: kk.score.get(), speed: kk.game.speed})'))
await b.close()
