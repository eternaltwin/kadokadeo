package cyclopean;

// particles: pictures only (their random draws are visual, see Seed.randomVfx at the call sites)
class Part extends Phys {
	public var timer:Null<Float>;
	public var fadeType:Null<Int>;
	public var fadeLimit:Float;
	public var scale:Float;
	public var vs:Null<Float>;
	public var rFrict:Float;
	public var sFrict:Float;

	public function new(mc:MC) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
		rFrict = 1;
		sFrict = 1;
		root.obj = this;
	}

	public function setScale(sc:Float):Void {
		scale = sc;
		root._xscale = sc;
		root._yscale = sc;
	}

	override public function update():Void {
		var tmod = Game.tmod;
		super.update();
		// (Part declares vr again: the same field as Phys's, so a spinning particle turns twice per frame)
		if (vr != null) {
			vr *= rFrict;
			root._rotation += vr * tmod;
		}
		if (timer != null) {
			timer -= tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				switch (fadeType) {
					case 0:
						root._xscale = scale * c;
						root._yscale = root._xscale;
					default:
						root._alpha = c * 100;
				}
				if (timer < 0) {
					kill();
				}
			}
		}
		if (vs != null) {
			vs *= sFrict;
			scale += vs * tmod;
			setScale(scale);
		}
	}
	// (kill: deathScore is never set in Cyclopean)
}
