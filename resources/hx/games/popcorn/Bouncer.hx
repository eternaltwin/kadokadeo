package popcorn;

import mt.Timer;

class Bouncer {
	public var px:Int;
	public var py:Int;
	public var ox:Float;
	public var oy:Float;
	public var frict:Float;
	public var sp:Phys;
	public var parc:Float;

	public function new(sprite:Phys) {
		sp = sprite;
		px = Std.int(sp.x);
		py = Std.int(sp.y);
		ox = 0.5;
		oy = 0.5;
		frict = 1;
	}

	public function setPos(x:Float, y:Float):Void {
		px = Std.int(x);
		py = Std.int(y);
		sp.x = x;
		sp.y = y;
	}

	public function update():Void {
		parc = 1;
		var tr = 0;
		var vvx = sp.vx * Timer.tmod;
		var vvy = sp.vy * Timer.tmod;

		while (parc > 0) {
			var cx = null;
			var cy = null;

			if (vvx > 0) {
				cx = (1 - ox) / vvx;
			} else if (vvx < 0) {
				cx = ox / vvx;
			} else {
				cx = 1;
			}

			if (vvy > 0) {
				cy = (1 - oy) / vvy;
			} else if (vvy < 0) {
				cy = oy / vvy;
			} else {
				cy = 1;
			}

			var c = null;
			var sx = null;
			var sy = null;
			if (Math.abs(cx) < Math.abs(cy)) {
				c = Math.abs(cx);
				sx = Std.int(cx / c);
			} else {
				c = Math.abs(cy);
				sy = Std.int(cy / c);
			}

			var flCheck = true;
			if (c > parc) {
				c = parc;
				flCheck = false;
			}
			ox += vvx * c;
			oy += vvy * c;
			parc -= c;

			if (flCheck) {
				if (sx != null) {
					if (Cs.game.isFree(px + sx, py)) {
						px += sx;
						ox -= sx;
					} else {
						onBounce(sp.vx / Math.abs(sp.vx), 0);
						vvx *= -frict;
						sp.vx *= -frict;
					}
				}
				if (sy != null) {
					if (Cs.game.isFree(px, py + sy)) {
						py += sy;
						oy -= sy;
					} else {
						onBounce(0, sp.vy / Math.abs(sp.vy));
						vvy *= -frict;
						sp.vy *= -frict;
					}
				}
			}
		}
		if (sp.bouncer == this) {
			sp.x = px + ox;
			sp.y = py + oy;
		}
	}

	dynamic public function onBounce(vx:Float, vy:Float):Void {}

	dynamic public function onBounceGround():Void {}

	dynamic public function onBounceAngle(a:Float, n:Float):Void {}
}
