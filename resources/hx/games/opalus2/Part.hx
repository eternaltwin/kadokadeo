package opalus2;

import mt.Timer;
import mt.bumdum.Phys;

class Part extends Phys {
	var rFrict:Float;
	var deathScore:Int;

	public function new(mc) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
		rFrict = 1.2;
	}

	public override function update() {
		if (vr != null) {
			vr *= rFrict;
		}
		super.update();
	}

	public override function kill() {
		if (deathScore != null)
			Cs.game.kkm.addScore(deathScore);
		super.kill();
	}
}
