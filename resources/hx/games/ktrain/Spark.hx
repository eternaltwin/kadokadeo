package ktrain;

// Spark.hx of the original: a spark of the brake, stretched along its speed
class Spark extends Phys {
	var placed = false;

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

		// port: attached at (-100, -100) (Sprite), placed under the train by its first update: shown there at once,
		// not interpolated from the top left corner
		if (!placed) {
			placed = true;
			root.teleport();
		}
	}
}
