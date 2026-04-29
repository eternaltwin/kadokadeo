package ironchouquette.elems;

// frame 6
class CBriaros extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("mcKidnapper", Game.DP_BADS);
		super(root);
		setLevel(6);
		setScore(Cs.C_BRIAROS);

		hp = 6;

		vy = -Seed.rand() * 5 * Cs.NEW_GEN_SCALE;

		var raf = newRafale();
		raf.addShot(1, [3, 0.6], 100, 1);
		shootTimer = 150 + Seed.rand() * 15;

		bList = [6, 7];
		frict = 0.9;

		var m = 20 * Cs.NEW_GEN_SCALE;
		beeRange = [
			{
				w: 6,
				xMin: m,
				xMax: Cs.mcw - m,
				yMin: m,
				yMax: 120 * Cs.NEW_GEN_SCALE
			},
			{
				w: 1,
				xMin: m,
				xMax: Cs.mcw - m,
				yMin: Cs.mch * 0.5,
				yMax: Cs.mch - 76 * Cs.NEW_GEN_SCALE
			},
		];
		acc = {c: 0.1 * Cs.NEW_GEN_SCALE, lim: 1 * Cs.NEW_GEN_SCALE};
	}
}
