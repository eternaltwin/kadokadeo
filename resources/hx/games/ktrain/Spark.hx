package ktrain;

// Spark.hx of the original: a spark of the brake, stretched along its speed
class Spark extends Phys {
	public function new(mc:MC) {
		super(mc);
	}

	override public function update() {
		var ox = x;
		var oy = y;
		super.update();

		var dx = x - ox;
		var dy = y - oy;
		root._rotation = Math.atan2(dy, dx) / 0.0174;
		root._xscale = Math.sqrt(dx * dx + dy * dy) * 100;
	}
}
