// Opalus Factory test modes (see game.html). They only decide from the url: the same in the live game and in its
// replay.
// cov: a golden coin every <gold> coins drawn (Game.getLevel, still drawing its random), goals of at most <goal> opals
//      (Game.setGoal): golden coins, completed goals, upward rolls and level ups up to 8 come fast
TEST_MODES.cov = (P, q) => {
  const gold = +(q.get('gold') || 40), goal = +(q.get('goal') || 2)
  const gl = P.getLevel
  P.getLevel = function () {
    const r = gl.call(this)
    this.__gn = (this.__gn || 0) + 1
    return this.__gn % gold === 0 ? 8 : r
  }
  const sg = P.setGoal
  P.setGoal = function () {
    sg.call(this)
    this.goal.goal = Math.min(this.goal.goal, goal)
    this.holes[this.goal.id].field.setText(String(this.goal.goal))
  }
}
