// The three bonuses in the port (test mode pm, bonus=1..3: the second fruit of the sequence), in the grid (cell frame 40)
// and in the sequence (blinking once the first fruit is eaten): screenshots for pbonus.py (SWF renders next to them).
// usage: node pbonus.mjs     env: PORT (default 9994), HPORT
import { launch } from '../../harness/cdp.mjs'
import { HOST, gameDir } from '../../harness/paths.mjs'
const dir = gameDir('puzzlemanda', 'check', 'bonus')
const b = await launch(+(process.env.PORT || 9994))
const POS = `(() => { const G = GamePuzzleManda; const H = G.grid.length, W = G.grid[0].length;
  return JSON.stringify(G.suite.list.map(c => ({ x: c.x * 30 + (300 - W * 30) / 2 + 15, y: c.y * 30 + 60 + (240 - H * 30) / 2 + 15 }))) })()`
try {
  for (const t of [1, 2, 3]) {
    await b.goto(HOST + '/game.html?game=puzzlemanda&cls=GamePuzzleManda&seed=123&test=pm&bonus=' + t)
    await b.waitFor('!!(window.kk && kk.game && GamePuzzleManda.suite)', 60000)
    await b.waitFor('!GamePuzzleManda.locked()', 20000)
    const p = JSON.parse(await b.eval(POS))
    await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + 20, y: 8 + 560, button: 'none', buttons: 0 })
    await b.screenshot(`${dir}/b${t}_grid.png`, { x: 8, y: 8, width: 600, height: 600 })
    console.log(t, JSON.stringify(p[1]))
    // eat the first fruit: the bonus of the sequence blinks
    const q = p[0]
    await b.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 8 + q.x * 2, y: 8 + q.y * 2, button: 'none', buttons: 0 })
    await b.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 8 + q.x * 2, y: 8 + q.y * 2, button: 'left', buttons: 1, clickCount: 1 })
    await b.sleep(60)
    await b.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 8 + q.x * 2, y: 8 + q.y * 2, button: 'left', buttons: 0, clickCount: 1 })
    await b.waitFor('!GamePuzzleManda.locked()', 20000)
    for (let i = 0; i < 4; i++) { await b.sleep(90); await b.screenshot(`${dir}/b${t}_blink${i}.png`, { x: 8, y: 8, width: 600, height: 600 }) }
  }
} finally { await b.close() }
