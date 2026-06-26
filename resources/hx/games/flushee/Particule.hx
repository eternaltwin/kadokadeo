package flushee;

import kado.Seed;
import mt.Timer;

class Particule {
	var mc:ASprite;
	var shade:ASprite;

	var px:Float;
	var py:Float;

	var dx:Float;
	var dy:Float;
	var speed:Float;
	var time:Float;
	var ds:Float;

	var scale:Float;

	public function new(g:Game, id:Int, x:Float, y:Float) {
		mc = g.dmanager.attach("mcPart", Cs.PLAN_PART);
		mc.gotoAndStop(id + 1);
		shade = g.dmanager.attach("mcPart", Cs.PLAN_PART_SHADE);
		shade.gotoAndStop(6);
		scale = Seed.randomVfx(50) + 70;
		ds = 0;
		time = (0.4 + Seed.randomVfx(100) / 100) / 2;
		speed = (3 + Seed.randomVfx(10) / 10) * Cs.NEW_GEN_SCALE;
		dx = (Seed.randomVfx(100) - 50) / 50;
		dy = -Seed.randomVfx(100) / 50;
		px = x + dx * speed * 2;
		py = y + dy * speed * 2;
	}

	public function update():Bool {
		var s = speed * Timer.tmod;
		speed += Timer.tmod / 10 * Cs.NEW_GEN_SCALE;
		dy += 0.07 * Timer.tmod * Cs.NEW_GEN_SCALE;
		px += dx * s;
		py += dy * s;
		if (time > 0) {
			time -= Timer.deltaT;
			if (time <= 0)
				ds = 10;
		}
		scale -= ds * Timer.tmod;
		if (scale <= 0) {
			mc.removeMovieClip();
			shade.removeMovieClip();
			return false;
		}
		mc._xscale = scale;
		mc._yscale = scale;
		shade._xscale = scale + 40;
		shade._yscale = scale + 40;
		mc._x = px;
		mc._y = py;
		shade._x = px;
		shade._y = py;
		return true;
	}
}
