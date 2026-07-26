package ironchouquette.elems;

import mt.Timer;

// frame 18
class CMine extends Bads {
	public var turn:ASprite;

	public function new() {
		var root = Cs.game.dm.attach("mineBody", Game.DP_BADS);
		super(root);
		turn = root.attachMovie("mineShell");

		setLevel(4);
		setScore(Cs.C_MINE);
		hp = 3;
		ray = KadoKadeoManager.I(16);
		vy = KadoKadeoManager.S(1 + Seed.rand() * 1);
		bounceId = 2;
		onDeath = () -> {
			var raf = newRafale();
			raf.shot(3, [3, 13, 12, 3.14]);
		};
	}

	public override function update() {
		turn._rotation += vy * Timer.tmod * 2.5;
		super.update();
	}
}
