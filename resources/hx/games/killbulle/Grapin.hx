package killbulle;

import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;
import kado.Seed;
import mt.Timer;
import mt.bumdum.Lib;

class Grapin {
	static var BASEY = Cs.MINY - KadoKadeoManager.I(30);

	public var game:Game;
	public var mc:ASprite;
	public var cordes:Array<ASprite>;
	public var y:Float;
	public var x:Float;
	public var speed:Float;
	public var rot:Bool;
	public var superg:Bool;

	public function new(g:Game) {
		game = g;
		superg = (game.hero.super_grapin_time > 0);
		mc = game.dmanager.attach("grapin" + (superg ? 2 : 1), Cs.PLAN_GRAPIN);
		mc.loop = true;
		mc.play();
		cordes = [];
		x = game.hero.x;
		y = BASEY;
		speed = KadoKadeoManager.I(8);
		mc._xscale = 100;
		mc._yscale = 100;
	}

	function destroyCordes():Bool {
		var i = 0;
		while (i < cordes.length) {
			var c = cordes[i];
			c._alpha -= 10 * Timer.tmod;
			if (c._alpha <= 0) {
				c.removeMovieClip();
				cordes.splice(i--, 1);
			}
			i++;
		}
		speed *= Math.pow(1.05, Timer.tmod);
		if (rot) {
			mc._rotation += 40 * Timer.tmod;
			mc._x += speed / 6 * Timer.tmod;
			mc._y += Math.abs(speed) / 3 * Timer.tmod;
			mc._xscale *= Math.pow(0.98, Timer.tmod);
			mc._yscale = mc._xscale;
		} else
			mc._y -= speed * Timer.tmod;
		if (mc._y > KadoKadeoManager.I(320) || mc._y < -KadoKadeoManager.I(20))
			mc.removeMovieClip();
		return cordes.length > 0 || mc._name != null;
	}

	function hits():Bool {
		if (game.hero.died)
			return false;

		var gx = Num.q(x);
		var gy = Num.q(y);
		for (b in game.blobs) {
			var s = Std.int(KadoKadeoManager.S(b.size) / 2);
			var bx = Num.q(b.x);
			var by = Num.q(b.y);
			if (gx >= bx - s && gx <= bx + s && gy <= by + s) {
				b.hit();
				rot = (gy >= by);
				if (rot) {
					game.dmanager.swap(mc, 1);
					if (Seed.random(2) == 0)
						speed *= -1;
				}

				var pts = Std.int(b.size / 2) * KKApi.val(Cs.C20);
				game.stats.s++;
				game.stats.ts += pts;
				game.stats.p.push(Std.int(b.size));
				if (game.blob_timer > 0) {
					game.stats.bp[0][game.stats.bp[0].length - 1] += 1;
				}
				if (game.hero.super_grapin_time > 0) {
					game.stats.bp[1][game.stats.bp[1].length - 1] += 1;
				}
				KadoKadeoManager.kkm.addScore(KKApi.const(pts));

				if (superg) {
					speed = Math.abs(speed);
					rot = false;
					continue;
				}
				return true;
			}
		}
		return false;
	}

	public function update():Bool {
		y = Num.q(y - speed * Timer.tmod);

		var ncordes = 1 + Std.int((BASEY - y) / (KadoKadeoManager.I(25)));
		for (i in 0...ncordes) {
			var c = cordes[i];
			if (c == null) {
				c = game.dmanager.attach("corde", Cs.PLAN_CORDE);
				c.loop = true;
				c.play();
				c._y = BASEY - KadoKadeoManager.I(25) * (i - 1);
				c._xscale = 100;
				cordes.push(c);
			}
			c._yscale = 100;
			c._x = x;
		}
		// cordes[ncordes - 1]._yscale = (cordes[ncordes - 1]._y - y) * 4;

		var h = hits();

		mc._x = x;
		mc._y = y;

		if ((y < -KadoKadeoManager.I(100)) || h) {
			if (y < -KadoKadeoManager.I(100))
				mc.removeMovieClip();
			game.addUpdate(destroyCordes);
			return false;
		}
		return true;
	}
}
