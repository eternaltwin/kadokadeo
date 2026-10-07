// Pacifik: screenshots of a replay at given steps (seek, pause, shot) into $KKP_WORK/pacifik/shots/<prefix>_<step>.png.
// usage: HPORT=8811 PORT=9938 node pshots.mjs <replay file> <extra url> <prefix> <step>...
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [file, extra, prefix, ...steps] = process.argv.slice(2)
const data = readFileSync(file, 'utf8').split('\n')[0]
const b = await launch(+(process.env.PORT || 9938))
try {
  // NOCACHE=1: the canons drawn on the stage (no cache, see Gfx.CanonMC)
  if (process.env.NOCACHE) await b.send('Page.addScriptToEvaluateOnNewDocument', { source: 'window.__pkNoCache = true' })
  await b.goto(HOST + '/game.html?game=pacifik&cls=GamePacifik&seed=123' + extra + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.laser && kk.replayHud)', 60000)
  await b.eval('kk.setReplayPaused(true)')
  for (const s of steps) {
    await b.eval(`kk.seekReplay(${+s})`)
    await b.waitFor('kk.seekTarget == null', 120000)
    await b.sleep(300)
    // NOHUD=1: the game alone (no replay controls, no score bar): start screen pictures
    if (process.env.NOHUD) await b.eval('(() => { let o = kk.game.root.spr; while (o.parent) { for (const c of o.parent.children) if (c !== o) c.visible = false; o = o.parent } })()')
    await b.screenshot(gameDir('pacifik', 'shots') + '/' + prefix + '_' + s + '.png', { x: 8, y: 8, width: 600, height: 600 })
  }
  console.log(b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l)).slice(0, 3).join('\n'))
} finally {
  await b.close()
}
