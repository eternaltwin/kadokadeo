package cyclopean;

class Phys extends Sprite {
	public var flOrient:Bool = false;

	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;
	public var bouncer:Bouncer;

	public function new(mc:MC) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
	}

	override public function update():Void {
		var tmod = Game.tmod;
		if (vr != null) {
			root._rotation += vr * tmod;
		}
		if (weight != null) {
			vx += Cs.game.gcos * weight * tmod;
			vy += Cs.game.gsin * weight * tmod;
		}
		if (frict != null) {
			var f = Cs.pow(frict, tmod);
			vx *= f;
			vy *= f;
		}
		if (bouncer != null) {
			bouncer.update();
		} else {
			x += vx * tmod;
			y += vy * tmod;
		}
		if (flOrient) {
			root._rotation = Cs.atan2(vy, vx) / 0.0174;
		}
		super.update();
	}
}
