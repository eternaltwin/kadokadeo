// Spiroule smoke test: loads the game, aims around, shoots a few balls at the chain, screenshots after each step.
// usage: node p0.mjs [shots] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const n = +(process.argv[2] || 4)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9971))
const shot = (s) => b.screenshot(gameDir('spiroule', 'shots') + `/${pre}${s}.png`, { x: 8, y: 8, width: 600, height: 600 })
try {
  await b.goto(HOST + '/game.html?game=spiroule&cls=GameSpiroule&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.chains)', 60000)
  await b.move(8 + 400, 8 + 300)
  await b.sleep(400)
  await shot('00start')
  await b.sleep(2500)
  await shot('01run')
  for (let i = 0; i < n; i++) {
    // aim at the last ball of the first chain
    const t = JSON.parse(await b.eval(`(() => { const c = kk.game.chains[0]; const bl = c.list[c.list.length - 1]; return JSON.stringify({x: bl.x, y: bl.y}) })()`))
    await b.move(8 + t.x * 2, 8 + t.y * 2)
    await b.sleep(120)
    await b.click(8 + t.x * 2, 8 + t.y * 2)
    await b.sleep(200)
    await shot(`1${i}fly`)
    await b.sleep(900)
    await shot(`2${i}after`)
  }
  console.log(await b.eval('JSON.stringify(kk.game.debugState())'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
