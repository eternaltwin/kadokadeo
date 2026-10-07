// Julianus test modes (see game.html). They only act on the frame counter and the url: the same in the live game
// and in its replay.
// ju: frames=N: every bubble removed at Flash frame N (the game ends through its own main(): no bubble left);
//     pcount=N: the pics generated so far set to N on the first step (the spinning spikes come after 20, the orbits
//     after 50); delta=X: speed_delta set to X on the first step (the late game: faster scroll, stronger blow);
//     bubbles=N: N more bubbles dropped by the game's own genBulle() on the first step (fusions and splits)
TEST_MODES.ju = (P, q) => {
  const orig = P.update, N = +(q.get('frames') || 0), PC = q.get('pcount'), SD = q.get('delta'), NB = +(q.get('bubbles') || 0)
  P.update = function (d) {
    if (!this.__ju) {
      this.__ju = true
      if (PC) this.pcount = +PC
      if (SD) this.speed_delta = +SD
      for (let i = 0; i < NB; i++) this.genBulle()
    }
    orig.call(this, d)
    if (N && this.frameCount >= N && this.bulles.length) {
      for (const b of this.bulles) b.mc.removeMovieClip()
      this.bulles.length = 0
    }
  }
}
