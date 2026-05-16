package kanji;

import mt.Timer;
import mt.bumdum.Lib;

class Bonus {
	var game:Game;
	var mc:ASprite;

	public var t:Int;

	var s:Float;

	public function new(g, p, t) {
		s = 5;
		game = g;
		this.t = t;
		mc = game.dmanager.attach("bonus" + (t + 1), Cs.PLAN_BONUS);
		mc._x = p.x;
		mc._y = p.y;
		mc.loop = true;
		mc.play();
		mc._xscale = s;
		mc._yscale = s;
		game.entities.push(mc);
	}

	public function update() {
		if (s < 100) {
			s += Timer.tmod * 10;
			if (s >= 100) {
				s = 100;
			}
			mc._xscale = s;
			mc._yscale = s;
		}

		var dx = Num.q(game.hero.mc._x - mc._x);
		var dy = Num.q((game.hero.mc._y - 20 * Cs.NEW_GEN_SCALE) - mc._y);
		if (dx * dx + dy * dy < Cs.BONUS_RAY2) {
			var p = game.dmanager.attach("FXVanish", Cs.PLAN_HERO + 1);
			p.play();
			p.removeOnFrame = 25;
			p._x = mc._x;
			p._y = mc._y;
			game.entities.remove(mc);
			mc.removeMovieClip();
			game.getBonus(this);
			return false;
		}

		return true;
	}
}
