package kslash;

import pixi.core.text.Text;
import mt.Timer;
import mt.bumdum.Phys;

class Part extends Phys {
	public var vs:Float;
	public var flQueue:Bool;
	public var field:Text;

	public function new(mc) {
		super(mc);
	}

	public override function update() {
		super.update();
		if (sleep != null) {
			return;
		}

		if (vs != null) {
			scale = scale + (vs * Timer.tmod);
		}

		var ox = x;
		var oy = y;

		if (flQueue) {
			var dx = ox - x;
			var dy = oy - y;
			var a = Math.atan2(dy, dx);
			var d = Math.sqrt(dx * dx + dy * dy);
			var q = Cs.game.newPart("partQueue");
			q.x = x;
			q.y = y;
			q.root._rotation = a / 0.0174;
			q.root._xscale = d;
		}
	}

	public override function kill() {
		Cs.game.pList.remove(this);
		super.kill();
	}
}
