// clip pages drawn by the game runtime (Game.debugShow, debug build) -> $KKP_WORK/schizofuzz/check/run<i>.png, to compare
// with the SWF references of ref.py: python3 ../../tools/cmp_pages.py $KKP_WORK/schizofuzz/check
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const out = process.argv[2] || gameDir('schizofuzz', 'check')
const pages = JSON.parse(readFileSync(new URL('./pages.json', import.meta.url), 'utf8'))
const b = await launch(+(process.env.PORT || 9503))
try {
  await b.goto(HOST + '/game.html?game=schizofuzz&cls=GameSchizoFuzz')
  await b.waitFor('!!(window.kk && kk.game && window.__state)', 60000)
  for (let i = 0; i < pages.length; i++) {
    await b.eval(`kk.game.debugShow(${JSON.stringify(pages[i])}, 0x335566)`)
    await b.sleep(300)
    await b.screenshot(out + '/run' + i + '.png', { x: 8, y: 8, width: 600, height: 640 })
  }
} finally {
  console.log(b.consoleLines.filter(l => /EXCEPTION|rror|CRASH|unknown/i.test(l)).slice(0, 8).join('\n').slice(0, 3000))
  await b.close()
}
