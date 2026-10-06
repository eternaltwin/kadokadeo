package cosmocrash;

// Part.hx of the original: particles (dust, sparks, pieces of the hero, rising scores). Only pictures: the random of
// their bounces is visual.
class Part extends Element {
	public var ray:Float;

	public var vr:Null<Float>;
	public var fr:Null<Float>;
	public var vsc:Null<Float>;
	public var scale:Null<Float>;
	public var sleep:Null<Float>;
	public var timer:Null<Float>;
	public var alpha:Float;
	public var bounceFrict:Float;
	public var fadeLimit:Float;
	public var fadeType:Null<Int>;

	public function new(mc:MC) {
		super(mc);
		fadeLimit = 10;
		alpha = 100;
		ray = 0;
		bounceFrict = -0.75;
	}

	public function setAlpha(n:Float) {
		alpha = n;
		root._alpha = alpha;
	}

	override function update() {
		if (sleep != null) {
			sleep--;
			if (sleep < 0) {
				sleep = null;
				root._visible = true;
				root.play();
			}
			return;
		}

		if (vr != null)
			root._rotation += vr;
		if (fr != null)
			vr *= fr;
		if (vsc != null) {
			root._xscale *= vsc;
			root._yscale = root._xscale;
		}

		if (timer != null) {
			timer--;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				// (Cosmo Crash never sets fadeType: the default fade)
				switch (fadeType) {
					case -1:
					case 0:
						root._xscale = c * scale;
						root._yscale = c * scale;
					case 1:
						root._visible = Std.int(timer) % 4 > 1;
					case 2:
						root.play();
					case 3:
						root._yscale = c * scale;
					case 5:
						root._xscale = c * scale;
					default:
						root._alpha = c * alpha;
				}
				if (timer <= 0) {
					kill();
				}
			}
		}

		super.update();

		var gy = Game.me.getGY(x);
		if (y > gy - ray) {
			y = gy - ray;
			if (vy > 0)
				vy *= bounceFrict;
			vx *= 0.95;
			if (vr != null) {
				if (!root.hasSub("smc"))
					vr *= -(0.5 + Seed.randVfx());
				else
					root.setSub("smc", root.subX("smc") * 0.85);
			}
		}
		updatePos();
	}
}
