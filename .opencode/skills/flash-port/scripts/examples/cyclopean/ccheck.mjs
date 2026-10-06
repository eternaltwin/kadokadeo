// pages of clips drawn by the game runtime (Game.debugShow, debug build) -> $KKP_WORK/cyclopean/check/run<i>.png, to
// compare with the SWF references of ref.py: python3 ../../tools/cmp_pages.py $KKP_WORK/cyclopean/check
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const out = process.argv[2] || gameDir('cyclopean', 'check')
const pages = JSON.parse(readFileSync(new URL('./pages.json', import.meta.url), 'utf8'))
const b = await launch(+(process.env.PORT || 9874))
try {
  for (let i = 0; i < pages.length; i++) {
    await b.goto(HOST + '/game.html?game=cyclopean&cls=GameCyclopean')
    await b.waitFor('!!(window.kk && kk.game)', 60000)
    await b.eval('kk.ff.onTick = () => {}')
    await b.eval(`kk.game.debugShow(${JSON.stringify(pages[i])}, 0x808080)`)
    await b.sleep(300)
    await b.screenshot(out + '/run' + i + '.png', { x: 8, y: 8, width: 600, height: 600 })
  }
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|unknown/i.test(l)).slice(0, 8).join('\n').slice(0, 3000))
  await b.close()
}
