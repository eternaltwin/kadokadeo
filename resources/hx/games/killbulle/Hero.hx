package killbulle;

import common_haxe_avm1.KeyboardManager;
import kado.KadoKadeoManager;
import mt.Timer;
import mt.bumdum.Lib;

class McSprite extends ASprite {
	public var sub:ASprite;
}

class Hero {
	public var game:Game;
	public var mc:McSprite;
	public var grapin:Null<Grapin>;
	public var died:Bool;
	public var x:Float;
	public var y:Float;
	public var dx:Float;
	public var dy:Float;
	public var frame:Float;
	public var moving:Bool;
	public var acc:Float;
	public var dir:Int;
	public var lock:Bool;
	public var super_grapin_time:Float;
	public var death_timer:Float;

	public function new(g:Game) {
		frame = 0;
		acc = 0;
		dir = 1;
		super_grapin_time = 0;
		lock = false;
		died = false;
		game = g;
		var heroAnims = [
			new ASprite("heroAnim1"),
			new ASprite("heroAnim2"),
			new ASprite("heroAnim3"),
			new ASprite("heroAnim4"),
			new ASprite("heroAnim5"),
			new ASprite("heroAnim6"),
			new ASprite("heroAnim7")
		];
		mc = cast game.dmanager.empty(Cs.PLAN_HERO);
		mc.sub = heroAnims[0];
		mc.addChild(mc.sub);
		mc._totalframes = 7;
		for (i in 1...8) {
			mc.onFrame.set(i, function() {
				mc.removeChild(mc.sub);
				mc.sub = heroAnims[i - 1];
				mc.sub.play();
				mc.sub.loop = true;
				mc.addChild(mc.sub);
			});
		}
		mc._yscale = 100;
		mc.stop();
		x = Cs.WIDTH / 2;
		y = Cs.MINY;
	}

	function kill():Void {
		dy = -10 * Cs.NEW_GEN_SCALE;
		dx = (x < Cs.WIDTH / 2) ? 2 * Cs.NEW_GEN_SCALE : -2 * Cs.NEW_GEN_SCALE;
		died = true;
		death_timer = 1.5;
		frame = 0;
		mc.gotoAndStop(7);
	}

	function hit():Void {
		var hx = Num.q(x);
		var hy = Num.q(y - 20 * Cs.NEW_GEN_SCALE);
		var r = 8 * Cs.NEW_GEN_SCALE;
		var found = false;
		for (b in game.blobs) {
			var dx = Num.q(b.x - hx);
			var dy = Num.q(b.y - hy);
			var ray = Num.q(b.size * Cs.NEW_GEN_SCALE / 2.4 + r);
			if (!found && dx * dx + dy * dy < ray * ray) {
				x = b.x;
				y = b.y;
				kill();
				b.mc._xscale = 50;
				b.mc._yscale = 50;
				b.size = 50 * Cs.NEW_GEN_SCALE;

				var e = game.dmanager.attach("animExplose", Cs.PLAN_BLOB);
				e.play();
				e.removeOnFrame = 13;
				e._x = b.x;
				e._y = b.y;
				e._xscale = 50;
				e._yscale = 50;
				b.setColor(e);

				if (b.bonus != null) {
					b.bonus.mc.removeMovieClip();
				}
				b.bonus = cast this;
				found = true;
			}
		}
	}

	public function special():Void {
		frame = 0;
		mc.gotoAndStop(6);
		moving = false;
		lock = true;
	}

	public function update():Void {
		if (super_grapin_time > 0)
			super_grapin_time -= Timer.deltaT;

		frame += Timer.tmod;
		switch (mc._currentframe) {
			case 2:
				if (frame >= mc.sub._totalframes)
					frame -= (mc.sub._totalframes - 4);
			case _:
		}

		if (grapin != null) {
			if (!grapin.update())
				grapin = null;
		} else if (KeyboardManager.isDown(KeyboardManager.SPACE) && !died && !lock) {
			grapin = new Grapin(game);
			if (!grapin.update())
				grapin = null;
			frame = 0;
			moving = false;
			mc.gotoAndStop(4);
		}

		if (died) {
			if (death_timer > 0) {
				death_timer -= Timer.deltaT;
				if (death_timer <= 0)
					KadoKadeoManager.kkm.gameOver(game.stats);
			}
			mc.sub.gotoAndStop(1 + (Std.int(frame) % mc.sub._totalframes));
			return;
		}

		if (!lock) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT) || KeyboardManager.isDown(KeyboardManager.Q) || KeyboardManager.isDown(KeyboardManager.A)) {
				if (!moving) {
					moving = true;
					frame = 0;
					mc.gotoAndStop(2);
				}
				dir = -1;
				if (acc > 0)
					acc = 0;
				acc = Num.q(acc - 1 * Cs.NEW_GEN_SCALE * Timer.tmod);
				if (acc < -5 * Cs.NEW_GEN_SCALE)
					acc = -5 * Cs.NEW_GEN_SCALE;
			} else if (KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D)) {
				if (!moving) {
					moving = true;
					frame = 0;
					mc.gotoAndStop(2);
				}
				dir = 1;
				if (acc < 0)
					acc = 0;
				acc = Num.q(acc + 1 * Cs.NEW_GEN_SCALE * Timer.tmod);
				if (acc > 5 * Cs.NEW_GEN_SCALE)
					acc = 5 * Cs.NEW_GEN_SCALE;
			} else {
				acc = Num.q(acc * Math.pow(0.8, Timer.tmod));
				if (moving) {
					moving = false;
					frame = 0;
					mc.gotoAndStop(3);
				}
			}
			x = Num.q(x + acc * Timer.tmod);
		}

		if (!moving && mc._currentframe == 2)
			mc.gotoAndStop(1);
		else if (!moving && mc._currentframe >= 3 && frame >= mc.sub._totalframes) {
			lock = false;
			acc = 0;
			mc.gotoAndStop(1);
		}

		mc._xscale = dir * 100;

		mc.sub.gotoAndStop(1 + (Std.int(frame) % mc.sub._totalframes));

		if (x <= 30 * Cs.NEW_GEN_SCALE)
			x = 30 * Cs.NEW_GEN_SCALE;
		else if (x >= Cs.WIDTH - 20 * Cs.NEW_GEN_SCALE)
			x = Cs.WIDTH - 20 * Cs.NEW_GEN_SCALE;

		if (game.blob_timer <= 0)
			hit();

		var dy = Math.max(0, Math.sin(x * Math.PI / (17 * Cs.NEW_GEN_SCALE))) * 3 * Cs.NEW_GEN_SCALE;

		mc._x = x;
		mc._y = y - dy;
	}
}
