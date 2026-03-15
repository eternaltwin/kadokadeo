package interwheel;

import mt.Timer;

class Phys extends Sprite {
	var weight:Float;
	var frict:Float;
	var vx:Float;
	var vy:Float;

	function new(mc) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
	}

	public override function update() {
		super.update();

		if (weight != null) {
			vy += weight * Timer.tmod;
		}

		if (frict != null) {
			var f = Math.pow(frict, Timer.tmod);
			vx *= f;
			vy *= f;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
	}

	public function speedToward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var a = getAng(o);
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Cs.mm(-lim, dx * c, lim);
		vy += Cs.mm(-lim, dy * c, lim);
	}
}
