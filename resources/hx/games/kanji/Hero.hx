package kanji;

import common_haxe_avm1.KeyboardManager;
import mt.Timer;

class Hero {
	static inline var S_WAIT = 0;
	static inline var S_MOVE = 1;
	static inline var S_JUMP = 2;

	var game:Game;
	var arrow:ASprite;

	public var mc:ASprite;
	public var x:Float;
	public var y:Float;
	public var frame:Float;
	public var way:Int;
	public var colOffX:Float;
	public var colOffY:Float;
	public var colHalfW:Float;
	public var colHalfH:Float;

	var state:Int;

	public var jump_pow:Float;
	public var jump_time:Bool;
	public var jump_dx:Float;

	public function new(g:Game) {
		game = g;
		x = 150 * Cs.NEW_GEN_SCALE;
		state = S_WAIT;
		y = Cs.MAXY;
		way = 1;
		jump_dx = 0;
		jump_pow = 0;
		frame = 0;
		colOffX = 0;
		colOffY = -20 * Cs.NEW_GEN_SCALE;
		colHalfW = 10 * Cs.NEW_GEN_SCALE;
		colHalfH = 10 * Cs.NEW_GEN_SCALE;
		arrow = game.dmanager.attach("arrow", 5);
		arrow.loop = true;
		arrow.play();
		mc = game.dmanager.attach("hero", Cs.PLAN_HERO);
		mc.stop();
	}

	public function update():Void {
		var speed = 5 * Cs.NEW_GEN_SCALE;
		var jspeed = 0.7 * Cs.NEW_GEN_SCALE;
		var maxpow = 25;

		jump_dx *= Math.pow(0.9, Timer.tmod);

		switch (state) {
			case S_WAIT | S_MOVE:
				if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
					if (state == S_WAIT) {
						frame = 29;
					}
					state = S_MOVE;
					way = -1;
					x -= Timer.tmod * speed;
				} else if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
					if (state == S_WAIT) {
						frame = 29;
					}
					state = S_MOVE;
					way = 1;
					x += Timer.tmod * speed;
				} else {
					if (state == S_MOVE) {
						frame = 40;
					}
					state = S_WAIT;
				}

				if (KeyboardManager.isDown(KeyboardManager.UP) || KeyboardManager.isDown(KeyboardManager.SPACE)) {
					jump_time = true;
					jump_pow = 4;
					jump_dx = (state == S_MOVE) ? (way * speed) : 0;
					state = S_JUMP;
					frame = 58;

					var p = game.dmanager.attach("smoke", Cs.PLAN_HERO);
					p.play();
					p.removeOnFrame = 9;
					p._x = x;
					p._y = y;
				}
			case S_JUMP:
				if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
					way = -1;
					jump_dx -= Timer.tmod * Cs.NEW_GEN_SCALE;
				} else if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
					way = 1;
					jump_dx += Timer.tmod * Cs.NEW_GEN_SCALE;
				}

				if (KeyboardManager.isDown(KeyboardManager.UP) || KeyboardManager.isDown(KeyboardManager.SPACE)) {
					if (jump_time && jump_pow < maxpow) {
						jump_pow *= Math.pow(1.4, Timer.tmod);
						if (jump_pow >= maxpow) {
							jump_pow = maxpow;
							jump_time = false;
						}
					}
				} else {
					jump_time = false;
				}

				x += jump_dx * Timer.tmod / 1.5;
				if (!jump_time) {
					jump_pow -= 1.2 * Timer.tmod;
				}
		}

		y -= Timer.tmod * jspeed * jump_pow;

		if (y > Cs.MAXY) {
			jump_pow = 0;
			state = S_WAIT;
			frame = 94;
			y = Cs.MAXY;
		}

		if (x < Cs.MINX) {
			x = Cs.MINX;
			jump_dx *= -2;
		}

		if (x > Cs.MAXX) {
			x = Cs.MAXX;
			jump_dx *= -2;
		}

		mc._x = x;
		mc._y = y;
		mc._xscale = 100;

		switch (state) {
			case S_WAIT:
				frame += Timer.tmod;
				if (frame >= 94) {
					if (frame >= 106) {
						frame = 1;
					}
				} else if (frame >= 40) {
					if (frame >= 46) {
						frame = KeyboardManager.isDown(KeyboardManager.DOWN) ? 59 : 1;
					}
				} else if (KeyboardManager.isDown(KeyboardManager.DOWN)) {
					frame = 59;
				} else if (frame >= 25) {
					frame -= 24;
				}
			case S_MOVE:
				frame += Timer.tmod;
				while (frame >= 36) {
					frame -= 3;
				}
			case S_JUMP:
				frame += Timer.tmod;
				if (frame >= 73 && jump_pow > 0) {
					frame = 70;
				}
				if (frame >= 93) {
					frame = 80;
				}
		}

		mc.gotoAndStop(Std.int(frame));
		arrow._visible = (y < 0);
		arrow._x = x;

		if (Cs.DEBUG) {
			game.drawBox({
				xMin: -10 * Cs.NEW_GEN_SCALE,
				yMin: -10 * Cs.NEW_GEN_SCALE,
				xMax: 10 * Cs.NEW_GEN_SCALE,
				yMax: 10 * Cs.NEW_GEN_SCALE
			}, x, y - 20 * Cs.NEW_GEN_SCALE);
		}
	}
}
