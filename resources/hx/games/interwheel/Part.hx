package interwheel;

import common_haxe_avm1.KKApi;
import mt.Timer;

class Part extends Phys {
	public var timer:Float;
	public var fadeType:Float;
	public var fadeLimit:Float;

	public var scale:Float;
	public var vr:Float;
	public var vs:Float;
	public var rFrict:Float;
	public var sFrict:Float;
	public var deathScore:Int;

	public function new(mc) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
		rFrict = 1;
		sFrict = 1;
		untyped root.obj = this;
	}

	public function setScale(sc) {
		scale = sc;
		root._xscale = sc;
		root._yscale = sc;
	}

	public override function update() {
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
						root._alpha = c * 100;
				}
				if (timer < 0) {
					kill();
				}
			}
		}
		if (vs != null) {
			vs *= sFrict;
			scale += vs * Timer.tmod;
			setScale(scale);
		}
	}

	public override function kill() {
		if (deathScore != null)
			KKApi.addScore(deathScore);
		super.kill();
	}
}
