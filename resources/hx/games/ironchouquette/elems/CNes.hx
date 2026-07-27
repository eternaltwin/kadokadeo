package ironchouquette.elems;

// frame 9
class CNes extends Bads {
	public var fire:ASprite;

	public function new() {
		var root = Cs.game.dm.attach("nesBody", Game.DP_BADS);
		super(root);
		fire = root.attachMovie("nesFire");

		fire._x = -KadoKadeoManager.I(26);
		fire._y = KadoKadeoManager.I(8);

		setLevel(40);
		setScore(Cs.C_NES);
		hp = 60;

		var raf = newRafale();
		raf.addShot(0, [10, 23, 16], 150, 1);
		raf.cooldown = 40;
		raf.dx = -KadoKadeoManager.I(5);
		raf.dy = KadoKadeoManager.I(20);

		raf = newRafale();
		raf.addShot(0, [10, 23, 16], 6, 3);
		raf.cooldown = 100;
		raf.dx = -KadoKadeoManager.I(5);
		raf.dy = KadoKadeoManager.I(24); // 20;

		shootTimer = 50 + Seed.rand() * 50;
		rect = {rw: KadoKadeoManager.I(30), rh: KadoKadeoManager.I(25)};
	}
}
