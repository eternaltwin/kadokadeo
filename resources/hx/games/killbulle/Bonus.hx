package killbulle;

import kado.KadoKadeoManager;
import mt.Timer;
import mt.bumdum.Lib;

class Bonus {
	public var game:Game;
	public var id:Int;
	public var mc:ASprite;
	public var x:Float;
	public var y:Float;
	public var dx:Float;
	public var dy:Float;

	public function new(g:Game, id:Int) {
		game = g;
		this.id = id;
		mc = game.dmanager.attach("bonus" + (id + 1), Cs.PLAN_BONUS);
		mc.play();
		mc.loop = true;
		mc._xscale = 50;
		mc._yscale = 50;
	}

	function activate():Void {
		switch (id) {
			case 0:
				game.flash(0x00FF00);
				game.blob_timer = 5;
			case 1:
				game.flash(0xFF0000);
				game.hero.super_grapin_time = 20;
			case 2:
				var b = game.blobs.copy();
				for (blob in b) {
					blob.hit();
				}
				game.flash(0x0000FF);
				game.hero.special();
			case 3:
				game.stats.b++;
				game.flash(0xFFFFFF);
				KadoKadeoManager.kkm.addScore(Cs.C5000);
			case _:
		}
	}

	public function fall():Void {
		dx = 0;
		dy = KadoKadeoManager.I(2);
		x = mc._x;
		y = mc._y;
		game.addUpdate(update);
	}

	function update():Bool {
		dy = Num.q(dy + KadoKadeoManager.S(0.9) * Timer.tmod);
		y = Num.q(y + dy * Timer.tmod);
		x = Num.q(x + dx * Timer.tmod);

		var my = Cs.MINY - KadoKadeoManager.I(10);
		if (y > my) {
			y = my * 2 - y;
			dy *= -0.5;
			if (Math.abs(dy) < KadoKadeoManager.I(1)) {
				dy = 0;
				y = my;
			}
		}

		var dx = Num.q(x - game.hero.x);
		var dy = Num.q(y - game.hero.y);
		var ray = KadoKadeoManager.I(30);
		if (dx * dx + dy * dy < ray * ray && !game.hero.died) {
			activate();
			mc.removeMovieClip();
			return false;
		}

		mc._x = x;
		mc._y = y;
		return true;
	}
}
