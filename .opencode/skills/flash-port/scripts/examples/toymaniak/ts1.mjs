// Toy Maniak: seeking in the replay of a bot game (t3.mjs writes $KKP_WORK/toymaniak/replays/t_replay_<seed>.txt: the
// replay data, then the live end state): the checks of harness/s3.mjs (seek 60 % / back to 20 % / 60 % again, normal
// playback to 75 % vs seek to the same frame, the end of the replay) on a real game, plus the game's own end state.
// usage: node ts1.mjs <replay file>      env: PORT (DevTools, 9967), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data, liveOver] = readFileSync(process.argv[2], 'utf8').trim().split('\n')
const result = {}
const FP = `(() => {
  const acc = []
  const walk = (o) => { for (const c of o.children || []) {
    const s = c._curState
    if (s) acc.push([s.x, s.y, s.rotation, s.xscale, s.yscale, s.alpha].map(v => Math.round(v * 100)).join(',') + ',' + (c._currentframe | 0) + (c.visible ? 'v' : 'h'))
    else acc.push([c.x, c.y].map(v => Math.round(v * 100)).join(',') + (c.visible ? 'v' : 'h'))
    walk(c) } }
  if (kk.gameRoot) walk(kk.gameRoot)
  let h = 2166136261; const str = acc.join('|')
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 }
  return JSON.stringify({ f: kk.replay.getCurrentFrame(), score: document.getElementById('score').textContent, n: acc.length, h,
    st: JSON.stringify(kk.game.debugState()) })
})()`
const b = await launch(+(process.env.PORT || 9967))
const seekTo = async (f) => {
  await b.eval(`kk.seekReplay(${f})`)
  const t0 = Date.now()
  await b.waitFor('kk.seekTarget == null', 180000)
  return Date.now() - t0
}
try {
  await b.goto(HOST + '/game.html?game=toymaniak&cls=GameToyManiak&seed=123&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.replayHud)', 60000)
  await b.eval('kk.setReplayPaused(true)')
  const len = await b.eval('kk.getReplayLength()')
  result.length = len
  const f60 = Math.round(len * 0.6), f20 = Math.round(len * 0.2)
  result.seek60ms = await seekTo(f60)
  const A = await b.eval(FP)
  result.back20ms = await seekTo(f20)
  await seekTo(f60)
  const C = await b.eval(FP)
  result.again60 = A === C ? 'SAME' : 'DIFF ' + A + ' / ' + C
  await b.eval('kk.setReplaySpeed(4)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor(`kk.replay.getCurrentFrame() >= ${Math.round(len * 0.75)} || !kk.replay.isPlayingReplay()`, 300000)
  await b.eval('kk.setReplayPaused(true)')
  const P = await b.eval(FP)
  const fp = JSON.parse(P).f
  await seekTo(f20)
  await seekTo(fp)
  const S = await b.eval(FP)
  result.playedVsSeek = P === S ? 'SAME' : 'DIFF ' + P + ' / ' + S
  await b.eval('kk.setReplaySpeed(8)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor('!!window.__over', 300000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  result.endMatch = rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep
} catch (e) { result.error = e.message.slice(0, 300) }
finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|CRASH/i.test(l))
  if (errs.length) result.errors = errs.slice(0, 2).map(e => e.slice(0, 300))
  await b.close()
}
console.log(JSON.stringify(result))
