package ironchouquette.elems;

// frame 3
class CFuria extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("furiaBody", Game.DP_BADS);
		super(root);

		setLevel(2);
		setScore(Cs.C_FURIA);
		hp = 1;
		var raf = newRafale();
		raf.addShot(0, [4.5, 13], 0, 1);
		shootTimer = 70 + Seed.rand() * 30;
	}
}
