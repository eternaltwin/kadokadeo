// Aqua Splash test modes (see game.html). They only decide from the url: the same in the live game and in its replay.
// as: map=<n> the board of another seed (the debug build always plays the seed 123 live), plays=<n> the plays at the
//     start (Cs.INIT_PLAYS, to reach the late levels), both read by Game.new; frames=N ends the game at frame N
TEST_MODES.as = (P, q) => {
  window.__aquaMap = q.get('map') ? +q.get('map') : null
  window.__aquaPlays = q.get('plays') ? +q.get('plays') : null
  const orig = P.update, N = +(q.get('frames') || 0)
  P.update = function (d) {
    if (this.__n === undefined) this.__n = 0
    orig.call(this, d)
    if (N && ++this.__n === N) kk.gameOver({})
  }
}
