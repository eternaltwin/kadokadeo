// Schizo Fuzz test modes (see game.html). They only patch the game from counters and the url: the same in the live
// game and in its replay.
// sf: coverage. ids=a,b,c...: the items drawn by randomProbas, in this order and in a loop (0 windmill, 1 bush,
//     2 springboard, 3 stump, 4 shield, 5 acorn; default: a shield, a stump hit with it, a shield shown while the
//     hero has one, then every item); frames=N ends the game at frame N like generic
TEST_MODES.sf = (P, q) => {
  const ids = (q.get('ids') || '4,3,4,4,0,1,2,5,4,5,0,2,1,5').split(',').map(Number)
  const N = +(q.get('frames') || 0)
  const orig = P.update
  P.randomProbas = function (tbl) {
    if (this.__ci === undefined) this.__ci = 0
    return ids[this.__ci++ % ids.length]
  }
  P.update = function (d) {
    orig.call(this, d)
    if (N && this.frameCount >= N && !window.__over) { window.__over = { frame: this.frameCount, forced: true }; kk.gameOver({}) }
  }
}
