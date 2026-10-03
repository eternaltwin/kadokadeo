package twinspirit.bh;

class Sinuso extends Behaviour {
	var xmin:Float;
	var xmax:Float;
	var ymin:Float;
	var ymax:Float;

	var vx:Float;
	var vy:Float;

	var dcx:Float;
	var dcy:Float;

	public function new(xmin:Float, xmax:Float, ymin:Float, ymax:Float, vx:Float, vy:Float) {
		this.xmin = xmin;
		this.xmax = xmax;
		this.ymin = ymin;
		this.ymax = ymax;
		this.vx = vx;
		this.vy = vy;
		super();
	}

	override public function init(b:Bad) {
		super.init(b);
		dcx = (1 - b.x / Cs.mcw) * 314;
		dcy = 0;
	}

	override public function update() {
		dcx = (dcx + vx) % 628;
		dcy = (dcy + vy) % 628;

		var tx = xmin + b.ray + (1 + Cs.cos(dcx * 0.01)) * (xmax - (xmin + b.ray * 2)) * 0.5;
		var ty = ymin + b.ray + (1 + Cs.cos(dcy * 0.01)) * (ymax - (ymin + b.ray * 2)) * 0.5;

		var c = 0.1;

		b.vx += (tx - b.x) * c;
		b.vy += (ty - b.y) * c;

		b.vx *= 0.9;
		b.vy *= 0.9;
	}
}
