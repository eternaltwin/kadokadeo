// Electrolink replay seeking on a bot game: the state after a seek (forward / backward) must be the state reached by
// playing normally (game state + whole display tree), at several points (charges, falls, score popups), then the end
// of the replay must give the end state of the game.
// usage: node es1.mjs <replay file written by e3.mjs ($KKP_WORK/electrolink/replays/e_replay_<n>.txt)> [extra url params]
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data, liveOver] = readFileSync(process.argv[2], 'utf8').split('\n')
const URL0 = HOST + '/game.html?game=electrolink&cls=GameElectrolink&seed=123' + (process.argv[3] || '')
const PORT = +(process.env.PORT || 9780)
const FP = `(() => { const g = kk.game
  let n = 0, acc = 0
  const walk = (o) => { n++; const c = o._curState; if (c) acc = (acc * 31 + Math.round(c.x * 100) + 7 * Math.round(c.y * 100) + 13 * Math.round(c.rotation * 1000) + 17 * Math.round(c.alpha * 100) + 19 * Math.round(c.xscale * 1000) + (o.visible ? 1 : 0)) % 1000000007; else acc = (acc * 31 + Math.round(o.x * 100) + (o.visible ? 1 : 0) + (o.tint | 0) % 9973) % 1000000007; for (const ch of o.children) walk(ch) }
  walk(g.root.spr)
  return JSON.stringify({ f: kk.replay.getCurrentFrame(), flash: g.frameCount, score: kk.score.get(), step: g.step._hx_name, expl: g.explosionCount, start: g.mcTime.start,
    board: g.boardKey(), sprites: g.__proto__.constructor === Object ? 0 : null, popup: [g.mcScoring._currentframe, g.mcScoring._t._pts.text], nodes: n, display: acc }) })()`
const b = await launch(PORT)
const seekTo = async (f) => {
  await b.eval(`kk.seekReplay(${f})`)
  const t0 = Date.now()
  await b.waitFor('kk.seekTarget == null', 120000)
  return Date.now() - t0
}
let bad = 0
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.game.board && kk.replayHud)', 60000)
  const len = await b.eval('kk.getReplayLength()')
  console.log('length', len)
  await b.eval('kk.setReplayPaused(true)')
  // points: played normally to them, then reached again by a seek back and forth
  await b.eval('kk.setReplaySpeed(8)')
  for (const p of [0.15, 0.33, 0.5, 0.71, 0.9]) {
    const target = Math.round(len * p)
    await b.eval('kk.setReplayPaused(false)')
    await b.waitFor(`kk.replay.getCurrentFrame() >= ${target}`, 200000)
    await b.eval('kk.setReplayPaused(true)')
    const f = await b.eval('kk.replay.getCurrentFrame()')
    const played = await b.eval(FP)
    let ms = await seekTo(Math.round(f * 0.4))
    ms += await seekTo(f)
    const seeked = await b.eval(FP)
    const ok = played === seeked
    if (!ok) bad++
    console.log(ok ? 'SAME' : 'DIFFERENT', ms + 'ms', played, ok ? '' : '\n   seeked ' + seeked)
  }
  await b.eval('kk.setReplayPaused(false)')
  await b.waitFor('!!window.__over', 300000)
  const end = await b.eval('JSON.stringify(window.__over)')
  console.log('end', end === liveOver ? 'MATCH' : 'MISMATCH ' + end + ' vs ' + liveOver)
} finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|rror|CRASH/i.test(l))
  console.log('errors', errs.length, errs.slice(0, 3).join('\n').slice(0, 2000))
  await b.close()
}
