package elloninthedark;

class Frog extends Bads {
	// labels of the "mcFrog" clip
	public static var FR_JUMP_START = 5;
	public static var FR_LAND = 19;

	public var step:Int;
	public var explodeTimer:Float;

	// "mcFrog": the jelly body and the ball keep wobbling while the clip is stopped
	var clip:SlotClip;

	public function new(mc:ASprite) {
		super(mc, 16);
		ray = KadoKadeoManager.I(18);
		hp = 30;
		score = Cs.SCORE_FROG;

		clip = new SlotClip(Data.FROG).attachTo(root, 1);
		// timeline actions of the clip: stop() on frame 12, gotoAndStop(1) on frame 40
		clip.stopOnFrame = [12];
		clip.onFrame.set(40, () -> clip.gotoAndStop(1));

		x = Cs.mcw + ray + KadoKadeoManager.I(5);
		initGround();
		gid = 6;

		//
		explodeTimer = 120;
	}

	override public function update() {
		super.update();
		switch (step) {
			case 0:
				var h = Cs.mcw * 0.5;
				if (x < h && Seed.rand() * (x / h) < 0.1) {
					step = 1;
					clip.gotoAndPlay(FR_JUMP_START);
					var ma = 0.3;
					var a = -(ma + Seed.rand() * (1.57 - 2 * ma));
					var sp = KadoKadeoManager.S(10 + Seed.rand() * 8);
					vx = Math.cos(a) * sp;
					vy = Math.sin(a) * sp - KadoKadeoManager.S(Seed.rand() * 5);
					frict = 0.98;
					weight = KadoKadeoManager.S(0.7);
				}
			case 1:
				if (y > Cs.GL) {
					initGround();
				}
		}
		explodeTimer -= Timer.tmod;
		if (explodeTimer < 0 && y < KadoKadeoManager.I(230)) {
			var max = 64;
			var cr = 8;
			for (i in 0...max) {
				var shot = newShot();
				var a = i / max * 6.28;
				var ca = Math.cos(a);
				var sa = Math.sin(a);
				var sp = KadoKadeoManager.S(3 + (i % 3) * 1.5);
				shot.x += ca * cr * sp;
				shot.y += sa * cr * sp;
				shot.vx = ca * sp;
				shot.vy = sa * sp;
				shot.setSkin(8);
			}
			kill();
		}
	}

	override public function hit(shot:Shot) {
		explodeTimer += shot.damage * 20;
		super.hit(shot);
	}

	public function initGround() {
		step = 0;
		weight = null;
		frict = 1;
		vx = -Cs.SCROLL_SPEED;
		vy = 0;
		y = Cs.GL - ray * 0.5;
		clip.gotoAndPlay(FR_LAND);
		root._rotation = 0;
	}
}
