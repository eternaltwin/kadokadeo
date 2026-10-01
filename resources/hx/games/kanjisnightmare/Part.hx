package kanjisnightmare;

class Part extends Phys {
	public var outMargin:Null<Float>;
	public var flPlatCol:Bool;

	public var timer:Null<Float>;
	public var fadeType:Null<Int>;
	public var fadeLimit:Float;
	public var scale:Float;
	public var vs:Null<Float>;
	public var rFrict:Float;
	public var sFrict:Float;
	public var wait:Null<Float>;
	public var alpha:Float;

	// called when the particle dies (afterimages free their picture)
	public var onKill:Void->Void;

	public function new(mc:ASprite) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
		alpha = 100;
		rFrict = 1;
		sFrict = 1;
		flPlatCol = false;
	}

	public function setScale(sc:Float) {
		scale = sc;
		root._xscale = sc;
		root._yscale = sc;
	}

	public function setAlpha(n:Float) {
		alpha = n;
		root._alpha = alpha;
	}

	override public function update() {
		if (wait != null && wait > 0) {
			wait -= Timer.tmod;
			return;
		}
		super.update();
		if (vr != null) {
			vr *= rFrict;
			root._rotation += vr * Timer.tmod;
		}
		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				switch (fadeType) {
					case 0:
						root._xscale = scale * c;
						root._yscale = root._xscale;
					default:
						root._alpha = c * alpha;
				}
				if (timer < 0) {
					kill();
					return;
				}
			}
		}
		if (vs != null) {
			vs *= sFrict;
			scale += vs * Timer.tmod;
			setScale(scale);
		}
		if (outMargin != null && isOut(outMargin)) {
			kill();
			return;
		}
		if (flPlatCol)
			checkPlatCol();
	}

	override public function land(pl:Plat) {
		vy *= -1;
		if (vr != null)
			vr *= -Seed.randVfx() * 1.5;
	}

	override public function kill() {
		if (onKill != null) {
			onKill();
			onKill = null;
		}
		super.kill();
	}
}
