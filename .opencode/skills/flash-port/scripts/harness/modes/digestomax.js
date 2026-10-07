// Digestomax test modes (see game.html). They only patch the game from counters and the url: the same in the live game
// and in its replay.
// dx: lvl=L starts at level L (the first levelUp), special=K gives every K-th random fruit (Ball.setColor(null)) a special
//     colour in turn: 4 (bigger stomach), 5 (gulp), 10..13 (flash), frames=N ends the game at Flash frame N (through
//     the game's own initGameOver: window.__over), slow=1 stops the timer while the hero plays (upc kept at 0)
TEST_MODES.dx = (P, q) => {
  const L = +(q.get('lvl') || 0), K = +(q.get('special') || 0), N = +(q.get('frames') || 0), slow = q.get('slow') === '1'
  const SPECIAL = [4, 5, 10, 11, 12, 13]
  const lvlUp = P.levelUp
  P.levelUp = function () {
    if (!this.__dx) {
      this.__dx = true
      this.__n = 0
      if (L > 1) this.lvl = L - 1
      if (K) {
        // Ball.prototype (the hero is a Piou, a Ball)
        const B = Object.getPrototypeOf(Object.getPrototypeOf(this.hero))
        const set = B.setColor
        const game = this
        B.setColor = function (col) {
          if (col == null && game.__dx && ++game.__n % K === 0) col = SPECIAL[(game.__n / K | 0) % SPECIAL.length]
          set.call(this, col)
        }
      }
    }
    lvlUp.call(this)
  }
  const ff = P.flashFrame
  P.flashFrame = function () {
    ff.call(this)
    // (Haxe binds methods with $bind: the closure keeps the function in `method`)
    if (slow && this.action && this.action.method === P.updatePlay) this.upc = 0
    if (N && this.frameCount >= N && !this.over) this.initGameOver()
  }
}
