// Linea test modes (see game.html). They only change constants at the first update: the same in the live game and
// in its replay.
// lb: line bonuses far more often (Const.LINE_BONUS = lb %, default 60): several lines, merges, line score popups,
//     x-factor up to 11; frames=N also ends the game at frame N (like generic)
TEST_MODES.lb = (P, q) => {
  const orig = P.update, lb = +(q.get('lb') || 60), N = +(q.get('frames') || 0)
  P.update = function (d) {
    if (this.__n === undefined) { this.__n = 0; window.LineaConst.LINE_BONUS = lb }
    orig.call(this, d)
    if (N && ++this.__n === N) kk.gameOver({})
  }
}
