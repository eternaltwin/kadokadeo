package minirace;

// particle with a height (z) and its shadow on the ground; mcParts by default (piece of a car, coloured by the code)
class Part extends Phys {
	static var SHADE_ALPHA = 20;

	public var z:Float;
	public var vz:Float;
	public var shade:Clip;
	public var zw:Float;
	public var bhl:Array<Int>;

	var clip:Clip;
	// mcParts: its timeline (frame 1 stopped, then smc plays frames 2 to 7, obj.kill() on frame 8)
	var isParts:Bool;
	var pf:Int;
	var playing:Bool;

	public function new(?mc:Clip) {
		isParts = mc == null;
		if (mc == null)
			mc = Clip.attach(Cs.game.mdm, "partSmc", Game.DP_SKY_PARTS);
		super(mc);
		clip = mc;
		z = 0;
		vz = 0;
		zw = 1;
		pf = 1;
		playing = false;
		// Filt.glow(root, 2, 1, 0): in the images
	}

	public function initShade() {
		shade = Clip.attach(Cs.game.mdm, "partSmcShade", Game.DP_GROUND);
		// Col.setPercentColor(shade, 100, 0)
		shade.setColour(0x000000, 0);
		shade._alpha = SHADE_ALPHA;
		shade._xscale = shade._yscale = scale;
		shade._x = shade._y = -1000;
	}

	// Col.setPercentColor(root.smc, 100, col): white image tinted (its black glow stays black)
	public function setColour(col:Int) {
		clip.setColour(col, 0);
	}

	override function fadePlay() {
		if (isParts)
			playing = true;
		else
			root.play();
	}

	override public function update() {
		// timeline of mcParts
		if (playing) {
			pf++;
			if (pf >= 8) {
				kill();
				return;
			}
			clip.gotoAndStop(pf);
		}

		// Z
		vz += zw * Timer.tmod;
		if (frict != null)
			vz *= Math.pow(frict, Timer.tmod);
		z += vz * Timer.tmod;

		if (z > 0) {
			if (vr != null)
				vr *= -Seed.randVfx() * 0.8;
			z = 0;
			vz *= -0.8;
			vx *= 0.9;
			vy *= 0.9;
		}

		// UPDATE GFX
		super.update();
		if (dead)
			return;

		// DISPLAY Z (in updatePos)
		root._yscale = root._xscale = scale - z;

		// SHADE
		if (shade != null) {
			var first = shade._x == -1000;
			shade._x = x;
			shade._y = y;
			shade._rotation = root._rotation;
			shade._alpha = SHADE_ALPHA * (root._alpha / 100);
			if (first)
				shade.updateState();
		}

		// BEHAVIOUR
		if (bhl != null)
			for (bh in bhl) {
				switch (bh) {
					case 0:
						var a = Math.atan2(vy, vx);
						var fl = Clip.attach(Cs.game.mdm, "partFlame", Game.DP_PARTS);
						var p = new Phys(fl);
						fl.onRemoved = p.kill;
						p.x = root._x + (Seed.randVfx() * 2 - 1) * 4;
						p.y = root._y + (Seed.randVfx() * 2 - 1) * 4;
						p.root._xscale = p.root._yscale = root._xscale;
						p.vx = vx * (0.5 + Seed.randVfx() * 0.2);
						p.vy = vy * (0.5 + Seed.randVfx() * 0.2);
						p.root._rotation = a / 0.0174 - 90;
				}
			}
	}

	override public function updatePos() {
		root._x = x + z * 0.1;
		root._y = y + z * 0.5;
		firstPlace();
	}

	override public function kill() {
		if (shade != null)
			shade.removeMovieClip();
		super.kill();
	}
}
