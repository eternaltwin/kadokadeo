// Klinker Surprise test modes (see game.html). They only decide from the url: the same in the live game and in its
// replay.
// ks: map=<n>: the grids of another seed (the debug build always plays the seed 123 live), read by Game.new;
//     timer=N: the time of each level capped at N (the game ends sooner, from level 2: level 1 has no time limit);
//     frames=N: the game ends at step N (like generic)
TEST_MODES.ks = (P, q) => {
  if (q.get('map')) window.__ksMap = +q.get('map')
  const T = +(q.get('timer') || 0), N = +(q.get('frames') || 0)
  const oz = P.initZone
  P.initZone = function () {
    oz.call(this)
    if (T && this.levelTimer > T) this.levelTimer = T
  }
  const ou = P.update
  P.update = function (d) {
    if (this.__n === undefined) this.__n = 0
    ou.call(this, d)
    if (N && ++this.__n === N) kk.gameOver({})
  }
}
