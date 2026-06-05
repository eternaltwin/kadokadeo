package zipzap;

import mt.deepnight.Color;
import mt.Timer;
import mt.bumdum.Lib;
import kado.Seed;

class Ballon {
	static var speed:Float = 0.05;
	static var factor:Float = 1.3;
	public static var ray:Float = 15 * factor * Cs.NEW_GEN_SCALE;

	var game:Game;
	var mc:ASprite;

	public var x:Float;
	public var y:Float;

	var dx:Float;
	var dy:Float;
	var a:Float;

	public var t:Int;

	public var timer:Float;
	public var mind:Float;
	public var tx:Float;
	public var ty:Float;

	public function new(g:Game, t:Int) {
		game = g;
		this.t = t;
		mc = game.dmanager.attach("ballon", Cs.PLAN_BALLON);
		mc.gotoAndStop(t + 1);
		x = Seed.random(300 * Cs.NEW_GEN_SCALE);
		y = -(20 * Cs.NEW_GEN_SCALE + Seed.random(300 * Cs.NEW_GEN_SCALE));
		dx = 0;
		dy = 0;
		nextStep();
		a = Seed.random(100) / 20;
		mc._x = x;
		mc._y = y;
		mc._xscale = 100 * factor;
		mc._yscale = 100 * factor;
	}

	function nextStep():Void {
		tx = Seed.random(200 * Cs.NEW_GEN_SCALE) + 50 * Cs.NEW_GEN_SCALE;
		ty = Seed.random(200 * Cs.NEW_GEN_SCALE) + 50 * Cs.NEW_GEN_SCALE;
		mind = ray * 2;
	}

	public function plop(sc:Int):Void {
		var p = game.dmanager.attach("plop", Cs.PLAN_PART);
		p.play();
		p._rotation = Seed.randomVfx(360);
		p.removeOnFrame = 30;
		p._x = mc._x;
		p._y = mc._y;
		var c = new Color(p);
		var colors = [0xE11B04, 0x5AE606, 0xFBC716, 0x584886];
		c.setRGB(colors[t]);

		var s = game.dmanager.attach("partScore" + (sc + 1), Cs.PLAN_PART);
		var compt = 0;
		s.onFrame.set(9, function() {
			compt = 10;
		});
		s.onFrame.set(11, function() {
			compt -= 1;
			if (compt > 0) {
				s.gotoAndPlay(10);
			}
		});
		s.removeOnFrame = 22;
		s.play();
		s._x = mc._x;
		s._y = mc._y;
	}

	public function destroy():Void {
		mc.removeMovieClip();
	}

	public function update(nb:Int):Bool {
		var s = Timer.tmod * speed;
		var ddx = Num.q(tx - x);
		var ddy = Num.q(ty - y);
		var dd = Num.q(Math.sqrt(ddx * ddx + ddy * ddy));
		var p = Math.pow(0.96, Timer.tmod);

		if (timer > 0) {
			timer -= Timer.tmod;
			if (timer <= 0) {
				nextStep();
			}
		}

		dx = dx * p + ddx * (1 - p);
		dy = dy * p + ddy * (1 - p);

		var r:Float = 1 * Cs.NEW_GEN_SCALE;
		if (x < 40 * Cs.NEW_GEN_SCALE) {
			dx += r;
		}
		if (y < 40 * Cs.NEW_GEN_SCALE) {
			dy += r;
		}
		if (x > 260 * Cs.NEW_GEN_SCALE) {
			dx -= r;
		}
		if (y > 260 * Cs.NEW_GEN_SCALE) {
			dy -= r;
		}

		if (dd < mind * Timer.tmod) {
			nextStep();
		}

		x = Num.q(x + dx * s);
		y = Num.q(y + dy * s);

		if (y > 280 * Cs.NEW_GEN_SCALE) {
			y = 280 * Cs.NEW_GEN_SCALE - (y - 280 * Cs.NEW_GEN_SCALE);
			dy = -Math.abs(dy);
			dx *= -1;
		}

		var l = game.bals;
		var n = l.length;
		for (i in (nb + 1)...n) {
			var b = l[i];
			var dx = Num.q(b.x - x);
			var dy = Num.q(b.y - y);
			r = Num.q(Math.sqrt(dx * dx + dy * dy));
			if (r < ray * 2) {
				var push = Num.q((ray * 2 - r) / 2);
				var ca:Float;
				var sa:Float;
				if (r > 0) {
					ca = Num.q(dx / r * push);
					sa = Num.q(dy / r * push);
				} else {
					ca = push;
					sa = 0;
				}
				x = Num.q(x - ca);
				y = Num.q(y - sa);
				b.x = Num.q(b.x + ca);
				b.y = Num.q(b.y + sa);
			}
		}

		mc._x = x;
		mc._y = y;
		return true;
	}
}
