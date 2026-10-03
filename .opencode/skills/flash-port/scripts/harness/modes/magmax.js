// Magmax test modes (see game.html). They only patch the game from the frame counter and the url: the same in the
// live game and in its replay.
// mx: coverage. lvl=L: the level from the start (firebombs only below 10, then heliflowers, cyblocks from 30);
//     inv=1: the hero cannot die before frame N (frames=N), where the game's own gameOver runs (death, then
//     KKApi.gameOver); bon=1: the bonuses dropped cycle through the 5 types (points x3, speed, power)
TEST_MODES.mx = (P, q) => {
  const orig = P.update, origGO = P.gameOver
  const lvl = +(q.get('lvl') || 0), inv = q.get('inv') === '1', N = +(q.get('frames') || 0), bon = q.get('bon') === '1'
  P.gameOver = function () { if (inv && this.frameCount < N) return; origGO.call(this) }
  P.update = function (d) {
    if (this.__k === undefined) { this.__k = 0; if (lvl) this.level = lvl }
    orig.call(this, d)
    if (bon) for (const b of this.bonus) if (!b.__cov) { b.__cov = 1; b.t = this.__k++ % 5; b.gotoAndStop(b.t + 1) }
    if (inv && N && this.frameCount >= N && !this.game_over) origGO.call(this)
  }
}
