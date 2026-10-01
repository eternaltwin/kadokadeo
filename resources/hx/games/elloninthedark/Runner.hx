package elloninthedark;

class Runner extends Bads {
	public static var MARGIN = KadoKadeoManager.I(30);

	public var tx:Float;
	public var runFrame:Float;
	public var wTimer:Float;
	public var shotLeft:Float;

	public function new(mc:ASprite) {
		super(mc, 6);
		ray = KadoKadeoManager.I(11);
		hp = 4;
		frict = 0.98;
		score = Cs.SCORE_RUNNER;
		root._xscale *= -1;

		newTrg();
		tx += MARGIN;
		x = Cs.mcw + ray + KadoKadeoManager.I(5);
		y = Cs.GL - ray;

		runFrame = 0;

		shootRate = 1;
		cooldown = 100;
		shotLeft = 3;
		gid = 5;

		// the running clip is nested in a single frame root: it always plays, and so does its dusty body
		new SlotClip(Data.RUNNER).attachTo(root, 1).play();
	}

	override public function update() {
		super.update();
		var dx = tx - x;
		var lim = KadoKadeoManager.S(2.5);

		var vit = Num.mm(-lim, dx * 0.1, lim);
		x += vit * Timer.tmod;

		var speed = Math.max(0, 2.5 + Cs.u(vit) * 0.3);

		// root.gotoAndStop(runFrame) had no effect on the one frame root of the original clip
		runFrame = (runFrame + speed * Timer.tmod) % 40;

		wTimer -= Timer.tmod;
		if (wTimer < 0) {
			newTrg();
		}
	}

	override public function shoot() {
		shotLeft--;
		if (shotLeft == 0) {
			cooldown = 60;
			shotLeft = 3;
		} else {
			cooldown = 4;
		}
		var s = newAimedShot(KadoKadeoManager.S(2.5), 0);
		s.setSkin(2);
	}

	public function newTrg() {
		wTimer = 20 + Seed.rand() * 80;
		tx = MARGIN + Seed.rand() * (Cs.mcw - 2 * MARGIN);
	}
}
