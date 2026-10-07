// Razor test modes (see game.html). They only patch the game from counters and the url: the same in the live game
// and in its replay.
// rz: pat=<name> gives the first board a designed layout (the colours of PATTERNS, rows y = 0..5, x = 0..5; 3 is a
//     Pioupiou), frames=N ends the game at Flash frame N (through the game's own initGameOver: window.__over).
//     The razor starts under (3, 5): a path of one colour from there gives a long combo at the first slice (a board of
//     one colour would make getPath try every path of the grid, as the original: hours).
//   a: 24 fruits (a snake on rows 5, 3, then the 2 rows 1 and 0): "ORGIE DANS LE SANG!"
//   b: 18 fruits (rows 5, 3, 1): "ARCHI-GORE!"
//   c: 14 (rows 5, 3, then (5, 2), (5, 1), (4, 1)): "MONSTRUEUX!"
//   d: 11 with 2 Pioupious in it: "SUPER COMBO!"
//   e: 8: "COMBO!"
//   p: a path of Pioupious from the start (scored 1000 each)
const PATTERNS = {
  a: ['000000', '000000', '121210', '000000', '021212', '000012'],
  b: ['121212', '000000', '121210', '000000', '021212', '000012'],
  c: ['121212', '212100', '121210', '000000', '021212', '000012'],
  d: ['121212', '212121', '121212', '000030', '021212', '003012'],
  e: ['121212', '212121', '121212', '000121', '021212', '000012'],
  p: ['121212', '212121', '121212', '212121', '121232', '212331'],
}
TEST_MODES.rz = (P, q) => {
  const pat = PATTERNS[q.get('pat') || ''], N = +(q.get('frames') || 0)
  const ff = P.flashFrame
  P.flashFrame = function () {
    if (pat && this.frameCount === 0) {
      for (const b of this.balls) {
        b.col = +pat[b.y][b.x]
        b.root.gotoAndStop(b.col + 1)
      }
    }
    ff.call(this)
    if (N && this.frameCount >= N && !this.over) this.initGameOver()
  }
}
