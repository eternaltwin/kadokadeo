// Cyclopean test modes (see game.html). They only act on the frame counter and the url: the same in the live game
// and in its replay.
// cy: time=N: the time left (gameTimer, in Flash frames: 3600 at the start) set to N on the first frame of the game
//     (a short game); ids=a,b...: the elements of the level take these ids in turn (coverage of every bonus)
TEST_MODES.cy = (P, q) => {
  const orig = P.update, T = q.get('time'), ids = q.get('ids') ? q.get('ids').split(',').map(Number) : null
  P.update = function (d) {
    orig.call(this, d)
    if (this.step === 1 && !this.__cy) {
      this.__cy = true
      if (T) this.gameTimer = +T
      if (ids) this.eList.forEach((e, i) => { e.id = ids[i % ids.length]; if (e.id === 4 && e.sid == null) e.sid = i % 7 })
    }
  }
}
