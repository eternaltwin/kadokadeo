// Spiroule test modes (see game.html). They only decide from the url: the same in the live game and in its replay.
// sp: the speed of the chain starts at <spd> (Game.speed, normally 0.0003 growing by 2.6e-7 per frame: the games end
//     sooner), black balls 1 in <blk> once the speed allows it (Game.black: kicked out, side bursts)
TEST_MODES.sp = (P, q) => {
  const spd = +(q.get('spd') || 0.0012), blk = +(q.get('blk') || 0)
  const up = P.updatePlay
  P.updatePlay = function () {
    if (!this.__sp) { this.__sp = true; this.speed = Math.max(this.speed, spd) }
    up.call(this)
    if (blk) this.black = Math.min(this.black, blk)
  }
}
