// Kanji Gaiden replay seeking (from kslash/ks1.mjs): the state after a seek (forward / backward) must be the state reached by playing
// normally (game state + whole display tree), then the end of the replay must give the end state of the game.
// usage: node ks1.mjs <replay file written by g3.mjs ($KKP_WORK/kanjigaiden/replays/g3_<n>.txt)> <extra url params of that game>
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data, liveOver] = readFileSync(process.argv[2], 'utf8').split('\n')
const URL0 = HOST + '/game.html?game=kanjigaiden&cls=GameKanjiGaiden&seed=123' + (process.argv[3] || '')
const PORT = +(process.env.PORT || 9867)
const FP = `(() => { const g = kk.game
  let n = 0, acc = 0
  const walk = (o) => { n++; const c = o._curState; if (c) acc = (acc * 31 + Math.round(c.x * 100) + 7 * Math.round(c.y * 100) + 13 * Math.round(c.rotation * 1000) + 17 * Math.round(c.alpha * 100) + 19 * Math.round(c.xscale * 1000) + (o.visible ? 1 : 0) + 23 * (o._currentframe || 0)) % 1000000007; for (const ch of o.children) walk(ch) }
  walk(g.root)
  return JSON.stringify({ f: kk.replay.getCurrentFrame(), score: kk.score.get(), pos: g.pos, sType: g.hero.sType, mons: g.monkeys.map(m => [m.pl, Math.round(m.x * 1000), Math.round(m.y * 1000)]).join(";"), shots: g.shoots.length, bonus: g.bonus.length, diff: g.diff, nodes: n, display: acc }) })()`
const b = await launch(PORT)
const seekTo = async (f) => {
  await b.eval(`kk.seekReplay(${f})`)
  const t0 = Date.now()
  await b.waitFor('kk.seekTarget == null', 120000)
  return Date.now() - t0
}
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.hero && kk.replayHud)', 60000)
  const len = await b.eval('kk.getReplayLength()')
  console.log('length', len)
  await b.eval('kk.setReplayPaused(true)')
  const a = Math.round(len * 0.6), c = Math.round(len * 0.2)
  let ms = await seekTo(a)
  const A = await b.eval(FP)
  console.log('A forward seek', ms + 'ms', A)
  ms = await seekTo(c)
  console.log('back to 20%', ms + 'ms', await b.eval(FP))
  ms = await seekTo(a)
  const B = await b.eval(FP)
  console.log('B forward again', ms + 'ms', A === B ? 'SAME' : 'DIFFERENT ' + B)
  // play normally from 60% to 75%, then reach the same frame by seeking back and forth
  await b.eval('kk.setReplaySpeed(4)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor(`kk.replay.getCurrentFrame() >= ${Math.round(len * 0.75)}`, 120000); await b.eval('kk.setReplayPaused(true)')
  const fNormal = await b.eval('kk.replay.getCurrentFrame()')
  const C = await b.eval(FP)
  ms = await seekTo(Math.round(len * 0.1)); ms += await seekTo(fNormal)
  const D = await b.eval(FP)
  console.log('C played ', C, '\nD seeked ', D, C === D ? 'SAME' : 'DIFFERENT', ms + 'ms')
  await b.eval('kk.setReplaySpeed(8)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor('!!window.__over', 300000)
  const end = await b.eval('JSON.stringify(window.__over)')
  console.log('end', end === liveOver ? 'MATCH' : 'MISMATCH ' + end + ' vs ' + liveOver)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l))
  console.log('errors', errs.length, errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
