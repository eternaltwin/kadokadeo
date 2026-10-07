// Pacifik: a first look. Sweeps the mouse across the stage, clicks now and then, screenshots every `every` ms into
// $KKP_WORK/pacifik/shots/p0_<n>.png, prints the exceptions.
// usage: HPORT=8811 PORT=9931 node p0.mjs [shots] [every ms] [extra url]
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const N = +(process.argv[2] || 8), EVERY = +(process.argv[3] || 1500), EXTRA = process.argv[4] || ''
const b = await launch(+(process.env.PORT || 9931))
await b.goto(HOST + '/game.html?game=pacifik&cls=GamePacifik&seed=123' + EXTRA)
await b.waitFor('!!(window.kk && kk.game && kk.game.laser)', 60000)
const dir = gameDir('pacifik', 'shots')
const t0 = Date.now()
let shot = 0, nextShot = 0, nextClick = 700
while (shot < N) {
  const t = Date.now() - t0
  if (t >= nextShot) {
    await b.screenshot(dir + '/p0_' + shot + '.png', { x: 8, y: 8, width: 600, height: 640 })
    shot++
    nextShot += EVERY
  }
  const x = 300 + 220 * Math.sin(t / 900)
  await b.move(8 + x, 8 + 300)
  if (t >= nextClick) { await b.click(8 + x, 8 + 300); nextClick += 1100 }
  if (await b.eval('!!window.__over')) break
  await new Promise(r => setTimeout(r, 25))
}
console.log('over', await b.eval('JSON.stringify(window.__over)'))
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH|rror/.test(l)).slice(0, 20).join('\n'))
await b.close()
