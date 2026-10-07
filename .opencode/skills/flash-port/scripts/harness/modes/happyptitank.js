// Happy Pti Tank test modes (loaded by game.html for game=happyptitank). Each must do exactly the same thing in the
// live game and in its replay: only the Flash frame counter and the url parameters decide.
// test=ht  coverage, every parameter optional:
//   inv=1        the tank takes no damage
//   armor=N      armor at the start
//   waves=N      waves already done (harder zones, OptTime allowed, the countdown starts at the next zone)
//   time=S       the countdown starts at once with S seconds (the end by the big missile)
//   zone=F       a war zone at Flash frame F (and the game started: missiles, zones)
//   opts=i,j,..  an option dropped in front of the tank every `every` frames (indexes of Game.OPT_TABLE:
//                30 OptShot, 33 OptTime, 34 OptArmor, 35 OptSpeed, 37 OptShotRate)
//   clear=F      the zone left at Flash frame F (the "zone cleared" banner)
//   tc=K         the colour of the tank (index of the palette; a picture only)
//   art=1        no interface, no target (start screen pictures)
//   frames=N     the tank destroyed at Flash frame N (the YouDie end)
//   e.g. game.html?game=happyptitank&cls=GameHappyPtiTank&seed=123&test=ht&inv=1&zone=20&opts=30,33,34,35,37
TEST_MODES.ht = (P, q) => {
  const orig = P.origUpdate, origDamage = P.tankDamaged
  const inv = q.get('inv') === '1', N = +(q.get('frames') || 0), every = +(q.get('every') || 150)
  const opts = (q.get('opts') || '').split(',').filter(Boolean).map(Number)
  P.tankDamaged = function (d) { if (!inv) origDamage.call(this, d) }
  P.origUpdate = function () {
    if (this.__n === undefined) {
      this.__n = 0
      if (q.get('armor')) { this.armor = +q.get('armor'); this.updateArmorBits() }
      if (q.get('waves')) this.waves = +q.get('waves')
      if (q.get('tc')) { const k = +q.get('tc'), t = this.tank, c = window.GameHappyPtiTank.color.getColor(k); t.variant = k; t.col1.setColor(c); t.col2.setColor(c) }
      if (q.get('time')) { this.endTime = this.now + 1000 * +q.get('time'); this.userInterface.enableTime() }
    }
    const n = ++this.__n
    if (q.get('art') === '1') { this.userInterface.visible = false; this.target.visible = false }
    if (q.get('zone') && n === +q.get('zone')) { this.started = true; this.enterWarZone() }
    if (opts.length && n % every === every / 2) {
      const T = window.GameHappyPtiTank.OPT_TABLE, t = this.tank
      const o = new T[opts[(n / every | 0) % opts.length]]()
      o.set_x(t.get_x() + Math.cos(t.angle) * 40); o.set_y(t.get_y() + Math.sin(t.angle) * 40)
      this.gameLayer.addChild(o); this.options.push(o)
    }
    if (q.get('clear') && n === +q.get('clear') && this.warZone.visible) this.leaveWarZone(this.now)
    if (N && n === N) this.armor = 0
    orig.call(this)
  }
}
