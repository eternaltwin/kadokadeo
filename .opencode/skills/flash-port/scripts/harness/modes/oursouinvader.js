// Oursouinvader test modes (see game.html). They only patch the game from the frame counter and the url: the same in
// the live game and in its replay.
// oi: wave=W&dif=D starts at wave W with the difficulty D (13 and more: the boss); inv=1 makes the hero immortal (what
//     touches it is killed, like with the shield); bonus=t,t,...&every=N drops a bonus of each type in turn on the hero
//     every N Flash frames (0 - 2 points, 3 speed, 4 triple shot, 5 fire rate, 6 shield); frames=N ends the game at
//     Flash frame N (through the game's own gameOver: window.__over)
TEST_MODES.oi = (P, q) => {
  const N = +(q.get('frames') || 0), wave = +(q.get('wave') || 0), dif = +(q.get('dif') || 0), inv = q.get('inv') === '1'
  const bonus = (q.get('bonus') || '').split(',').filter(s => s !== '').map(Number), every = +(q.get('every') || 200)
  let nb = 0
  const orig = P.flashFrame
  P.flashFrame = function () {
    if (this.frameCount === 0) {
      if (wave) this.debugWave(wave, dif || 24)
      if (inv) this.hero.shooted = function (m) { m.kill() }
    }
    if (bonus.length && this.frameCount > 0 && this.frameCount % every === 0 && !this.hero.dead)
      this.debugBonus(bonus[nb++ % bonus.length], this.hero.x, 150)
    orig.call(this)
    if (N && this.frameCount >= N && !window.__over) this.gameOver()
  }
}
