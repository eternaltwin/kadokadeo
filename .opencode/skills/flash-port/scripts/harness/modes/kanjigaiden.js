// Kanji Gaiden test modes (see game.html). They only patch the game from the frame counter and the url: the same in the
// live game and in its replay.
// kg: kinds=1 gives the monkeys that appear (on the far plane) each kind in turn: the 4 colours of mtype 0..3, then the
//     monkeys carrying the 4 bonuses (mtype 4, btype 0..3); diff=D starts the difficulty at D (faster monkeys, the
//     strong ones, more of them); bonus=B&every=N gives bonus B (0..3, 4: each in turn) every N Flash frames
//     (Game.bonusMe, as a killed carrier does); frames=N ends the game at Flash frame N (the game's own gameOver)
TEST_MODES.kg = (P, q) => {
  const kinds = q.get('kinds') === '1', diff = +(q.get('diff') || 0), N = +(q.get('frames') || 0)
  const bonus = q.has('bonus') ? +q.get('bonus') : -1, every = +(q.get('every') || 400)
  const SEQ = [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [4, 1], [4, 2], [4, 3]]
  let n = 0, given = 0
  const orig = P.flashFrame
  P.flashFrame = function () {
    if (this.frameCount === 0) n = given = 0
    if (this.frameCount === 0 && diff) { this.diff = diff; this.monkeyMin = 4 + diff }
    if (bonus >= 0 && this.frameCount > 0 && this.frameCount % every === 0 && !this.dead) this.bonusMe(bonus === 4 ? given++ % 4 : bonus)
    orig.call(this)
    if (kinds) for (const m of this.monkeys) {
      if (m.__kg) continue
      m.__kg = true
      // (the monkeys moved to a nearer plane keep their kind)
      if (m.pl !== 2) continue
      const [t, bt] = SEQ[n++ % SEQ.length]
      m.mtype = t
      m.btype = bt
      m.initMCs()
    }
    if (N && this.frameCount >= N && !window.__over) this.gameOver()
  }
}
