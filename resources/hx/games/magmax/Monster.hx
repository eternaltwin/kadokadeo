package magmax;

import common_haxe_avm1.display.BBox;
import pixi.filters.colormatrix.ColorMatrixFilter;
import kado.KadoKadeoManager;
import mt.Timer;

class SubSprite extends ASprite {
	public var col:BBox;
}

class MonsterMcSprite extends ASprite {
	public var sub:SubSprite;
}

class Monster {
	public var mc:MonsterMcSprite;

	var game:Game;
	var type:Int;
	var x:Float;
	var y:Float;
	var dx:Float;
	var dy:Float;
	var speed:Float;
	var nsteps:Int;
	var ang:Float;
	var ray:Float;
	var time:Float;
	var wait:Float;
	var flag:Bool;
	var next:{x:Float, y:Float};
	var pv:Int;
	var flash_time:Float;
	var flashMatrixFilter:ColorMatrixFilter;

	public function new(g, t) {
		game = g;
		type = t;
		init();
		flashMatrixFilter = new ColorMatrixFilter();
		mc.filters = [flashMatrixFilter];
	}

	function genRandPos(out) {
		var x = KadoKadeoManager.S(Seed.random(260) + 20);
		var y = KadoKadeoManager.S(Seed.random(260) + 20);
		if (out) {
			switch (Seed.random(4)) {
				case 0:
					x = KadoKadeoManager.I(-20);
				case 1:
					x = KadoKadeoManager.I(320);
				case 2:
					y = KadoKadeoManager.I(-20);
				case 3:
					y = KadoKadeoManager.I(320);
			}
		}
		return {x: x, y: y};
	}

	function init() {
		var p = genRandPos(true);
		x = p.x;
		y = p.y;

		var ddx = x - game.hero.x;
		var ddy = y - game.hero.y;
		var d = Math.sqrt(ddx * ddx + ddy * ddy);
		if (d < KadoKadeoManager.I(70)) {
			init();
			return;
		}

		mc._x = x;
		mc._y = y;
	}

	public function nextStep() {}

	public function mobTouched() {}

	public function touched(t:Tir) {
		pv -= t.pow;

		if (pv > 0) {
			if (!game.game_over)
				KadoKadeoManager.kkm.addScore(Cs.MONSTER_POINTS[type]);
			flash_time = 1;
			var vx = x - game.hero.x;
			var vy = y - game.hero.y;
			var v = Math.sqrt(vx * vx + vy * vy);
			var d = Math.sqrt(dx * dx + dy * dy);
			dx += vx * d / v;
			dy += vy * d / v;
			return;
		}

		game.doCombo();

		game.stats.k[type]++;
		mc.removeMovieClip();
		game.monsters.remove(this);

		{
			var bt = Cs.randomProbas(Cs.BONUS);
			var b:magmax.Game.BonusSprite = cast game.dmanager.attach("bonus" + (bt + 1), Cs.PLAN_BONUS);
			b.col = b.attachBBox(switch (bt) {
				case 0 | 1 | 2:
					new BBox(KadoKadeoManager.S(-25), KadoKadeoManager.I(-21), KadoKadeoManager.S(48.5), KadoKadeoManager.I(41));
				case 3 | 4 | 5:
					new BBox(KadoKadeoManager.I(-23), KadoKadeoManager.I(-29), KadoKadeoManager.S(45.5), KadoKadeoManager.I(47));
				case _:
					throw 'Unknown bonus type: $bt';
			});
			b._x = x;
			b._y = y;
			if (b._x < KadoKadeoManager.I(10))
				b._x = KadoKadeoManager.I(10);
			if (b._y < KadoKadeoManager.I(10))
				b._y = KadoKadeoManager.I(10);
			if (b._x > KadoKadeoManager.I(290))
				b._x = KadoKadeoManager.I(290);
			if (b._y > KadoKadeoManager.I(290))
				b._y = KadoKadeoManager.I(290);
			b.t = bt;
			b.time = 15;
			b.play();
			b.loop = true;
			game.bonus.push(b);
		}

		mobTouched();
	}

	public function mobUpdate():Bool {
		return true;
	}

	public function mobWait() {}

	public function update() {
		var retval = true;

		if (flash_time > 0) {
			flash_time -= Timer.tmod * 0.15;
			if (flash_time < 0)
				flashMatrixFilter.reset();
			else {
				flashMatrixFilter.matrix = [
					1, 0, 0, 0, flash_time,
					0, 1, 0, 0, flash_time,
					0, 0, 1, 0, flash_time,
					0, 0, 0, 1,          0
				];
			}
		}

		if (wait > 0) {
			wait -= Timer.deltaT;
			mobWait();
		} else {
			retval = mobUpdate();
		}

		mc._x = x;
		mc._y = y;
		return retval;
	}
}
