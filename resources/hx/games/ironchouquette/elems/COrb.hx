package ironchouquette.elems;

// frame 10
class COrb extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("orbBody", Game.DP_BADS);
		super(root);

		setLevel(18);
		setScore(Cs.C_ORB);
		ray = 25 * Cs.NEW_GEN_SCALE;
		y = -(ray + 5 * Cs.NEW_GEN_SCALE);
		hp = 16;
		bounceId = 1;
		bList = [9];
		trg = {x: 0, y: 70 * Cs.NEW_GEN_SCALE + Cs.rand() * 30 * Cs.NEW_GEN_SCALE}
		waitTimer = 100;

		var raf = newRafale();
		for (i in 0...2) {
			raf.addShot(3, [3, 13, 4, 0.7], 14, 1);
			raf.addShot(3, [3, 13, 3, 0.5], 14, 1);
		}
		raf.cooldown = 800;
		shootTimer = 2000;
	}
}
