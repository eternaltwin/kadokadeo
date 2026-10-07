// Memopsy test modes (see game.html). They only depend on the frame counter and the url: the same in the live game
// and in its replay.
// show: the comparison page `page` (Game.debugShow), then the game is frozen (examples/memopsy/mpage.mjs, ref.py)
TEST_MODES.show = (P, q) => {
  const page = +(q.get('page') || 0)
  P.update = function (d) {
    if (!this.__shown) { this.__shown = true; this.debugShow(page) }
  }
}
