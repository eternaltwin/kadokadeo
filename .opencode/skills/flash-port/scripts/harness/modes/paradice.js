// Paradice test modes (see game.html). They only patch the game from counters and the url: the same in the live game
// and in its replay.
// pd: coverage. sp=0|1|2: every fill is that special (flame thrower, bomb, grenades); sp=c: the fills cycle through
//     normal, flame, normal, bomb, normal, grenades; spn=N: only the first N fills (then the game's random);
//     play=P: the game starts as if P plays were done (5 colours from 61)
TEST_MODES.pd = (P, q) => {
  const orig = P.update
  const sp = q.get('sp'), play = +(q.get('play') || 0), spn = +(q.get('spn') || 1e9)
  P.update = function (d) {
    if (this.__k === undefined) {
      this.__k = 0
      if (play) this.play = play
      const g = this.ground, fill = g.fill
      g.fill = function () {
        const k = this.__n = (this.__n || 0) + 1
        if (k > spn) this.testSpecial = null
        else if (sp === 'c') this.testSpecial = k % 2 ? null : [0, 1, 2][(k / 2 - 1) % 3]
        else if (sp != null) this.testSpecial = +sp
        fill.call(this)
      }
    }
    orig.call(this, d)
  }
}
