package twinspirit.bh;

class Errant extends Behaviour {
	var waitBase:Float;
	var waitRnd:Float;
	var marginY:Float;

	var wait:Float;
	var rob:Robot;

	public function new(wb:Float, wr:Float, my:Float) {
		super();
		waitBase = wb;
		waitRnd = wr;
		marginY = my;
	}

	override public function init(b:Bad) {
		super.init(b);
		rob = b.robs[0];
		wait = 0;
	}

	override public function update() {
		if (wait-- < 0 || Cs.isOut(b.x, b.y, b.ray + 5, marginY))
			impulse();
	}

	function impulse() {
		var to = 0;
		var a = 0.0;
		while (true) {
			a = b.seed.rand() * 6.28;
			var d = 100;
			var tx = b.x + Cs.cos(a) * d;
			var ty = b.y + Cs.sin(a) * d;
			if (!Cs.isOut(tx, ty, b.ray, marginY))
				break;
			if (to++ > 100)
				break;
		}
		wait = waitBase + b.seed.rand() * waitRnd;
		rob.angle = a;
	}
}
