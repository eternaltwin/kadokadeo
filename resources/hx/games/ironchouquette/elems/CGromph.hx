package ironchouquette.elems;

// frame 4
class CGromph extends Bads {
	public var follow:ASprite;
	public var fire:ASprite;

	public function new() {
		var root = Cs.game.dm.attach("gromphBody", Game.DP_BADS);
		super(root);
		follow = root.attachMovie("gromphTurret");
		fire = follow;

		setLevel(7);
		setScore(Cs.C_GROMPH);
		hp = 5;

		var raf = newRafale();
		raf.addShot(2, [6, 21], 4, 3);
		raf.dy = 0;
		raf.orientRay = 26 * Cs.NEW_GEN_SCALE;

		shootTimer = 80;
	}

	public override function update() {
		super.update();
		// TURRET
		var dx = Cs.game.hero.x - x;
		var dy = Cs.game.hero.y - y;
		follow._rotation = Math.atan2(dy, dx) / 0.0174 - root._rotation;
	}
}
