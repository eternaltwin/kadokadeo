package ironchouquette.elems;

// frame 9
class CNes extends Bads {
	public var fire:ASprite;

	public function new() {
		var root = Cs.game.dm.attach("nesBody", Game.DP_BADS);
		super(root);
		fire = root.attachMovie("nesFire");

		fire._x = -26 * Cs.NEW_GEN_SCALE;
		fire._y = 8 * Cs.NEW_GEN_SCALE;

		setLevel(40);
		setScore(Cs.C_NES);
		hp = 60;

		var raf = newRafale();
		raf.addShot(0, [10, 23, 16], 150, 1);
		raf.cooldown = 40;
		raf.dx = -5 * Cs.NEW_GEN_SCALE;
		raf.dy = 20 * Cs.NEW_GEN_SCALE;

		raf = newRafale();
		raf.addShot(0, [10, 23, 16], 6, 3);
		raf.cooldown = 100;
		raf.dx = -5 * Cs.NEW_GEN_SCALE;
		raf.dy = 24 * Cs.NEW_GEN_SCALE; // 20;

		shootTimer = 50 + Seed.rand() * 50;
		rect = {rw: 30 * Cs.NEW_GEN_SCALE, rh: 25 * Cs.NEW_GEN_SCALE};
	}
}
