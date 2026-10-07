// the cheeks of the hero (sprite 124: smc shown and scaled by $big) after swallowing fruits (down, n times)
import { launch } from '../../harness/cdp.mjs'
import { HOST } from '../../harness/paths.mjs'
const b = await launch(+(process.env.PORT || 9878))
const ev = (type) => b.send('Input.dispatchKeyEvent', { type, windowsVirtualKeyCode: 40, nativeVirtualKeyCode: 40, key: 'ArrowDown', code: 'ArrowDown' })
const CH = `JSON.stringify((() => { const s = kk.game.hero.skin.clip.getClip('smc'); return { big: s.big, st: kk.game.hero.stomach.join(''), same: s === kk.game.hero.skin.clip.getClip('smc'), frame: s.frame, cheeks: ['joue0', 'joue1'].map(n => { const j = s.getClip(n); const c = j && j.get('smc'); return c ? { vis: c.visible, sx: +c.scale.x.toFixed(3) } : null }) } })())`
try {
  await b.goto(HOST + '/game.html?game=digestomax&cls=GameDigestomax&seed=123')
  await b.waitFor('!!(window.kk && kk.game && window.__state && kk.game.debugBot().idle)', 60000)
  await b.sleep(500)
  console.log('start', await b.eval(CH))
  for (let i = 0; i < 2; i++) {
    await ev('keyDown'); await b.sleep(80); await ev('keyUp')
    await b.waitFor('kk.game.debugBot().idle', 10000)
    await b.sleep(200)
    console.log('after dig', i + 1, await b.eval(CH))
  }
} finally {
  await b.close()
}
