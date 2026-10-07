// Opalus Factory smoke test: loads the game, waits for the door, moves the mouse, plays a few cases (the biggest group
// next to the hero), screenshots after each step.
// usage: node o0.mjs [plays] [shots prefix]     env: PORT, HPORT, EXTRA (url params)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const plays = +(process.argv[2] || 4)
const pre = process.argv[3] || 's'
const b = await launch(+(process.env.PORT || 9871))
const shot = (n) => b.screenshot(gameDir('opalusfactory', 'shots') + `/${pre}${n}.png`, { x: 8, y: 8, width: 600, height: 600 })
const CASES = `(() => { const g = kk.game; const out = []; if (!g.getHeroCase()) return '[]';
  for (const l of g.roll) for (const c of l.line) if (g.canBePlayed(c)) { const p = g.getCasePos(c);
    out.push({ x: p.x, y: p.y, id: c.coin ? c.coin.id : -1, n: c.links ? c.links.length : 0 }) }
  return JSON.stringify(out) })()`
try {
  await b.goto(HOST + '/game.html?game=opalusfactory&cls=GameOpalusFactory&seed=123' + (process.env.EXTRA || ''))
  await b.waitFor('!!(window.kk && kk.game && kk.game.roll)', 60000)
  await b.sleep(300)
  await shot('00door')
  await b.sleep(1500)
  await shot('01start')
  for (let i = 0; i < plays; i++) {
    const cs = JSON.parse(await b.eval(CASES))
    if (!cs.length) { console.log('no case to play'); break }
    cs.sort((a, b) => b.n - a.n)
    const c = cs[0]
    await b.move(8 + c.x * 2, 8 + c.y * 2)
    await b.sleep(150)
    await shot(`1${i}hover`)
    await b.click(8 + c.x * 2, 8 + c.y * 2)
    console.log('play', JSON.stringify(c))
    await b.sleep(250)
    await shot(`2${i}move`)
    await b.sleep(1800)
    await shot(`3${i}after`)
  }
  console.log(await b.eval('JSON.stringify(kk.game.debugState())'))
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|rror|CRASH/i.test(l)); if (errs.length) console.log(errs.slice(0, 5).join('\n').slice(0, 3000))
  await b.close()
}
