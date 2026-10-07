// Logico test modes (see game.html). They only use the number of updates and the url: the same in the live game and
// in its replay.
// lg: frames=N ends the game at update N through the game's own code (initGameOver: the balls burst one by one, then
//     KKApi.gameOver); dif=D starts with the difficulty counter at D (colorMax grows when dif * 0.05 > colorMax^3,
//     more colours sooner); pool=P starts with P balls in the pool; chain=1 recolours the 16 balls of the start so
//     that pressing ball 0 makes a line of 4 whose removal joins two pairs into a second line (a chain: mult 3, the
//     score popup "+... x2")
TEST_MODES.lg = (P, q) => {
  const orig = P.update, frames = +(q.get('frames') || 0), dif = +(q.get('dif') || 0), pool = +(q.get('pool') || 0)
  P.update = function (d) {
    if (this.__n === undefined) {
      this.__n = 0
      if (dif) this.dif = dif
      if (pool) this.pool = pool
      if (q.get('chain')) {
        const L = [1, 2, 3, 0, 0, 1, 1, 1, 0, 0, 2, 3, 2, 3, 2, 3]
        this.balls.forEach((b, i) => b.setSkin(L[i]))
        this.buildGroups()
      }
    }
    this.__n++
    if (frames && this.__n === frames && !this.flForceDeath) this.initGameOver()
    orig.call(this, d)
  }
}
