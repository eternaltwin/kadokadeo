// Punch-In test modes (see game.html). They only patch the game from counters and the url: the same in the live game
// and in its replay.
// pi: msg=N shows the message `mtext` (default "3 COMBO") at Flash frame N (Game.newMsg, 15), bonus=1 gives every bonus
//     a colour in turn (green, blue, red: Game.initBonus draws its colour; the draw is kept, only the result changes),
//     cool=C shortens the wait between two bonuses (bonusCool at most C), def=L starts the afro's defence level at L
//     (the late game), god=1 keeps the stamina at 50 at least, frames=N ends the game at Flash frame N (through the
//     game's own initGameOver: window.__over)
TEST_MODES.pi = (P, q) => {
  const MSG = +(q.get('msg') || 0), text = q.get('mtext') || '3 COMBO', bonus = q.get('bonus') === '1'
  const COOL = q.get('cool') != null ? +q.get('cool') : -1, DEF = +(q.get('def') || 0), god = q.get('god') === '1'
  const N = +(q.get('frames') || 0)
  const G = window.GamePunchIn
  const COLS = [[2, 0xB3FD02], [3, 0x02CBFD], [4, 0xFF6600]]
  const ib = P.initBonus
  P.initBonus = function () {
    ib.call(this)
    if (bonus) {
      const c = COLS[(this.__nb = (this.__nb || 0) + 1) % 3]
      G.bonusCol = c[0]
      this.currentCol = c[1]
    }
  }
  const orig = P.origUpdate
  P.origUpdate = function () {
    if (this.frameCount === 0 && DEF) G.afro.defLevel = DEF
    if (COOL >= 0 && this.bonusCool > COOL) this.bonusCool = COOL
    orig.call(this)
    if (god && this.st.maskXScale < 50) this.st.maskXScale = 50
    if (MSG && this.frameCount + 1 === MSG) this.newMsg(text, 15)
    if (N && this.frameCount + 1 >= N && !this.over) this.initGameOver()
  }
}
