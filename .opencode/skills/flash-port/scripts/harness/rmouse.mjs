// live game with smooth mouse moves (like a hand) and some keys / clicks, then its replay: same end score?
//   node rmouse.mjs <game> <Class> <frames> <out file>
import fs from 'fs'
import { launch } from './cdp.mjs'
const [pkg, cls, frames, out] = process.argv.slice(2)
const URL0 = `http://127.0.0.1:${process.env.HPORT || 8765}/game.html?game=${pkg}&cls=${cls}&test=generic&frames=${frames}`
let rs = 5
const rnd = () => { rs = (rs * 1103515245 + 12345) & 0x7fffffff; return (rs >> 8) / 8388608 }
let b = await launch(+(process.env.PORT || 9395))
const mouse = (type, x, y, buttons = 0) => b.send('Input.dispatchMouseEvent', { type, x: 8 + x, y: 8 + y, button: type === 'mouseMoved' ? 'none' : 'left', buttons, clickCount: 1 })
const key = (type, code, k) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, key: k, code: k })
let data, live
try {
  await b.goto(URL0)
  await b.waitFor('!!(window.kk && kk.game)', 60000)
  let x = 300, y = 300
  while (!(await b.eval('!!window.__logs.find(l => l.includes("Replay data:"))'))) {
    const tx = 30 + rnd() * 540, ty = 60 + rnd() * 500, n = 15 + Math.floor(rnd() * 40)
    const sx = x, sy = y
    for (let i = 1; i <= n; i++) {
      const t = i / n, e = t * t * (3 - 2 * t)
      x = sx + (tx - sx) * e + (rnd() - 0.5) * 1.5; y = sy + (ty - sy) * e + (rnd() - 0.5) * 1.5
      await mouse('mouseMoved', Math.round(x), Math.round(y)); await b.sleep(16)
    }
    if (rnd() < 0.5) { await mouse('mousePressed', Math.round(x), Math.round(y), 1); await b.sleep(60); await mouse('mouseReleased', Math.round(x), Math.round(y)) }
    if (rnd() < 0.3) { await key('keyDown', 32, 'Space'); await b.sleep(80); await key('keyUp', 32, 'Space') }
    await b.sleep(Math.floor(rnd() * 300))
  }
  live = await b.eval(`document.getElementById('score').textContent`)
  data = (await b.eval(`window.__logs.find(l => l.includes("Replay data:"))`)).split('Replay data: ')[1].trim()
} finally { await b.close() }
b = await launch(+(process.env.PORT || 9395))
try {
  await b.goto(URL0 + '&seed=123&replay=' + encodeURIComponent(data))
  await b.waitFor('!!(window.kk && kk.game && kk.replay.isPlayingReplay())', 60000)
  await b.eval('kk.setReplaySpeed(8)')
  await b.waitFor('kk.gameOverScreen != null || kk.game == null', 300000)
  const end = await b.eval(`document.getElementById('score').textContent`)
  console.log(pkg, 'live', live, 'replay', end, end === live ? 'MATCH' : 'MISMATCH', 'chars', data.length)
  fs.writeFileSync(out, data + '\n')
} finally { await b.close() }
