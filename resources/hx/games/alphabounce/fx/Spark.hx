package alphabounce.fx;

import mt.bumdum.Phys;

class Spark extends Phys {
	// length of the line of the picture (Flash px)
	var len:Float;

	public function new(mc:ASprite, len:Float) {
		super(mc);
		this.len = len;
	}

	override public function update() {
		var vit = Math.sqrt(vx * vx + vy * vy);
		var a = Math.atan2(vy, vx);
		root._xscale = vit / len * 100;
		root._rotation = a / 0.0174;

		super.update();
	}
}
