// Hexile test modes (see game.html). They only decide from the url: the same in the live game and in its replay.
// map: the island of another seed (map=<n>; the debug build always plays the seed 123 live), read by Game.new;
//      frames=N also ends the game at frame N (like generic)
TEST_MODES.map = (P, q) => {
  window.__hexileMap = +(q.get('map') || 1)
  const orig = P.update, N = +(q.get('frames') || 0)
  P.update = function (d) {
    if (this.__n === undefined) this.__n = 0
    orig.call(this, d)
    if (N && ++this.__n === N) kk.gameOver({})
  }
}
