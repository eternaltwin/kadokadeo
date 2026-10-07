// Chakre Bouddha: a first look. Plays a game with a click on every lit chakra (reaction of `delay` ms), screenshots
// every `every` ms into $KKP_WORK/chakrebouddha/shots/c0_<n>.png, prints the exceptions.
// usage: HPORT=8786 PORT=9861 node c0.mjs [shots] [every ms] [delay ms]
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const N = +(process.argv[2] || 8), EVERY = +(process.argv[3] || 1500), DELAY = +(process.argv[4] || 150)
const b = await launch(+(process.env.PORT || 9861))
await b.goto(HOST + '/game.html?game=chakrebouddha&cls=GameChakreBouddha&seed=123')
await b.waitFor('!!(window.kk && kk.game && kk.game.chakras)', 60000)
const dir = gameDir('chakrebouddha', 'shots')
const t0 = Date.now()
let shot = 0, nextShot = 0
const active = `(() => { const g = kk.game; const s = g.activatedStep; if (s == null || g.chakraLock) return -1; return s._hx_index; })()`
let seen = -1, seenAt = 0
while (shot < N) {
  const t = Date.now() - t0
  if (t >= nextShot) {
    await b.screenshot(dir + '/c0_' + shot + '.png', { x: 8, y: 8, width: 600, height: 640 })
    shot++
    nextShot += EVERY
  }
  const a = await b.eval(active)
  if (a >= 0 && a !== seen) { seen = a; seenAt = Date.now() }
  if (a >= 0 && Date.now() - seenAt >= DELAY) { await b.click(8 + 300, 8 + 300); seen = -1 }
  if (await b.eval('!!window.__over')) break
  await new Promise(r => setTimeout(r, 20))
}
console.log('over', await b.eval('JSON.stringify(window.__over)'))
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH|rror/.test(l)).slice(0, 20).join('\n'))
await b.close()
