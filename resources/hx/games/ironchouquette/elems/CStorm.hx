package ironchouquette.elems;

// frame 11
class CStorm extends Bads {
	public function new(lvl:Int) {
		var root = Cs.game.dm.attach("storm" + Std.string(lvl + 1), Game.DP_BADS);
		super(root);

		root.loop = true;
		root.play();

		setLevel((lvl + 1) * 32);
		setScore(Cs.C_STORM[lvl]);

		hp = 28 + lvl * 20;
		ray = KadoKadeoManager.I(25);
		bList.push(5);
		waitTimer = 500 + lvl * 150;

		// SHOTS
		var raf = newRafale();
		raf.addShot(1, [3, 0.4], 5, 5 + 4 * lvl);
		shootTimer = 10;
	}
}
