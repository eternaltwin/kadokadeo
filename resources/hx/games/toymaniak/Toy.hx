package toymaniak;

import toymaniak.Gfx.ToyMC;

class Toy {
	var game:Game;
	var rail:Rail;

	public var mc:ToyMC;
	public var x:Float;

	var kdo:Bool = false;

	public var lock:Bool = false;
	public var t:Int;

	// the frame of each type (a static of the original: Game.new changes TOYS[3] once in a while, reset there)
	public static var TOYS:Array<Int>;

	public static function resetToys() {
		TOYS = [1, 4, 5, 2, 6, 8, 9];
	}

	public function new(g:Game, t:Int, r:Rail, flCursor:Bool) {
		game = g;
		rail = r;
		mc = g.dmanager.add(new ToyMC(), 1);
		setType(t);
		if (!flCursor) {
			mc.but.onPress = game.selectToy.bind(this);
			mc.but._alpha = 0;
		}
		// (the toy in hand has no rail: null.pos is undefined in Flash, the _y NaN is ignored)
		mc._y = r == null ? Math.NaN : Const.RAIL_Y_BASE + Const.RAIL_Y_DELTA * r.pos;
		x = 350;
	}

	public function setType(t:Int) {
		this.t = t;
		if (t == -1) {
			mc.gotoAndStop(20);
			mc.but.useHandCursor = false;
		} else {
			mc.but.useHandCursor = true;
			mc.gotoAndStop(TOYS[t]);
		}
	}

	public function update(dx:Float):Bool {
		x -= dx;

		var center = Const.RAIL_END;
		var delta = 10;

		if (x >= center - delta && x <= center + delta) {
			lock = true;
			if (t != -1 && t < Const.BONUS_PLUS20) {
				var p = 1 - Math.abs(center - x) / delta;
				if (!kdo && x <= center)
					p = 1;
				rail.cruncher._y = -50 + p * 35;
			}
		}

		if (!kdo && x <= Const.RAIL_END) {
			rail.active(this);
			kdo = true;
			if (t != -1 && t != Const.BONUS_PLUS20 && t != Const.BONUS_X2 && t != Const.BONUS_SPEED)
				mc.gotoAndStop(7);
		}
		mc._x = Std.int(x);
		if (x < -30) {
			destroy();
			return false;
		}
		return true;
	}

	public function destroy() {
		mc.removeMovieClip();
	}
}
