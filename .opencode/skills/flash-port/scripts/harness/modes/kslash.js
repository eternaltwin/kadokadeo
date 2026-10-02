// K-Slash test modes (loaded by game.html for game=kslash). Each must do exactly the same thing in the live game and
// in its replay: only the frame counter and the url parameters decide.
// test=ks  coverage: difficulty from the start (dif=), a bonus given on the hero every `every` frames (ids=1,2,...),
//          immortal hero (inv=1), game over at frame N (frames=)
//   e.g. game.html?game=kslash&cls=GameKSlash&seed=123&test=ks&dif=6000&ids=4,5,6,7,8,9&inv=1&frames=3000
TEST_MODES.ks = (P, q) => {
  const orig = P.update, N = +(q.get('frames') || 3000), D = +(q.get('dif') || 0)
  const ids = (q.get('ids') || '').split(',').filter(Boolean).map(Number), inv = q.get('inv') === '1', every = +(q.get('every') || 120)
  P.update = function (d) {
    const h = this.hero
    if (this.__n === undefined) {
      this.__n = 0; this.dif = D
      if (inv) { const oi = h.initStep; h.initStep = function (n) { if (n !== 3) oi.call(this, n) } }
    }
    // (Haxe properties are read through their getters from JS: root.get__x())
    if (ids.length && this.__n % every === every / 2) this.spawnBonus(h.root.get__x(), h.root.get__y(), ids[(this.__n / every | 0) % ids.length])
    orig.call(this, d)
    if (++this.__n === N) this.gameOver()
  }
}
