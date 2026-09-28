package magmax.monsters;

import common_haxe_avm1.display.BBox;
import mt.Timer;

class Firebomb extends Monster {
	public function new(g) {
		mc = cast g.dmanager.empty(1);
		var m = cast mc.attachMovie("monster1", "sub", 0);
		mc.sub = cast m;
		mc.sub.col = mc.sub.attachBBox(new BBox(KadoKadeoManager.S(-9.5), KadoKadeoManager.S(-12), KadoKadeoManager.S(19), KadoKadeoManager.S(19)));
		var f = mc.attachMovie("monster1Flames", "flames", 1);
		f.play();
		f.loop = true;
		f._rotation = 90;

		super(g, 0);
	}

	override public function init() {
		super.init();

		pv = 5;
		nsteps = 10;
		nextStep();
		dx = next.x - x;
		dy = next.y - y;
		speed = KadoKadeoManager.S(2 + game.level / 40);
	}

	override public function nextStep() {
		next = genRandPos((--nsteps) <= 0);
		if (dx != null && Seed.random(5) == 0) {
			fire3();
			wait = 2;
		}
	}

	override public function mobTouched() {
		var b = game.dmanager.attach("boum", Cs.PLAN_PART);
		b.play();
		b.removeOnFrame = b._totalframes;
		b._x = x;
		b._y = y;
	}

	override public function mobUpdate():Bool {
		var tdx = next.x - x;
		var tdy = next.y - y;
		var p = Math.pow(0.95, Timer.tmod);
		dx = dx * p + tdx * (1 - p);
		dy = dy * p + tdy * (1 - p);

		//----------
		var ang = Math.atan2(dy, dx);
		if (ang < 0)
			mc.sub.gotoAndStop(Std.int(-ang * 30 / Math.PI) + 1);
		else
			mc.sub.gotoAndStop(31 + Std.int((-ang + Math.PI) * 30 / Math.PI));
		//----------

		var s = Timer.tmod * speed / Math.sqrt(dx * dx + dy * dy);
		x += s * dx;
		y += s * dy;
		if (Math.abs(x - next.x) + Math.abs(y - next.y) < Timer.tmod * speed * 2) {
			if (nsteps <= 0) {
				mc.removeMovieClip();
				return false;
			}
			nextStep();
		}
		return true;
	}

	function fire3() {
		var a = Math.atan2(dy, dx);
		var s = KadoKadeoManager.S(4);
		game.tirs.push(new Tir(game, 1, x, y, s * Math.cos(a), s * Math.sin(a)));
		game.tirs.push(new Tir(game, 1, x, y, s * Math.cos(a + 0.2), s * Math.sin(a + 0.2)));
		game.tirs.push(new Tir(game, 1, x, y, s * Math.cos(a - 0.2), s * Math.sin(a - 0.2)));
	}
}
