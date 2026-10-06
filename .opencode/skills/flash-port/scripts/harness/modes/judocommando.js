// Judo Commando test modes (see game.html). They only decide from the url and the Flash frame counter: the same in
// the live game and in its replay.
//   lvl=<n>     the game starts on level n (the monsters and the level of that rank)
//   chrono=<n>  frames before the first gorilla on every level (the original: 6000, 4000 then 2000)
//   inv=1       the hero keeps 10 lives (coverage: gorillas, every monster type)
//   frames=<n>  the game over (Game.initGameOver) at Flash frame n
TEST_MODES.jc = (P, q) => {
  const L = +(q.get('lvl') || 0), C = +(q.get('chrono') || 0), INV = q.get('inv') === '1', N = +(q.get('frames') || 0)
  const decale = P.decale, initPlay = P.initPlay, flash = P.flashFrame
  P.decale = function () {
    if (!this.__lvlSet) { this.__lvlSet = true; this.lvl = L }
    decale.call(this)
  }
  P.initPlay = function () {
    initPlay.call(this)
    if (C) this.chrono = C
  }
  P.flashFrame = function () {
    if (INV && this.hero && this.hero.life < 10 && this.hero.life > 0) this.hero.life = 10
    flash.call(this)
    if (N && this.frameCount >= N && !this.over) this.initGameOver()
  }
}
