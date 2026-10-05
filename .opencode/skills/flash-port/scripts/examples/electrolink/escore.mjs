// the scoring texts composed by the game (TextGfx, debug build) saved as pictures, to compare with ref_score.py:
//   node escore.mjs <pts>:<mult> ...   ->  $KKP_WORK/electrolink/check/score/run_<pts>_<mult>.png (+ origin.json)
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { writeFileSync } from 'node:fs'
const out = gameDir('electrolink', 'check', 'score')
const b = await launch(+(process.env.PORT || 9795))
try {
  await b.goto(HOST + '/game.html?game=electrolink&cls=GameElectrolink&seed=123')
  await b.waitFor('!!(window.kk && kk.game && kk.game.board && window.ElectrolinkTextGfx)', 60000)
  const origins = {}
  for (const a of process.argv.slice(2)) {
    const [pts, mult] = a.split(':')
    const r = JSON.parse(await b.eval(`(() => { const T = ElectrolinkTextGfx, c = T.compose(${JSON.stringify(pts)}, ${JSON.stringify(mult)})
      return JSON.stringify({ url: T.canvasOf(c).toDataURL('image/png'), x0: c.x0, y0: c.y0 }) })()`))
    writeFileSync(out + `/run_${pts}_${mult}.png`, Buffer.from(r.url.split(',')[1], 'base64'))
    origins[a] = [r.x0, r.y0]
  }
  writeFileSync(out + '/origin.json', JSON.stringify(origins))
  console.log('saved', Object.keys(origins).join(' '))
} finally { await b.close() }
