package interwheel;

import mt.Timer;
import mt.bumdum.Phys;

class Part extends Phys {
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
	}

	public override function update() {
		if (vr != null) {
			vr *= rFrict;
		}
		if (vs != null) {
			vs *= sFrict;
			scale += vs * Timer.tmod;
		}
		super.update();
	}

	public override function kill() {
		if (deathScore != null)
			Cs.game.kkm.addScore(deathScore);
		super.kill();
	}
}
