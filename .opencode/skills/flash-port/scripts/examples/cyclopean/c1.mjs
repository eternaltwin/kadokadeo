// Cyclopean: screenshots of the end of a short game (test=cy&time=N): the glowing time gauge, the burst, the spin
// usage: HPORT=<server> node c1.mjs [devtools port] [time]
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const port = +(process.argv[2] || 9871)
const out = gameDir('cyclopean', 'shots', 'end')
const b = await launch(port)
await b.goto(HOST + '/game.html?game=cyclopean&cls=GameCyclopean&seed=123&test=cy&time=' + (process.argv[3] || 450))
await b.waitFor('!!(window.kk && kk.game)', 60000)
await b.eval('kk.ff.onTick = () => {}')
const step = (n) => b.eval(`(() => { for (let i = 0; i < ${n}; i++) kk.updatePhysics(1000 / 32); kk.render ? kk.render(kk.stage) : kk.renderer.render(kk.stage); return kk.game.frameCount })()`)
const shot = async (name) => { await b.sleep(50); await b.screenshot(out + '/' + name + '.png', { x: 8, y: 8, width: 600, height: 640 }) }
await b.waitFor("(kk.updatePhysics(1000 / 32), kk.game.step === 1 && kk.game.gameTimer < 380)", 60000)
for (const k of [0, 4, 8, 12]) { await step(k ? 4 : 1); await shot('glow' + k) }
await b.waitFor('(kk.updatePhysics(1000 / 32), kk.game.step >= 9)', 60000)
for (const k of [1, 10, 25, 45, 80, 120]) { await step(k === 1 ? 1 : 10); await shot('end' + String(k).padStart(3, '0')) }
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH|rror/.test(l)).slice(0, 10))
await b.close()
