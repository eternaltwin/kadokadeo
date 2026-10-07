// Toy Maniak test modes (see game.html). They only depend on the frame counter and the url: the same in the live game
// and in its replay.
// show: the comparison page `page` (Game.debugShow), then the game is frozen (examples/toymaniak/tpage.mjs, ref.py)
TEST_MODES.show = (P, q) => {
  const page = +(q.get('page') || 0)
  P.update = function (d) {
    if (!this.__shown) { this.__shown = true; this.debugShow(page) }
  }
}
// cov: what a random game rarely reaches (examples/toymaniak/t3.mjs with EXTRA='&test=cov&...'):
//   every=N: a bonus every N steps (Rail.next, rails and kinds in turn: +20, speed, x2), toy3=F: the rare picture of
//   the 4th kind (Toy.TOYS[3]: 3, 10 or 11), time=T: the game starts at T s (of 100), combo=C: the rails start with
//   C combos (the 199 limit)
TEST_MODES.cov = (P, q) => {
  const orig = P.update, every = +(q.get('every') || 0), toy3 = q.get('toy3'), time = +(q.get('time') || 0), combo = q.get('combo')
  P.update = function (d) {
    if (this.__n === undefined) {
      this.__n = 0
      if (toy3) window.ToyManiakToy.TOYS[3] = +toy3
      if (time) this.time = time
      if (combo) this.rails.forEach((r) => { r.ncombos = +combo })
    }
    this.__n++
    if (every && this.__n % every === 0) {
      const k = this.__n / every
      this.rails[k % 3].next = 4 + (Math.floor(k / 3) % 3)
    }
    orig.call(this, d)
  }
}
