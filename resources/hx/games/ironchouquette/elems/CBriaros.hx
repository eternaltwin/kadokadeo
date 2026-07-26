package ironchouquette.elems;

// frame 6
class CBriaros extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("mcKidnapper", Game.DP_BADS);
		super(root);
		setLevel(6);
		setScore(Cs.C_BRIAROS);

		hp = 6;

		vy = -Seed.rand() * KadoKadeoManager.I(5);

		var raf = newRafale();
		raf.addShot(1, [3, 0.6], 100, 1);
		shootTimer = 150 + Seed.rand() * 15;

		bList = [6, 7];
		frict = 0.9;

		var m = KadoKadeoManager.I(20);
		beeRange = [
			{
				w: 6,
				xMin: m,
				xMax: Cs.mcw - m,
				yMin: m,
				yMax: KadoKadeoManager.I(120)
			},
			{
				w: 1,
				xMin: m,
				xMax: Cs.mcw - m,
				yMin: Cs.mch * 0.5,
				yMax: Cs.mch - KadoKadeoManager.I(76)
			},
		];
		acc = {
			c: KadoKadeoManager.S(0.1),
			lim: KadoKadeoManager.I(1)
		};
	}
}
