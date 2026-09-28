package magmax;

import pixi.filters.colormatrix.ColorMatrixFilter;
import common_haxe_avm1.display.BBox;
import common_haxe_avm1.KeyboardManager;
import kado.KadoKadeoManager;
import mt.Timer;

class HeroMcSprite extends ASprite {
	public var blob:ASprite;
	public var eyes:ASprite;
	public var col:BBox;
}

class Hero {
	public var x:Float;
	public var y:Float;
	public var mc:HeroMcSprite;

	var game:Game;
	var ploc:ASprite;
	var speed:Float;
	var wait_tir:Float;
	var tang:Float;
	var ang:Float;
	var tspeed:Float;
	var pow:Int;
	var bonus_time:Float;

	public function new(g) {
		game = g;
		wait_tir = 0;
		mc = cast game.dmanager.empty(Cs.PLAN_HERO);
		mc.blob = mc.attachMovie("heroBlob", "blob", 0);
		mc.blob.play();
		mc.blob.loop = true;
		mc.eyes = mc.attachMovie("hero", "eyes", 1);
		mc.col = mc.attachBBox(new BBox(KadoKadeoManager.S(-4), KadoKadeoManager.S(-4), KadoKadeoManager.S(9.5), KadoKadeoManager.S(9.5)));
		x = KadoKadeoManager.I(150);
		y = KadoKadeoManager.I(150);
		ang = 0;
		pow = 1;
		tang = 0;
		speed = KadoKadeoManager.S(3.5);
		tspeed = KadoKadeoManager.S(8);
		bonus_time = 0;
	}

	function genTir() {
		var t = new Tir(game, pow == 2 ? 3 : 0, x, y, Math.cos(tang) * tspeed, Math.sin(tang) * tspeed);
		game.tirs.push(t);
		ploc = game.dmanager.attach("plop", Cs.PLAN_HERO);
		ploc.play();
		ploc._x = x;
		ploc._y = y;
		if (pow == 2) {
			t.pow = 2;
		} else if (bonus_time > 0) {
			setColor(t.mc, 0xFF0000);
			setColor(ploc, 0xFF0000);
		}
		ploc._rotation = tang * 180 / Math.PI;
	}

	function moyAng(a:Float, b:Float):Float {
		if (Math.abs(a - b) > Math.PI) {
			if (b < a)
				b += Math.PI * 2;
			else
				b -= Math.PI * 2;
		}
		var p = Math.pow(0.7, Timer.tmod);
		a = a * p + b * (1 - p);
		while (a <= Math.PI)
			a += Math.PI * 2;
		while (a > Math.PI)
			a -= Math.PI * 2;
		return a;
	}

	function setColor(mc:ASprite, col) {
		var cm = Reflect.getProperty(mc, "__colorMatrixFilter");
		if (cm == null) {
			cm = new ColorMatrixFilter();
			mc.filters = [cm];
			Reflect.setProperty(mc, "__colorMatrixFilter", cm);
		}

		cm.matrix = [
			1, 0, 0, 0, ((col >> 16) & 0xFF) / 255,
			0, 1, 0, 0,  ((col >> 8) & 0xFF) / 255,
			0, 0, 1, 0,         (col & 0xFF) / 255,
			0, 0, 0, 1,                          0
		];
	}

	public function update() {
		var dx = 0, dy = 0;

		if (KeyboardManager.isDown(KeyboardManager.LEFT))
			dx--;
		if (KeyboardManager.isDown(KeyboardManager.RIGHT))
			dx++;
		if (KeyboardManager.isDown(KeyboardManager.UP))
			dy--;
		if (KeyboardManager.isDown(KeyboardManager.DOWN))
			dy++;

		if (bonus_time > 0) {
			bonus_time -= Timer.deltaT;
			if (bonus_time <= 0) {
				speed = KadoKadeoManager.S(3);
				pow = 1;
				setColor(mc, 0);
			}
		}

		if (dx != 0 || dy != 0) {
			var d = Timer.tmod * speed / Math.sqrt(dx * dx + dy * dy);
			if (!KeyboardManager.isDown(KeyboardManager.SPACE) && !KeyboardManager.isDown(KeyboardManager.CONTROL))
				tang = Math.atan2(dy, dx);
			x += dx * d;
			y += dy * d;
			if (ploc != null) {
				ploc._x += dx * d;
				ploc._y += dy * d;
			}
		}

		if (x < KadoKadeoManager.I(15))
			x = KadoKadeoManager.I(15);
		if (y < KadoKadeoManager.I(20))
			y = KadoKadeoManager.I(20);
		if (x > KadoKadeoManager.I(285))
			x = KadoKadeoManager.I(285);
		if (y > KadoKadeoManager.I(290))
			y = KadoKadeoManager.I(290);

		ang = moyAng(ang, tang);
		if (ang < 0)
			mc.eyes.gotoAndStop(Std.int(-ang * 30 / Math.PI) + 1);
		else
			mc.eyes.gotoAndStop(31 + Std.int((-ang + Math.PI) * 30 / Math.PI));

		if (wait_tir > 0)
			wait_tir -= Timer.deltaT;
		else if (KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(KeyboardManager.CONTROL)) {
			wait_tir = 0.2 / pow;
			genTir();
		}

		for (m in game.monsters) {
			if (m != null && mc.col.hitTestBbox(m.mc.sub.col))
				return false;
		}
		var i = 0;
		while (i < game.bonus.length) {
			var b = game.bonus[i];
			b.time -= Timer.deltaT;
			if (mc.col.hitTestBbox(b.col)) {
				game.stats.b[b.t]++;
				switch (b.t) {
					case 3:
						setColor(mc, 0xFF0000);
						speed = KadoKadeoManager.S(7);
						bonus_time += 8;
					case 4:
						pow = 2;
						bonus_time += 5;
					case 0 | 1 | 2:
						KadoKadeoManager.kkm.addScore(Cs.BONUS_POINTS[b.t]);
				}
				b.removeMovieClip();
				game.bonus.splice(i, 1);
			} else if (b.time < 0) {
				b._xscale -= 10 * Timer.tmod;
				b._yscale = b._xscale;
				if (b._xscale < 0) {
					b.removeMovieClip();
					game.bonus.splice(i, 1);
				} else
					i++;
			} else
				i++;
		}

		mc._x = x;
		mc._y = y;
		return true;
	}
}
