package zipzap;

import common_haxe_avm1.KeyboardManager;
import kado.Seed;
import mt.Timer;

class Hero {
	public var y:Float;
	public var mc:ASprite;

	var x:Float;
	var game:Game;
	var a:Float;
	var lock:Bool;

	public var moving:Null<Int>;

	var gameOver:Bool;

	public var ty:Null<Float>;

	var r:Float;

	public function new(g:Game) {
		game = g;
		mc = game.dmanager.attach("hero", Cs.PLAN_HERO);
		mc.onFrame.set(26, function() {
			mc.gotoAndPlay(1);
		});
		mc.onFrame.set(46, function() {
			mc.gotoAndPlay(1);
		});
		mc.stopOnFrame = [33, 50];
		a = 0;
		x = 25 * Cs.NEW_GEN_SCALE;
		y = 150 * Cs.NEW_GEN_SCALE;
		mc._x = x;
		mc._y = y;
		r = Seed.random(4) + 3;
	}

	public function action():Void {
		if (!lock) {
			lock = true;
			moving = (x < 150 * Cs.NEW_GEN_SCALE) ? 1 : -1;
			mc.gotoAndPlay(30);
			game.last = null;
		}
	}

	public function doGameOver():Void {
		gameOver = true;
		a = -1 * Cs.NEW_GEN_SCALE;
		mc.gotoAndStop(50);
	}

	public function update(steps:Int):Void {
		var dx = 20 * Cs.NEW_GEN_SCALE / steps;
		var dy = ((moving != null) ? 5 : 10) * Cs.NEW_GEN_SCALE / steps;

		if (gameOver) {
			a += 0.03 * Timer.tmod * Cs.NEW_GEN_SCALE;
			x += ((mc._xscale < 0) ? -1 : 1) * Timer.tmod / 2 * Cs.NEW_GEN_SCALE;
			y += a * Timer.tmod;

			if (y > 280 * Cs.NEW_GEN_SCALE) {
				y = 280 * Cs.NEW_GEN_SCALE - (y - 280 * Cs.NEW_GEN_SCALE);
				a = -Math.abs(a) * 0.8;
				r = Seed.random(10) - 4;
			}

			mc._rotation += r * Timer.tmod;
			mc._x = x;
			mc._y = y;
			return;
		}

		if (KeyboardManager.isDown(KeyboardManager.UP)) {
			y -= dy * Timer.tmod;
			if (y < 20 * Cs.NEW_GEN_SCALE) {
				y = 20 * Cs.NEW_GEN_SCALE;
			}
		} else if (KeyboardManager.isDown(KeyboardManager.DOWN)) {
			y += dy * Timer.tmod;
			if (y > 285 * Cs.NEW_GEN_SCALE) {
				y = 285 * Cs.NEW_GEN_SCALE;
			}
		}
		if (moving != null) {
			x += moving * dx * Timer.tmod;
			if (x > 275 * Cs.NEW_GEN_SCALE || x < 25 * Cs.NEW_GEN_SCALE) {
				if (x > 275 * Cs.NEW_GEN_SCALE) {
					x = 275 * Cs.NEW_GEN_SCALE;
				} else {
					x = 25 * Cs.NEW_GEN_SCALE;
				}
				mc._xscale = (x > 150 * Cs.NEW_GEN_SCALE) ? -100 : 100;
				mc.gotoAndPlay(40);
				moving = null;
			}
		} else {
			if (KeyboardManager.isDown(KeyboardManager.SPACE)
				|| (KeyboardManager.isDown(KeyboardManager.RIGHT) && x < 150 * Cs.NEW_GEN_SCALE)
				|| (KeyboardManager.isDown(KeyboardManager.LEFT) && x > 150 * Cs.NEW_GEN_SCALE)) {
				action();
			} else {
				lock = false;
			}
		}

		if (ty != null) {
			var p = Math.pow((moving == null) ? 0.7 : 0.99, Timer.tmod);
			y = y * p + ty * (1 - p);
			if (Math.abs(ty - y) < 5 * Cs.NEW_GEN_SCALE) {
				y = ty;
				ty = null;
			}
			if (y < 20 * Cs.NEW_GEN_SCALE) {
				y = 20 * Cs.NEW_GEN_SCALE;
			} else if (y > 285 * Cs.NEW_GEN_SCALE) {
				y = 285 * Cs.NEW_GEN_SCALE;
			}
		}

		a += Timer.tmod / (10 * steps);
		var tx = x + Math.cos(a) * 5 * Cs.NEW_GEN_SCALE;
		var ty = y + Math.sin(a) * 5 * Cs.NEW_GEN_SCALE;
		var p = Math.pow(0.7, Timer.tmod);
		var x = mc._x * p + tx * (1 - p);
		var y = mc._y * p + ty * (1 - p);
		mc._x = x;
		mc._y = y;

		if (moving != null) {
			var r = Ballon.ray + 5 * Cs.NEW_GEN_SCALE;
			r = r * r;
			var i = 0;
			while (i < game.getBalsLength()) {
				var b = game.bals[i];
				dx = x - b.x + 12 * Cs.NEW_GEN_SCALE;
				dy = y - b.y + 10 * Cs.NEW_GEN_SCALE;
				if (dx * dx + dy * dy < r) {
					game.getBallon(b);
				}
				i++;
			}
		}
	}
}
