package kaskade2;

import mt.Timer;

class Bille {
	public static var COS = Math.cos(Math.PI / 4);
	public static var SIN = Math.sin(Math.PI / 4);

	public static var INV_COS = Math.cos(-Math.PI / 4);
	public static var INV_SIN = Math.sin(-Math.PI / 4);

	public var mc:ASprite;
	public var star:ASprite;
	public var id:Int;
	public var group:Array<Bille>;
	public var px:Float;
	public var py:Float;

	public var gx:Float;
	public var gy:Float;

	public function new(game:Game, px, py) {
		// star = downcast(mc).star;
		if (game.nlevels == Const.MAXCOLORS)
			id = Const.MAXCOLORS - 1;
		else
			id = game.random(game.nlevels);
		mc = game.dmanager.attach("bille/bille_" + (id + 1), Const.PLAN_BILLE);
		mc.gotoAndStop(id + 1);
		mc._xscale = 0;
		mc._yscale = 0;
		setPos(px, py);
		activate(false);
	}

	public function setPos(x, y) {
		px = x * Const.BILLE_RAY - (Const.LVL_WIDTH * Const.BILLE_RAY) / 2;
		py = y * Const.BILLE_RAY - (Const.LVL_HEIGHT * Const.BILLE_RAY) / 2;
		move();
	}

	public function move() {
		mc._x = px * COS - py * SIN + Const.DELTA_X;
		mc._y = px * SIN + py * COS + Const.DELTA_Y;
	}

	public function activate(b) {
		// downcast(mc).sub.gotoAndStop(b ? 2 : 1);
	}

	public function gravityLeft() {
		gx = Const.BILLE_RAY;
		gy = 0;
	}

	public function gravityDown() {
		gx = 0;
		gy = Const.BILLE_RAY;
	}

	public function gravityMain() {
		var s:Float = 10 * Timer.tmod;
		if (gx > 0) {
			if (gx >= s)
				gx -= s;
			else {
				s = gx;
				gx = 0;
			}
			px += s;
		}
		if (gy > 0) {
			if (gy >= s)
				gy -= s;
			else {
				s = gy;
				gy = 0;
			}
			py += s;
		}
		move();
		return (gx != 0 || gy != 0);
	}
}
