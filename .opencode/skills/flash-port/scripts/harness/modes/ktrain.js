// K-Train test modes (see game.html). They only patch the game from the frame counter and the url: the same in the
// live game and in its replay.
// kt: frames=N ends the game at Flash frame N (game over through the game's own flag); piouz=1 makes every gem a piouz
//     (on the track: the train hits it, or the driver catches it); opp=S gives the train behind the speed S from the
//     start (the crash comes early)
TEST_MODES.kt = (P, q) => {
  const N = +(q.get('frames') || 0), piouz = q.get('piouz') === '1', opp = +(q.get('opp') || 0)
  const orig = P.flashFrame
  P.flashFrame = function (pressed) {
    if (this.frameCount === 0) {
      if (piouz) this.testPiouz = true
      if (opp) this.debugOpp(opp)
    }
    orig.call(this, pressed)
    if (N && this.frameCount >= N) this.gameOver = true
  }
}
