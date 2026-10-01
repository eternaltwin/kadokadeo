package elloninthedark;

class Carrier extends Bads {
	public static var MARGIN = KadoKadeoManager.I(20);

	public var run:Int;
	public var turn:Float;
	public var wTimer:Float;

	public function new(mc:ASprite) {
		super(mc, 2);

		ray = KadoKadeoManager.I(10);
		hp = 1;
		frict = 0.98;
		trg = {x: Cs.mcw - KadoKadeoManager.I(40), y: MARGIN + Seed.rand() * (Cs.GL - 2 * MARGIN)};
		turn = 0;
		wTimer = 250;

		x = Cs.mcw + KadoKadeoManager.I(20);
		y = MARGIN + Seed.rand() * (Cs.GL - 2 * MARGIN);

		score = Cs.SCORE_CARRIER;
		gid = 3;
		run = 3;
		wTimer = 150;

		root.loop = true;
		root.play();
	}

	override public function update() {
		super.update();
		turn = (turn + 13 * Timer.tmod) % 628;
		var pos = {
			x: trg.x + Math.cos(turn / 100) * MARGIN,
			y: trg.y + Math.sin(turn / 100) * MARGIN
		};
		speedToward(pos, 0.2, KadoKadeoManager.S(0.2));

		// TIMER
		wTimer -= Timer.tmod;
		if (wTimer <= 0) {
			if (run-- > 0) {
				wTimer = 50 + Seed.rand() * 150;
				trg = {
					x: MARGIN + Seed.rand() * (Cs.mcw - 2 * MARGIN),
					y: MARGIN + Seed.rand() * (Cs.GL - 2 * MARGIN)
				};
			} else {
				wTimer = 1000;
				trg = {
					x: Cs.mcw + KadoKadeoManager.I(20),
					y: y
				};
			}
		}
		if (run == 0 && x > Cs.mcw + KadoKadeoManager.I(20)) {
			kill();
		}

		checkGround();
	}

	override public function explode() {
		var b = new Bonus();
		b.x = x;
		b.y = y;
		super.explode();
	}
}
