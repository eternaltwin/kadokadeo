package kavern;

import common_haxe_avm1.KeyboardManager;
import kado.KadoKadeoManager;
import mt.Timer;

class Hero {
	public static inline var NORMAL = 0;
	public static inline var FALLING = 1;
	public static inline var JUMPING = 2;
	public static inline var DEATH = 3;

	public static var A_WALK = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
	public static var A_BEC = [58, 59, 60, 61, 62, 63, 64];
	public static var A_FACE = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];
	public static var A_CREUSE = [58, 59, 60, 61, 62, 63, 64];
	public static var A_DEATH = [
		78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103
	];

	var game:Game;
	var mc:ASprite;

	public var anim:Array<Int>;
	public var frame:Float;

	var sx:Null<Float>;

	public var x:Float;
	public var y:Float;
	public var state:Int;
	public var moving:Bool;

	var key_time:Float;
	var death:ASprite;

	public function new(g:Game, px:Int, py:Int) {
		game = g;
		key_time = 0;
		mc = game.dmanager.attach("hero", Cs.PLAN_HERO);
		state = NORMAL;
		anim = A_WALK;
		frame = 0;
		x = (px + 0.5) * Cs.BLOCK_SIZE;
		y = py * Cs.BLOCK_SIZE;
	}

	public function kill(bx:Int, by:Int):Void {
		if (state == DEATH)
			return;
		var px = Std.int(x / Cs.BLOCK_SIZE);
		var py = Std.int(y / Cs.BLOCK_SIZE);
		if (bx == px && by == py) {
			state = DEATH;
			death = game.dmanager.attach("FXFeather", Cs.PLAN_PART);
			death.loop = true;
			death.play();
			death._x = mc._x;
			death._y = mc._y;
			mc.removeMovieClip();
		}
	}

	function animDone():Void {
		if (anim == A_BEC) {
			frame += 3;
		}
		if (anim == A_CREUSE && state == JUMPING) {
			var px = Std.int(x / Cs.BLOCK_SIZE);
			var py = Std.int(y / Cs.BLOCK_SIZE);
			game.genParts(px, py + 1, 0, -1);
			game.getBonus(px, py + 1);
			game.level.tbl[px][py + 1] = Level.EMPTY;
			game.needsUpdate = true;
			game.stats.c++;
			moving = true;
			anim = A_FACE;
			frame = 0;
			state = NORMAL;
		}
		if (anim == A_DEATH) {
			anim = A_WALK;
			mc.removeMovieClip();
			KadoKadeoManager.kkm.gameOver(game.stats);
		}
	}

	public function update():Void {
		if (death != null) {
			KadoKadeoManager.kkm.gameOver(game.stats);
			return;
		}

		var dx = 0;
		var s = Cs.BLOCK_SIZE;
		var speed = KadoKadeoManager.I(5);

		if (state == NORMAL) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT)
				|| KeyboardManager.isDown(KeyboardManager.A)
				|| KeyboardManager.isDown(KeyboardManager.Q)) {
				anim = A_WALK;
				moving = true;
				mc._xscale = -100;
				dx = -1;
			} else if (KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D)) {
				anim = A_WALK;
				moving = true;
				mc._xscale = 100;
				dx = 1;
			} else if ((KeyboardManager.isDown(KeyboardManager.DOWN) || KeyboardManager.isDown(KeyboardManager.S)) && key_time <= 0) {
				var py = Std.int(y / s);
				var px = Std.int(x / s);
				var l = game.level.tbl[px][py + 1];
				if (l == Level.EARTH) {
					anim = A_CREUSE;
					frame = 0;
					state = JUMPING;
					animDone();
				} else if (l == Level.BLOCK) {
					if (anim != A_BEC) {
						anim = A_BEC;
						frame = 0;
					}
					game.doCasse(px, py + 1);
				} else if (l == Level.BLOCKSPE) {
					if (anim != A_BEC) {
						anim = A_BEC;
						frame = 0;
					}
					if (game.diff > 0)
						game.deltaLife(-Timer.tmod);
				}
				moving = true;
			} else
				key_time -= Timer.deltaT;
		}

		frame += Timer.tmod;
		if (frame >= anim.length) {
			frame %= anim.length;
			animDone();
		}

		switch (state) {
			case NORMAL:
				if (!moving) {
					anim = A_WALK;
					frame = 0;
				} else {
					var x2 = x + dx * speed * Timer.tmod;
					var px = Std.int(x / s);
					var px1 = Std.int(x2 / s - 0.3);
					var px2 = Std.int(x2 / s + 0.3);
					var py = Std.int(y / s);
					var ok = true;

					if (px1 < px)
						px1 = px - 1;
					if (px2 > px)
						px2 = px + 1;

					if (dx <= 0) {
						switch (game.level.tbl[px1][py]) {
							case Level.EARTH:
								game.genParts(px1, py, 1, 0);
								game.getBonus(px1, py);
								game.level.tbl[px1][py] = Level.EMPTY;
								game.needsUpdate = true;
							case Level.BLOCKSPE | Level.BLOCK:
								ok = false;
							case _:
						}
					}

					if (dx >= 0 && game.level.tbl[px2] != null) {
						switch (game.level.tbl[px2][py]) {
							case Level.EARTH:
								game.genParts(px2, py, -1, 0);
								game.getBonus(px2, py);
								game.level.tbl[px2][py] = Level.EMPTY;
								game.needsUpdate = true;
							case Level.BLOCKSPE | Level.BLOCK:
								ok = false;
							case _:
						}
					}

					if (ok)
						x = x2;
					else {
						var nx = ((dx < 0) ? (px1 + 1.5) : (px2 - 0.5)) * s;
						if (dx < 0)
							x = Math.min(x, nx);
						else
							x = Math.max(x, nx);
					}

					px = Std.int(x / s - 0.3 * dx);
					if (game.level.tbl[px][py + 1] == Level.EMPTY) {
						sx = x;
						x = (px + 0.5) * s;
						state = FALLING;
					}
				}

			case FALLING:
				if (sx != null) {
					var p = Math.pow(0.5, Timer.tmod);
					sx = sx * p + x * (1 - p);
					if (Math.abs(sx - x) < KadoKadeoManager.I(1))
						sx = null;
				} else
					y += KadoKadeoManager.I(8) * Timer.tmod;
				var px = Std.int(x / s);
				var py = Std.int(y / s);
				if (game.level.tbl[px][py + 1] != Level.EMPTY) {
					y = py * s;
					state = NORMAL;
				}
			case _:
		}

		var changedLevel = false;
		if (x < 0) {
			game.changeLevel(-1, 0);
			changedLevel = true;
		} else if (x >= KadoKadeoManager.I(300)) {
			game.changeLevel(1, 0);
			changedLevel = true;
		} else if (y >= KadoKadeoManager.I(290)) {
			y = KadoKadeoManager.I(290);
			game.changeLevel(0, 1);
			changedLevel = true;
		}

		var px = Std.int(x / s);
		var py = Std.int(y / s);

		mc._yscale = 100;
		if (state == NORMAL)
			for (f in game.falls) {
				if (f.gridX == px && f.gridY + 1 == py) {
					mc._yscale = 100 * (y - f._y) / Cs.BLOCK_SIZE;
				}
			}

		mc._x = (sx != null) ? sx : x;
		mc._y = y + s;
		if (changedLevel)
			mc.updateState();
		mc.gotoAndStop(anim[Std.int(frame)]);
		moving = false;
	}
}
