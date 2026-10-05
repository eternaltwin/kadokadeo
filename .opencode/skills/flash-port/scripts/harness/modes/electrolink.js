// Electrolink test modes (see game.html). They only change constants at the first update: the same in the live game
// and in its replay.
// el: a shorter game (Cs.PLAY_TIME = time ms, default 30000), ended by the game itself (time out)
TEST_MODES.el = (P, q) => {
  const orig = P.update, time = +(q.get('time') || 30000)
  P.update = function (d) {
    if (this.__n === undefined) { this.__n = 0; window.ElectrolinkCs.PLAY_TIME = time }
    this.__n++
    orig.call(this, d)
  }
}
