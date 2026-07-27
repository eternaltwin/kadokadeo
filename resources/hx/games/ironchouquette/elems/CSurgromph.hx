package ironchouquette.elems;

// frame 5
class CSurgromph extends Bads {
	public var follow:ASprite;
	public var fire:ASprite;

	public function new() {
		var root = Cs.game.dm.attach("surgromphBody", Game.DP_BADS);
		super(root);
		follow = root.attachMovie("surgromphTurret");
		fire = follow;

		setLevel(20);
		setScore(Cs.C_SURGROMPH);
		hp = 16;

		var raf = newRafale();
		raf.addShot(2, [6, 21], 4, 3);
		raf.cooldown = 60;
		raf.dy = 0;
		raf.orientRay = KadoKadeoManager.I(26);

		shootTimer = 40;
	}

	public override function update() {
		super.update();
		// TURRET
		if (this.root != null) {
			var dx = Cs.game.hero.x - x;
			var dy = Cs.game.hero.y - y;
			follow._rotation = Math.atan2(dy, dx) / 0.0174 - root._rotation;
		}
	}
}
