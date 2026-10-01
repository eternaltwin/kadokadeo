package elloninthedark;

class Golgoth extends Bads {
	public static var EYE_POS = [[-31, -2], [-17, 3]];

	// labels of the "mcGolgoth" clip
	public static var FR_WARNING = 4;
	public static var FR_SHOOT_SHORT = 13;
	public static var FR_SHOOT_BIG = 26;

	public var sleep:Float;
	public var wTimer:Float;
	public var step:Int;

	// "mcGolgoth": whiskers, breathing body and warning keep playing while the clip is stopped
	var body:SlotClip;

	public function new(mc:ASprite) {
		super(mc, 28);
		buildClip();
		ray = KadoKadeoManager.I(40);
		hp = 50;
		frict = 0.98;

		x = Cs.mcw + ray + KadoKadeoManager.I(30);
		y = Cs.GL * 0.5;
		decal = 0;
		sleep = 0;
		//
		initStep(2);
		wTimer = 140;
		gid = 4;
		//
		score = Cs.SCORE_GOLGOTH;
	}

	function buildClip() {
		body = new SlotClip(Data.GOLGOTH).attachTo(root, 1);
		// scale tween of the breathing clip
		body.setScaleAnim("golgothBreath", Data.GOLGOTH_BREATH);
		// timeline actions: stop() on 1 and 8, gotoAndStop(1) on 22 and 32
		body.stopOnFrame = [1, 8];
		body.onFrame.set(22, () -> body.gotoAndStop(1));
		body.onFrame.set(32, () -> body.gotoAndStop(1));
	}

	override public function update() {
		super.update();
		move();
		wTimer -= Timer.tmod;
		switch (step) {
			case 0:
				if (wTimer < 0) {
					initStep(2);
				}
			case 1:
				if (wTimer < 0) {
					body.gotoAndPlay(FR_SHOOT_BIG);
					var s = newAimedShot(KadoKadeoManager.S(14), 0);
					s.setSkin(10);
					s.ray = KadoKadeoManager.I(20);
					vx -= s.vx * 0.5;
					vy -= s.vy * 0.5;
					initStep(2);
				}
			case 2:
				if (wTimer < 0) {
					initStep(Seed.random(2));
				}
		}
	}

	public function initStep(n:Int) {
		step = n;
		switch (step) {
			case 0:
				shootRate = 1;
				wTimer = 150;
			case 1:
				shootRate = null;
				wTimer = 30 + Seed.rand() * 100;
				body.gotoAndPlay(FR_WARNING);
			case 2:
				shootRate = null;
				wTimer = 40 + Seed.rand() * 40;
		}
	}

	override public function shoot() {
		body.gotoAndPlay(FR_SHOOT_SHORT);
		var h = Cs.game.hero;
		for (i in 0...2) {
			var p = EYE_POS[i];
			var s = newShot();
			s.x = x + KadoKadeoManager.I(p[0]) * root._xscale / 100;
			s.y = y + KadoKadeoManager.I(p[1]);
			var dx = h.x + KadoKadeoManager.I(p[0]) + KadoKadeoManager.I(17) - s.x;
			var dy = h.y - s.y;
			s.a = Math.atan2(dy, dx);
			var sp = KadoKadeoManager.S(6);
			s.vx = Math.cos(s.a) * sp;
			s.vy = Math.sin(s.a) * sp;
			s.orient();
			s.setSkin(9);
			s.root._rotation = Seed.randVfx() * 360;
			cooldown = 16;
		}
	}

	public function move() {
		sleep = Math.min(sleep + 0.01 * Timer.tmod, 1);

		decal = (decal + 17 * Timer.tmod) % 628;

		var h = Cs.game.hero;
		var mw = Cs.mcw * 0.5;
		var mh = Cs.GL * 0.5;
		var r = KadoKadeoManager.S(25);
		var cc = 0.7;
		var trg = {
			x: (mw - (h.x - mw) * cc) + Math.cos(decal / 100) * r,
			y: (mh - (h.y - mh) * cc) + Math.sin(decal / 100) * r
		};
		var speed = KadoKadeoManager.S(0.5) * sleep;
		speedToward(trg, 0.2, speed);

		// RECAL
		bounceFamily();

		// REBOND
		if (y + ray > Cs.GL) {
			y = Cs.GL - ray;
			vy *= -0.8;

			for (i in 0...4) {
				genGroundSmoke();
			}
		}

		//
		var sens = root._xscale / 100;
		if ((h.x - x) * sens > 0)
			setSens(-sens);
		root._rotation = -(Cs.u(h.y - y) * 0.1) * root._xscale / 100;
	}
}
