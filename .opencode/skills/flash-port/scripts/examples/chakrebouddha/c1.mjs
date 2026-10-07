// Chakre Bouddha: seeking in the replay of a bot game (c3.mjs): seek to 60 %, back to 20 %, 60 % again, normal playback
// to 75 % vs a seek to the same frame (score + hash of the whole display tree, as harness/s3.mjs), then the end of the
// replay against the end of the live game.
// usage: node c1.mjs <replay file of c3.mjs> ['<url params the game was played with: &test=cb&...>']   env: PORT, HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data, liveOver] = readFileSync(process.argv[2], 'utf8').trim().split('\n')
const URL0 = HOST + '/game.html?game=chakrebouddha&cls=GameChakreBouddha&seed=123' + (process.argv[3] || '')
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
  return JSON.stringify({ f: kk.replay.getCurrentFrame(), score: document.getElementById('score').textContent, n: acc.length, h })
})()`
const b = await launch(+(process.env.PORT || 9875))
const result = {}
const seekTo = async (f) => { await b.eval(`kk.seekReplay(${f})`); const t0 = Date.now(); await b.waitFor('kk.seekTarget == null', 180000); return Date.now() - t0 }
try {
  await b.goto(URL0 + '&replay=' + encodeURIComponent(data))
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
  await b.eval('kk.setReplaySpeed(2)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor(`kk.replay.getCurrentFrame() >= ${Math.round(len * 0.75)} || !kk.replay.isPlayingReplay()`, 120000)
  await b.eval('kk.setReplayPaused(true)')
  const P = await b.eval(FP)
  const fp = JSON.parse(P).f
  await seekTo(f20)
  await seekTo(fp)
  const S = await b.eval(FP)
  result.playedVsSeek = P === S ? 'SAME' : 'DIFF ' + P + ' / ' + S
  await b.eval('kk.setReplaySpeed(8)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor('!!window.__over', 300000)
  const end = await b.eval('JSON.stringify(window.__over)')
  result.endMatch = end === liveOver ? 'MATCH' : 'MISMATCH ' + end
} finally {
  const errs = b.consoleLines.filter(l => /EXCEPTION|CRASH/i.test(l)); if (errs.length) result.errors = errs.slice(0, 2).map(e => e.slice(0, 300))
  console.log(JSON.stringify(result))
  await b.close()
}
