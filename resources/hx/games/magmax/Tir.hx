package magmax;

// Tir.mt of the original: a shot (t = 0: the hero's, 1: the 3 fireballs of the firebomb, 2: the 4 balls of the cyblock)
class Tir {
	var game:Game;

	public var mc:MC;

	var fromMonster:Bool;
	var x:Float;
	var y:Float;
	var dx:Float;
	var dy:Float;

	public var pow:Int;

	// cos / sin of mc._rotation (the bounds of the shot turn with it)
	var rcos:Float;
	var rsin:Float;

	public function new(g:Game, t:Int, x:Float, y:Float, dx:Float, dy:Float) {
		game = g;
		pow = 1;
		fromMonster = (t != 0);
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
		mc = game.dmanager.attach(new MC("tir"), Const.PLAN_TIR);
		mc.gotoAndStop(t + 1);
		mc._x = x;
		mc._y = y;
		var a = Const.q(Math.atan2(dy, dx));
		mc._rotation = a * 180 / Math.PI;
		rcos = Const.q(Math.cos(a));
		rsin = Const.q(Math.sin(a));
	}

	// Hero.setColor(t.mc, 0xFF0000) during the speed bonus: the red shot of the SWF (baked, see magmax_assets.py)
	public function setRed() {
		mc.setClip("tirRed");
	}

	// bounds of mc in the stage: the shapes of its frame and of its nested clip's frame, turned by its _rotation
	public function bounds():Array<Float> {
		var f = mc._currentframe;
		var nested = Data.TIR_LEAVES[f - 1];
		var n = 1;
		if (nested.length > 1)
			for (c in mc.clip.children) {
				var cc = Std.downcast(c, Clip);
				if (cc != null) {
					n = cc.frame;
					break;
				}
			}
		return Bounds.turned(nested[n - 1], rcos, rsin, mc._x, mc._y);
	}

	public function update():Bool {
		x += dx * Timer.tmod;
		y += dy * Timer.tmod;
		mc._x = x;
		mc._y = y;

		if (fromMonster) {
			if (Bounds.hit(game.hero.colBounds(), bounds()))
				game.gameOver();
		} else {
			var i = 0;
			var l = game.monsters;
			while (i < l.length) {
				var m = l[i];
				if (Bounds.hit(m.colBounds(), bounds())) {
					m.touched(this);
					mc.removeMovieClip();
					return false;
				}
				i++;
			}
		}

		if (x < -10 || y < -10 || x > 310 || y > 310) {
			mc.removeMovieClip();
			return false;
		}
		return true;
	}
}
