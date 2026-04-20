package popcorn;

import mt.bumdum.Sprite;
import mt.Timer;

class Phys extends mt.bumdum.Phys {
	public var flOrient:Bool;
	public var ray:Float;
	public var bouncer:Bouncer;

	public function new(mc:ASprite) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
	}

	override public function update():Void {
		var prevx = x;
		var prevy = y;
		super.update();
		x = prevx;
		y = prevy;

		if (bouncer != null) {
			bouncer.update();
		} else {
			x += vx * Timer.tmod;
			y += vy * Timer.tmod;
		}
		if (flOrient) {
			var sens = 1;
			if (vx < 0)
				sens = -1;

			root._xscale = sens * 100;
			root._prevState.xscale = root._curState.xscale;
			root._rotation = Math.atan2(vy, vx) / 0.0174;

			if (vx < 0)
				root._rotation += 180;
		}
	}

	public function removeBouncer():Void {
		x = bouncer.px + bouncer.ox;
		y = bouncer.py + bouncer.oy;
		bouncer.parc = 0;
		bouncer = null;
	}
}
