// pages of pictures drawn by the game runtime (Game.debugShow, debug build) -> $KKP_WORK/chakrebouddha/check/run<i>.png,
// to compare with the SWF references of ref.py: python3 ../../tools/cmp_pages.py $KKP_WORK/chakrebouddha/check
// usage: HPORT=8786 PORT=9871 node ncheck.mjs
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const out = process.argv[2] || gameDir('chakrebouddha', 'check')
const pages = JSON.parse(readFileSync(new URL('./pages.json', import.meta.url), 'utf8'))
const b = await launch(+(process.env.PORT || 9871))
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
try {
  for (let i = 0; i < pages.length; i++) {
    await b.goto(HOST + '/game.html?game=chakrebouddha&cls=GameChakreBouddha&seed=123')
    await b.waitFor('!!(window.kk && kk.game && kk.game.chakras)', 60000)
    // the game stopped: only the page is drawn
    await b.eval('kk.ff.onTick = () => {}')
    await b.eval(`kk.game.debugShow(${JSON.stringify(pages[i])}, 0x335566)`)
    await sleep(500)
    await b.screenshot(out + '/run' + i + '.png', { x: 8, y: 8, width: 600, height: 640 })
  }
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|unknown/i.test(l)).slice(0, 8).join('\n').slice(0, 3000))
  await b.close()
}
