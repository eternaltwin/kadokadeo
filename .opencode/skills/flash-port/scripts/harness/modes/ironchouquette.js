// Test modes of Iron Chouquette. Rule: identical in live and replay (only the frame counter decides).
// icw: equips the laser, the missiles and the speed boost, then sacrifices the plasma (the bolt shower):
// exercises every plasma stamp path (laser into layer 1, missile trails + speed blobs into layer 0 and the
// SpeedField, partPlasmaBolt incrust).
TEST_MODES.icw = (P, q) => {
  const orig = P.update
  P.update = function (d) {
    if (this.__m === undefined) this.__m = 0
    this.__m++
    const h = this.hero
    if (h && !h.isDead) {
      if (this.__m === 60) h.addWeapon(2)      // laser
      if (this.__m === 200) h.addWeapon(5)     // missiles (trails stamped into layer 0 / SpeedField)
      if (this.__m === 300) h.addWeapon(3)     // speed (blobs into layer 0 / SpeedField, gameplay RNG)
      if (this.__m === 420) h.addWeapon(0)     // a plasma slot... (a 4th weapon auto-sacrifices slot 0)
      if (this.__m === 440 && h.slots.lastIndexOf(0) >= 0) h.sacrifice(h.slots.lastIndexOf(0))     // ...sacrificed: the partPlasmaBolt shower
    }
    orig.call(this, d)
    if (this.__m === +(q.get('frames') || 900)) kk.gameOver({})
  }
}
