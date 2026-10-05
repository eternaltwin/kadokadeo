package paradice;

// Phys.mt of the original
class Phys extends Sprite {
	public var ray:Float;

	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;

	public function new(mc:MC) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
	}

	override public function update() {
		super.update();

		if (weight != null) {
			vy += weight * Timer.tmod;
		}

		if (frict != null) {
			// (rounded: the bomb falls with it, see Cs.q)
			var f = Cs.q(Math.pow(frict, Timer.tmod));
			vx *= f;
			vy *= f;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
	}

	public function speedToward(o:Sprite, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Cs.mm(-lim, dx * c, lim);
		vy += Cs.mm(-lim, dy * c, lim);
	}
}
