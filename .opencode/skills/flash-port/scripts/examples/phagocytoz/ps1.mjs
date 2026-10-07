// Phagocytoz: seeks in a replay saved by p3.mjs (replays/p3_<seed>.txt: data, then the live end state), like
// harness/s3.mjs: to 60 %, back to 20 %, 60 % again (same display), normal playback to 75 % vs a seek to the same frame,
// then the end of the replay (same end state as the live game).
// usage: node ps1.mjs <replay file>     env: PORT (default 9878), HPORT, EXTRA (the url parameters of the live game)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
import { readFileSync } from 'node:fs'
const [data, liveOver] = readFileSync(process.argv[2], 'utf8').split('\n')
const b = await launch(+(process.env.PORT || 9878))
const result = { file: process.argv[2].split('/').pop() }
// the display: every PIXI object of the game (state, frame, visibility, text)
const FP = `(() => {
  const acc = []
  const walk = (o) => { for (const c of o.children || []) {
    const s = c._curState
    if (s) acc.push([s.x, s.y, s.rotation, s.xscale, s.yscale, s.alpha].map(v => Math.round(v * 100)).join(',') + (c.visible ? 'v' : 'h'))
    else acc.push([c.x, c.y, c.scale ? c.scale.x : 1].map(v => Math.round(v * 100)).join(',') + (c.visible ? 'v' : 'h') + (c.texture && c.texture.textureCacheIds ? c.texture.textureCacheIds[0] : ''))
    walk(c) } }
  if (kk.gameRoot) walk(kk.gameRoot)
  let h = 2166136261; const str = acc.join('|')
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 }
  return JSON.stringify({ f: kk.replay.getCurrentFrame(), score: document.getElementById('score').textContent, n: acc.length, h })
})()`
const seekTo = async (f) => {
  await b.eval(`kk.seekReplay(${f})`)
  const t0 = Date.now()
  await b.waitFor('kk.seekTarget == null', 180000)
  return Date.now() - t0
}
try {
  await b.goto(HOST + '/game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123' + (process.env.EXTRA || '') + '&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.replayHud)', 60000)
  await b.eval('kk.setReplayPaused(true)')
  const len = await b.eval('kk.getReplayLength()')
  result.length = len
  const f60 = Math.round(len * 0.6), f20 = Math.round(len * 0.2)
  result.seek60ms = await seekTo(f60)
  await b.sleep(200)
  const A = await b.eval(FP)
  result.back20ms = await seekTo(f20)
  await seekTo(f60)
  await b.sleep(200)
  const C = await b.eval(FP)
  result.again60 = A === C ? 'SAME' : 'DIFF ' + A + ' / ' + C
  await b.eval('kk.setReplaySpeed(4)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor(`kk.replay.getCurrentFrame() >= ${Math.round(len * 0.75)} || !kk.replay.isPlayingReplay()`, 300000)
  await b.eval('kk.setReplayPaused(true)')
  await b.sleep(200)
  const P = await b.eval(FP)
  const fp = JSON.parse(P).f
  await seekTo(f20)
  await seekTo(fp)
  await b.sleep(200)
  const S = await b.eval(FP)
  result.playedVsSeek = P === S ? 'SAME' : 'DIFF ' + P + ' / ' + S
  await b.eval('kk.setReplaySpeed(8)'); await b.eval('kk.setReplayPaused(false)')
  await b.waitFor('!!window.__over', 600000)
  const rep = await b.eval('JSON.stringify(window.__over)')
  result.endMatch = rep === liveOver ? 'MATCH' : 'MISMATCH ' + rep + ' / ' + liveOver
} catch (e) { result.error = e.message.slice(0, 300) }
finally {
  const errs = b.consoleLines.filter((l) => /EXCEPTION|CRASH/i.test(l))
  if (errs.length) result.errors = errs.slice(0, 2).map((e) => e.slice(0, 300))
  await b.close()
}
console.log(JSON.stringify(result))
