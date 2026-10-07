// Puzzle-Manda test modes (see game.html). They only decide from the url: the same in the live game and in its replay.
// pm: lv=<n> the game starts at level n (the bigger grids: 6 x 4 from 3, 8 x 6 from 8, 10 x 8 from 30), time=<t> the
//     time of the first level (2000 = 83 s; the next levels have 90 % of the previous one), bonus=<t> the second fruit
//     of every sequence is the bonus t (1..3: 2000, 5000, 15000 points; shown in the grid and in the sequence)
TEST_MODES.pm = (P, q) => {
  const G = window.GamePuzzleManda
  const lv = +(q.get('lv') || 1), time = +(q.get('time') || 0), bonus = +(q.get('bonus') || 0)
  const lu = P.levelUp
  P.levelUp = function () {
    if (!this.__pmStarted) {
      this.__pmStarted = true
      G.level = lv - 1
    }
    return lu.call(this)
  }
  const ic = P.initConst
  P.initConst = function () {
    ic.call(this)
    if (time && !this.__pmTime) {
      this.__pmTime = true
      G.time = time
      G.cTime = time
    }
  }
  const is = P.initSuite
  P.initSuite = function () {
    is.call(this)
    const s = G.suite
    if (bonus && s.list.length > 1) {
      const c = s.list[1]
      c.symbol = 4 + bonus
      c.mcSymbol.subGotoAndStop('symbol', c.symbol + 1)
      s.mcList[1].subGotoAndStop('symbol', c.symbol + 1)
    }
  }
}
