// Hypercube test modes (see game.html). They only change the game at its first update: the same in the live game and
// in its replay.
// hc: a shorter game: the time ring starts at `time` (default 1500, Cs.TIMER_MAX = 5000: 6250 Flash frames)
TEST_MODES.hc = (P, q) => {
  const orig = P.update, time = +(q.get('time') || 1500)
  P.update = function (d) {
    if (this.__n === undefined) { this.__n = 0; this.mainTimer = time }
    this.__n++
    orig.call(this, d)
  }
}
// show: the comparison page (Game.debugShow), then the game is frozen (examples/hypercube/hshow.mjs, ref.py)
TEST_MODES.show = (P, q) => {
  P.update = function (d) {
    if (!this.__shown) { this.__shown = true; this.debugShow() }
  }
}
