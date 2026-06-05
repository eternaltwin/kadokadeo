package kanjisnightmare;

import mt.bumdum.Lib.Num;
import mt.Timer;

class Phys extends mt.bumdum.Phys {
	public var ray:Float;

	public function new(mc) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
	}

	public function checkPlatCol() {
		//
		if (vy > 0) {
			var px = Num.q(x);
			var py = Num.q(y + ray);
			var oy = Num.q(py - vy * Timer.tmod);
			for (i in 0...Cs.game.platList.length) {
				var pl = Cs.game.platList[i];
				var ply = Num.q(pl.y);
				var plx = Num.q(pl.x);
				var plr = Num.q(pl.x + pl.w);
				if (oy < ply && py > ply && px > plx && px < plr) {
					y = pl.y - ray;
					land(pl);
					break;
				}
			}
		}
	}

	public function land(plat) {}

	public function speedToward(o, c, lim) {
		var a = getAng({x: o.x, y: o.y});
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Num.mm(-lim, dx * c, lim);
		vy += Num.mm(-lim, dy * c, lim);
	}

	public function isOut2(m:Float) {
		var px = x + Cs.game.map._x;
		var py = y + Cs.game.map._y;
		return (px < -m || px > Cs.mcw + m || py < -m || py > Cs.mch + m);
	}
}
