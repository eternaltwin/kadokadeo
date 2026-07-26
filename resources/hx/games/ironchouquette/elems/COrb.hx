package ironchouquette.elems;

// frame 10
class COrb extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("orbBody", Game.DP_BADS);
		super(root);

		setLevel(18);
		setScore(Cs.C_ORB);
		ray = KadoKadeoManager.I(25);
		y = -(ray + KadoKadeoManager.I(5));
		hp = 16;
		bounceId = 1;
		bList = [9];
		trg = {x: 0., y: KadoKadeoManager.S(70) + Seed.rand() * KadoKadeoManager.I(30)}
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
