package ktrain;

import ktrain.MC.FilterSpec;

// Loco.hx of the original: the locomotive (it goes up the screen while the driver is out, back down when he is in),
// its smoke and the sparks of the brake, and the crash when the train behind catches up
class Loco {
	static var up = false;
	static var smoke = true;
	static var game:Game = null;
	static var SMOKE_CYCLE = 20.0;
	static var smokeCycle = SMOKE_CYCLE;
	static var shadow:MC;
	static var crash = false;
	static var initCrash = false;
	static var fBad:Array<Float>;

	public static var lockSpeed = false;
	public static var move = false;
	public static var mc:MC;
	public static var mcBad:MC;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		up = false;
		smoke = true;
		game = null;
		smokeCycle = SMOKE_CYCLE;
		shadow = null;
		crash = false;
		initCrash = false;
		fBad = null;
		lockSpeed = false;
		move = false;
		mc = null;
		mcBad = null;
	}

	public static function init(g:Game) {
		game = g;
		shadow = game.dm.attach("mc_ombre_train", Const.DP_LOCO);
		shadow._x = Const.CENTER_X;
		shadow._y = Const.LOCO_STARTPOS;
		shadow.setBlend("multiply");

		mc = game.dm.attach("mcLoco", Const.DP_LOCO);
		mc._x = Const.CENTER_X;
		mc._y = Const.LOCO_STARTPOS;
	}

	public static function update(scroll:Float) {
		if (crash) {
			doCrash();
		} else {
			if (move)
				moveUp()
			else
				moveDown(scroll);
		}

		if (KeyboardManager.isDown(KeyboardManager.SPACE) && !lockSpeed) {
			fxSpark();
			#if debug
			game.stats.brakes++;
			#end
			Const.SPEED *= 0.98;
			Const.STEP_SPEED = 0;
			Const.NEXT_SPEED = 0;
			game.updateSpeedoMeter();
		}

		Scroller.hitPiouz(mc);

		smokeCycle -= scroll;
		while (smokeCycle <= 0) {
			makeSmoke();
			smokeCycle += 15;
		}
	}

	static function moveUp() {
		lockSpeed = true;
		doMove(-Const.SPEED);
		if (mc._y < 0) {
			game.gameOver = true;
			return;
		}
	}

	public static function doCrash() {
		if (!initCrash) {
			game.unlockScroll();
			mcBad = game.dm.attach("mcLoco", Const.DP_LOCO);
			mcBad._x = Const.CENTER_X;
			mcBad._y = Const.LOCO_STARTPOS + Const.LOCO_H;
			// (blendMode = "substract": not a blend mode name, Flash ignores it)
			mcBad.setBlend("substract");
			fBad = [1.56, 0, 0, 0, 90.16, 0, 1.56, 0, 0, -90.16, 0, 0, 1.56, 0, -90.16, 0, 0, 0, 1, 0];
			initCrash = true;
			#if debug
			game.stats.crash++;
			#end
		}

		game.scroll += 1;
		Man.fly();

		mcBad.setFilters([ColorMatrix(fBad)]);
		crash = true;
		if (mcBad._y > mc._y && !up) {
			if (mcBad._y - Const.LOCO_H <= mc._y) {
				mc._y -= 5;
				Game.startBoom = 40;
			}
			mcBad._y -= 5;
		}

		if (mcBad._y < Const.HEIGHT - 10) {
			game.gameOver = true;
		}

		if (mcBad._y < Const.HEIGHT - 70) {
			smoke = false;
		}

		if (mcBad._y < Const.HEIGHT - Const.LOCO_H) {
			Game.startBoom = 0;
		}
	}

	static function moveDown(scroll:Float) {
		if (mc._y == Const.LOCO_STARTPOS) {
			lockSpeed = false;
			return;
		}

		if (scroll > 0) {
			// (compiled form: STEP_SPEED > 0 ? STEP_SPEED : 1)
			var s = Const.STEP_SPEED > 0 ? Const.STEP_SPEED : 1;
			doMove(scroll / (s * 2));
		}

		if (mc._y > Const.LOCO_STARTPOS) {
			mc._y = Const.LOCO_STARTPOS;
			game.unlockScroll();
			lockSpeed = false;
		}
	}

	static function doMove(v:Float) {
		if (mc._y < 0) {
			mc._y = 0;
		}
		var y = mc._y + v;
		mc._y = y;
		shadow._y = y;
	}

	// the smoke: only pictures (its random is visual)
	public static function makeSmoke() {
		if (!smoke)
			return;

		for (i in 0...2) {
			// mcSmoke and s.smc.smc.gotoAndStop(random(6) + 1): the clip of that puff
			var s = game.dm.attach("mcSmoke" + (Const.randomVfx(6) + 1), Const.DP_SMOKE);
			var p = new Phys(s);

			p.x = mc._x;
			p.y = mc._y - 136;

			if (i == 0) {
				p.vy = Const.SPEED * 0.25;
				p.y -= Const.SPEED * 0.35;
				p.timer = 10;
				p.setScale(75);
			} else {
				p.timer = 35;
				p.fadeLimit = 20;
				p.vy = Const.SPEED;
				p.y -= 10;
				p.root._yscale = 100 + Const.SPEED * 10;
				p.y += Const.SPEED * 2;

				p.x += Const.randomVfx(7) - 3;
				p.y += Const.randomVfx(9) - 4;

				#if debug
				if (untyped js.Browser.window.__noSmokeBlur != true)
				#end
				p.root.setFilters([Blur(0, Const.SPEED)]);
			}
			p.updatePos();
		}
	}

	static function fxSpark() {
		var ammount = Std.int(Const.SPEED * 0.3);

		for (n in 0...ammount) {
			for (i in 0...2) {
				var sens = i * 2 - 1;
				var p = new Spark(game.dm.attach("fxSpark", Const.DP_SPARK));
				p.x = mc._x + sens * 16;
				p.y = mc._y + Seed.randVfx() * 10 - 126;
				p.vx = sens * Seed.randVfx() * 3;
				p.vy = Const.SPEED + Seed.randVfx() * 3 - 1;
				p.timer = 10;
			}
		}
	}
}
