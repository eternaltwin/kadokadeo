// Cosmo Crash test modes (see game.html). They only patch the game from the frame counter and the url: the same in the
// live game and in its replay.
// cc: frames=N ends the game at Flash frame N (through the game's own gameOver: window.__over); norescue=1 ends the
//     rescue phase at the start (no free crash: vehicles come, the first crash ends the game); dif=D starts the
//     difficulty at D (vehicles at once, tanks from 3600); loop=1 keeps the loop bonus of the hero armed in flight
//     (Hero.loopBonus = 100: every landing with colonists scores it)
TEST_MODES.cc = (P, q) => {
  const N = +(q.get('frames') || 0), noRescue = q.get('norescue') === '1', dif = +(q.get('dif') || 0), loop = q.get('loop') === '1'
  const orig = P.flashFrame
  P.flashFrame = function () {
    if (this.frameCount === 0) {
      if (noRescue) this.stopRescue()
      if (dif) this.dif = dif
    }
    if (loop && this.hero && this.hero.step === 0) this.hero.loopBonus = 100
    orig.call(this)
    if (N && this.frameCount >= N && !window.__over) this.gameOver()
  }
}
