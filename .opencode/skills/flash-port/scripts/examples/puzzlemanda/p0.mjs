// Puzzle-Manda smoke test: loads the game, screenshots the first level, then plays the levels by following the
// sequence (click on its first fruit, then the mouse over the next ones), a screenshot after each move.
// usage: node p0.mjs [levels] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const levels = +(process.argv[2] || 1)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9971))
const shot = (n) => b.screenshot(gameDir('puzzlemanda', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 640 })
// the sequence: positions (Flash pixels) of the fruits of the suite, in order
const PATH = `(() => { const G = GamePuzzleManda; const H = G.grid.length, W = G.grid[0].length;
  return JSON.stringify(G.suite.list.map(c => ({ x: c.x * 30 + (300 - W * 30) / 2 + 15, y: c.y * 30 + 60 + (240 - H * 30) / 2 + 15, s: c.symbol }))) })()`
const locked = () => b.eval('GamePuzzleManda.locked()')
async function waitUnlocked(ms = 8000) {
  const t0 = Date.now()
  while (await locked()) { if (Date.now() - t0 > ms) return false; await b.sleep(50) }
  return true
}
try {
  await b.goto(HOST + '/game.html?game=puzzlemanda&cls=GamePuzzleManda&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
  await b.sleep(150)
  await shot('00appear')
  await waitUnlocked()
  await shot('01level')
  for (let lv = 0; lv < levels; lv++) {
    await waitUnlocked()
    const path = JSON.parse(await b.eval(PATH))
    console.log('level', lv + 1, JSON.stringify(path))
    for (let i = 0; i < path.length; i++) {
      const p = path[i]
      await waitUnlocked()
      if (i == 0) await b.click(8 + p.x * 2, 8 + p.y * 2)
      else await b.move(8 + p.x * 2, 8 + p.y * 2)
      await b.sleep(120)
      if (lv == 0) await shot(`1${i}move`)
    }
    await b.sleep(400)
    if (lv == 0) await shot('20end')
    await b.sleep(1600)
    await shot(`3${lv}next`)
  }
  console.log(await b.eval('JSON.stringify(kk.game.debugState())'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
