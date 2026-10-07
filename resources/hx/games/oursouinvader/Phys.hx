package oursouinvader;

// Phys.mt of the original
class Phys extends Sprite {
	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;

	public var flash:Null<Float>;

	public function new(mc:MC) {
		super(mc);
		vx = 0;
		vy = 0;
	}

	override public function update() {
		super.update();

		if (weight != null) {
			vy += weight * Timer.tmod;
		}

		if (frict != null) {
			// (rounded: Math.pow of the gameplay, see Cs.q)
			var f = Cs.q(Math.pow(frict, Timer.tmod));
			vx *= f;
			vy *= f;
		}
		if (vr != null) {
			if (frict != null)
				vr *= frict;
			root._rotation += vr * Timer.tmod;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
	}

	public function updateFlash() {
		if (flash != null) {
			var prc = Math.min(flash, 100);
			flash *= 0.6;
			if (flash < 2) {
				flash = null;
				prc = 0;
			}
			Cs.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	// (var a = getAng(o): computed and unused, not ported)
	public function speedToward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Cs.mm(-lim, dx * c, lim);
		vy += Cs.mm(-lim, dy * c, lim);
	}
}
