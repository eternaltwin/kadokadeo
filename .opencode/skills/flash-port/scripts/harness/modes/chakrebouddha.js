// Chakre Bouddha test mode: test=cb
//   bonus=<n>  a lit chakra is a bonus one time in n (original 70); trap=<n> a trap one time in n (original 200)
//   inv=1      the energy never goes under 120 (given back to 300 at the start of a step)
//   frames=<n> no energy left at step n (the game ends through its own code)
//   cycles=<n> Const.CYCLES (the drain period, 10)
// Only the step counter and the url decide: the same in a game and in its replay.
TEST_MODES.cb = (P, q) => {
  const orig = P.update
  const bonus = q.get('bonus'), trap = q.get('trap'), inv = q.get('inv'), frames = +(q.get('frames') || 0), cycles = q.get('cycles')
  P.update = function (d) {
    const C = window.__cbConst
    if (this.__n === undefined) {
      this.__n = 0
      if (bonus) C.BONUS_CHANCE = +bonus
      if (trap) C.TRAP_CHANCE = +trap
      if (cycles) C.CYCLES = +cycles
    }
    this.__n++
    if (inv && C.POINTS < 120 && C.POINTS > 0) C.POINTS = 300
    if (frames && this.__n === frames) C.POINTS = 0
    orig.call(this, d)
  }
}
