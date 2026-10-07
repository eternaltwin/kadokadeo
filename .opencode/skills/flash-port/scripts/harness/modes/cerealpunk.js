// Cereal Punk test modes (see game.html). They only patch the game from counters and the url: the same in the live game
// and in its replay.
// cp: rare=K makes every K-th new cereal a stone, a gold cereal or a bubble in turn (randId still draws its random
//     numbers); hold=N keeps the game going until Flash frame N whatever the height (the columns can be filled up to the
//     top: cereals thrown on a full column fly away, Game.hscombo); frames=N ends the game at Flash frame N (through
//     the game's own end: the grid is destroyed, then window.__over); maxtime=M: the time between two new rows starts at
//     M instead of 15 (the columns fill up quickly); setup=a: the grid of scenario a at the start (no new row): column 3
//     (the cook's) ends with 0 0 1, column 4 is full but its top cell, under it 0 0, column 5 has a 5000 bonus next to
//     them, column 2 a 5000 bonus on its own. Up, right, down: the first 0 thrown completes the 0 0 0 (the bonus next to
//     it is destroyed), the second flies away and is kept in that combo; left, left, up: the bonus is taken
//     (with hold=N: the full column would end the game)
TEST_MODES.cp = (P, q) => {
  const rare = +(q.get('rare') || 0), hold = +(q.get('hold') || 0), N = +(q.get('frames') || 0), mt = +(q.get('maxtime') || 0), setup = q.get('setup')
  const origRand = P.randId
  P.randId = function () {
    const id = origRand.call(this)
    this.__rare = (this.__rare || 0) + 1
    if (rare && this.__rare % rare === 0) {
      const k = (this.__rare / rare) % 3
      return k === 0 ? 21 : k === 1 ? 9 + (this.__rare % 3) : 20
    }
    return id
  }
  const origMain = P.main
  P.main = function () {
    if (setup && !this.__setup) {
      this.__setup = true
      const lv = this.level, L = Object.getPrototypeOf(lv.legumes[0][11]).__class__
      for (let x = 0; x < 8; x++) for (let y = 0; y < 12; y++) { const l = lv.legumes[x][y]; if (l) l.mc.removeMovieClip(); lv.legumes[x][y] = null }
      this.animator.ups = []
      const put = (x, y, id) => { lv.legumes[x][y] = new L(this, id, x, y) }
      if (setup === 'a') {
        put(3, 9, 0); put(3, 10, 0); put(3, 11, 1)
        put(4, 1, 0); put(4, 2, 0)
        for (let y = 3; y < 12; y++) put(4, y, 1 + (y & 1))
        put(5, 1, 23); for (let y = 2; y < 12; y++) put(5, y, 1 + (y & 1))
        put(2, 11, 23)
      }
      this.maxtime = this.time = 100000
    }
    if (mt && this.frameCount === 0 && this.maxtime === 15) { this.maxtime = mt; this.time = mt }
    if (hold && this.frameCount < hold) this.game_over = false
    if (N && this.frameCount >= N) this.game_over = true
    origMain.call(this)
  }
}
