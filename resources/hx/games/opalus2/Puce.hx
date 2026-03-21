package opalus2;

import mt.bumdum.Phys;

class Puce extends Phys {
	var a:Float;

	public function new(mc) {
		super(mc);
		Cs.game.puceList.push(this);
	}

	public override function kill() {
		Cs.game.puceList.remove(this);
		super.kill();
	}
}
