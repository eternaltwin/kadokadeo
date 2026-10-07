package kanjigaiden;

// Phys.hx of the original (a copy of mt.bumdum.Phys). Kanji Gaiden only uses vx / vy (the monkeys): the other fields
// stay null like in the original, their branches are kept for the order of the update. Port: towardSpeed and the
// fades of `timer` (never set) are left out.
class Phys extends Sprite {
	public var frict:Null<Float>;

	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;
	public var fr:Null<Float>;
	public var vsc:Null<Float>;
	public var sleep:Null<Float>;
	public var weight:Null<Float>;
	public var alpha:Float;

	public function new(?mc:MC) {
		super(mc);
		vx = 0;
		vy = 0;
		alpha = 100;
	}

	override public function update() {
		if (sleep != null) {
			sleep--;
			if (sleep < 0) {
				sleep = null;
				root._visible = true;
				root.play();
			}
			return;
		}

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

		if (vr != null)
			root._rotation += vr * Timer.tmod;
		if (fr != null)
			vr *= Math.pow(fr, Timer.tmod);
		if (vsc != null) {
			root._xscale *= Math.pow(vsc, Timer.tmod);
			root._yscale = root._xscale;
		}

		super.update();
	}
}
