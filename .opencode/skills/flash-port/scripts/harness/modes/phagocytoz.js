// Phagocytoz test modes (loaded by game.html for game=phagocytoz). Each must do exactly the same thing in the live
// game and in its replay: only the Flash frame counter and the url parameters decide.
// test=hold   the game is not updated by KadoKadeo: stepped by hand (kk.game.flashFrame(); kk.game.display(1)), for
//             frame by frame screenshots (pframes.mjs)
// test=ph     coverage, every parameter optional:
//   dif=N        the game starts at phase N + 1 (the title, the number of cells, hunters, the hero's timer)
//   clear=F,G..  at these Flash frames, every cell but the hero dies (the phase ends: fade, title, next phase)
//   starve=F     at Flash frame F, the phase timer jumps to its limit (the hero shrinks every frame, the pink flash)
//   frames=N     the hero dies at Flash frame N (game over)
//   inv=1        the hero is never eaten (it still shrinks when the timer is over)
//   swim=1       the hero swims by itself (pressed, the mouse turning around the centre: smoothness tests)
//   e.g. game.html?game=phagocytoz&cls=GamePhagocytoz&seed=123&test=ph&clear=200,500&starve=900
TEST_MODES.hold = (P) => {
  window.__hold = true
  const u = P.update
  P.update = function (d) { if (!window.__hold) u.call(this, d) }
}
TEST_MODES.ph = (P, q) => {
  const orig = P.origUpdate
  const clear = (q.get('clear') || '').split(',').filter(Boolean).map(Number)
  const starve = +(q.get('starve') || 0), N = +(q.get('frames') || 0)
  if (q.get('swim') === '1') {
    const G = window.GamePhagocytoz
    G.mouseX = () => 150 + 100 * Math.cos((P.__swimN || 0) / 60)
    G.mouseY = () => 150 + 100 * Math.sin((P.__swimN || 0) / 60)
    P.pollMouse = function () { P.__swimN = this.__n || 0; this.click = true }
  }
  P.origUpdate = function () {
    if (this.__n === undefined) {
      this.__n = 0
      if (q.get('dif')) { this.dif = +q.get('dif'); this.title.phase.field.set_text('phase #' + (this.dif + 1)) }
    }
    const n = ++this.__n
    if (clear.includes(n) && this.cells && this.hero && !this.hero.dead)
      for (const c of this.cells.slice()) if (c !== this.hero) c.kill()
    if (q.get('inv') === '1' && this.hero && !this.hero.__inv) {
      // (the hero of this phase: grow(-area) only from its own update, the timer)
      const h = this.hero, grow = h.grow, upd = h.update
      h.__inv = true
      let own = false
      h.update = function () { own = true; try { upd.call(this) } finally { own = false } }
      h.grow = function (inc) { if (inc >= 0 || own) grow.call(this, inc) }
    }
    if (starve && n === starve && this.hero) this.timer = 2500 - this.dif * 200
    if (N && n === N && this.hero && !this.hero.dead) this.hero.kill()
    orig.call(this)
  }
}
