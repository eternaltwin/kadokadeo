// Pacifik test mode: test=pk
//   frames=<n> the game ends at step n (gameOver = true: through the game's own code)
//   learn=<s>  Const.LEARN_STEP from the start (0..3; 2 and more: bonus balls)
//   ship=<n>   the first ship in n Flash frames (original 1440)
//   fire=<n>   Const.FIRE_CYCLE from the start (700: the canons fire every ~70-105 Flash frames)
//   full=1     12 canons on each side from the start (Game.addCanon + playStartAnim, as the replacements do)
// Only the step counter and the url decide: the same in a game and in its replay.
TEST_MODES.pk = (P, q) => {
  const orig = P.update
  const frames = +(q.get('frames') || 0), learn = q.get('learn'), ship = q.get('ship'), fire = q.get('fire'), full = q.get('full')
  P.update = function (d) {
    const C = window.__pkConst
    if (this.__n === undefined) {
      this.__n = 0
      if (learn) C.LEARN_STEP = +learn
      if (ship) this.ship_cycle = +ship
      if (fire) C.FIRE_CYCLE = +fire
      if (full) for (let i = 1; i < 12; i++) {
        this.addCanon(this.canons1); this.playStartAnim(this.canons1)
        this.addCanon(this.canons2, true); this.playStartAnim(this.canons2)
      }
    }
    this.__n++
    if (frames && this.__n === frames) this.gameOver = true
    orig.call(this, d)
  }
}
