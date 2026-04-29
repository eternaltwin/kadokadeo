package pioupiou;

import kado.KadoKadeoManager;
import common_haxe_avm1.KeyboardManager;
import mt.Timer;

class FeatherMain extends ASprite {
	public var timer:Int;

	public var fList:Array<FeatherSprite> = [];
}

class FeatherSprite extends ASprite {
	public var t:Int;
}

class Hero {
	static inline var FALLING:Int = 0;
	static inline var NORMAL:Int = 1;
	static inline var CLIMB_LEFT:Int = 2;
	static inline var CLIMB_RIGHT:Int = 3;
	static inline var END_CLIMB_LEFT:Int = 4;
	static inline var END_CLIMB_RIGHT:Int = 5;
	public static inline var DEATH:Int = 6;

	var game:Game;

	public var mc:ASprite;

	var frameCount = 0;

	var death_mc:FeatherMain;
	var flRun:Bool;
	var x:Float;

	public var y:Float;

	var r:Float;

	public var state:Int;

	var sens:Int;
	var frame:Float;
	var death_time:Float;
	var isEnd:Bool = false;

	public function new(g:Game) {
		game = g;
		state = NORMAL;
		x = 150 * Cs.NEW_GEN_SCALE;
		y = 200 * Cs.NEW_GEN_SCALE;
		r = 0;
		sens = 1;
		frame = 0;
		flRun = false;
		mc = game.dmanager.attach("hero", Cs.PLAN_HERO);
		mc.stop();
	}

	public function scrollUp():Void {
		y += Cs.BLK_HEIGHT;
	}

	function getPos():{x:Int, y:Int} {
		return game.level.getPos(x, y + Cs.BLK_HEIGHT - Cs.NEW_GEN_SCALE);
	}

	function recal(x:Null<Int>, y:Null<Int>):Void {
		if (x != null) {
			this.x = x * Cs.BLK_WIDTH + Cs.DELTA_X;
		}
		if (y != null) {
			this.y = (game.level.base_y - y) * Cs.BLK_HEIGHT + Cs.DELTA_Y;
		}
	}

	function tbl(x:Int, y:Int):Kind {
		return game.level.tbl[x][y];
	}

	inline function isLeftPressed():Bool {
		return KeyboardManager.isDown(KeyboardManager.LEFT)
			|| KeyboardManager.isDown(KeyboardManager.A)
			|| KeyboardManager.isDown(KeyboardManager.Q);
	}

	inline function isRightPressed():Bool {
		return KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D);
	}

	function climbFalling(p:{x:Int, y:Int}):Void {
		if (tbl(p.x, p.y) == null) {
			return;
		}
		var b = game.level.getFalling(p.x, p.y + 1);
		if (b == null) {
			b = game.level.getFalling(p.x, p.y);
		}
		if (b != null && !b.mc.hitTest(mc._x, mc._y, false)) {
			return;
		}
		r = 0;
		state = FALLING;
	}

	function death():Void {
		if (state == DEATH) {
			return;
		}
		mc._yscale = 100;
		mc._visible = false;
		state = DEATH;
		death_time = 1;
		death_mc = cast game.dmanager.empty(Cs.PLAN_FX);
		death_mc._x = mc._x;
		death_mc._y = mc._y;
		death_mc.timer = 30;
		death_mc.fList = [];
		var i = 0;
		while (i < 10) {
			var d:FeatherSprite = cast death_mc.attachMovie("FXFeather");
			d.loop = true;
			d.gotoAndPlay(1 + Seed.randomVfx(d._totalframes));
			d._xscale = d._yscale = 50 + Seed.randomVfx(100);
			d._x = 0;
			d._y = -Cs.BLK_HEIGHT;
			d.t = 10 + Seed.randomVfx(20);
			i++;
			death_mc.fList.push(d);
		}
	}

	public function updateFeathers() {
		var f = death_mc;
		if (f == null) {
			return;
		}
		frameCount++;
		if (frameCount % 2 == 0) {
			return;
		}
		f.update();

		var j = 0;
		while (j < f.fList.length) {
			var mc = f.fList[j];
			if (mc == null) {
				j++;
				continue;
			}
			mc.update();
			mc.t--;
			if (mc.t < 10) {
				mc._alpha = 10 * mc.t;
			}
			var c = (mc._currentframe * 2 - mc._totalframes) / mc._totalframes;
			mc._y += (0.5 + Math.abs(c) * 1) * Cs.NEW_GEN_SCALE;
			if (mc.t == 0) {
				mc.removeMovieClip();
				f.fList.splice(j--, 1);
			}
			j++;
		}

		if (f.timer-- < 0) {
			f.removeMovieClip();
			f = null;
		}
	}

	public function update():Void {
		if (isEnd) {
			return;
		}
		var climb_speed = 8 * Cs.NEW_GEN_SCALE;
		var fall_speed = 20 * Cs.NEW_GEN_SCALE;

		var p = getPos();

		var minX = p.x * Cs.BLK_WIDTH + Cs.DELTA_X + 10 * Cs.NEW_GEN_SCALE;
		var maxX = (p.x + 1) * Cs.BLK_WIDTH + Cs.DELTA_X - 10 * Cs.NEW_GEN_SCALE;

		if (p.x == 0) {
			minX += 9 * Cs.NEW_GEN_SCALE;
		} else if (p.x == Cs.LVL_WIDTH - 1) {
			maxX -= 9 * Cs.NEW_GEN_SCALE;
		}

		if (p.x > 0 && tbl(p.x - 1, p.y) == null) {
			minX -= Cs.BLK_WIDTH;
		}
		if (p.x < Cs.LVL_WIDTH - 1 && tbl(p.x + 1, p.y) == null) {
			maxX += Cs.BLK_WIDTH;
		}

		if (state == CLIMB_LEFT || state == CLIMB_RIGHT || state == END_CLIMB_LEFT || state == END_CLIMB_RIGHT) {
			climbFalling(p);
		}

		flRun = false;
		switch (state) {
			case NORMAL:
				if (tbl(p.x, p.y - 1) == null) {
					if (isLeftPressed()) {
						x -= 5 * Cs.NEW_GEN_SCALE * Timer.tmod;
					} else if (isRightPressed()) {
						x += 5 * Cs.NEW_GEN_SCALE * Timer.tmod;
					}
					state = FALLING;
				} else if (isLeftPressed()) {
					sens = -1;
					flRun = true;
					r = Math.max(-5, r - Timer.tmod);
					if (x > minX) {
						x -= 5 * Cs.NEW_GEN_SCALE * Timer.tmod;
						if (x <= minX) {
							x = minX;
						}
					} else if (p.x > 0 && mc._yscale >= 100) {
						r += 20 * Timer.tmod;
						if (r >= 20) {
							state = CLIMB_LEFT;
						}
					}
				} else if (isRightPressed()) {
					sens = 1;
					flRun = true;
					r = Math.min(r + Timer.tmod, 5);
					if (x < maxX) {
						x += 5 * Cs.NEW_GEN_SCALE * Timer.tmod;
						if (x >= maxX) {
							x = maxX;
						}
					} else if (p.x < Cs.LVL_WIDTH - 1 && mc._yscale >= 100) {
						r -= 20 * Timer.tmod;
						if (r <= -20) {
							state = CLIMB_RIGHT;
						}
					}
				} else {
					r = 0;
				}
			case FALLING:
				for (i in 0...10) {
					y += fall_speed / 10 * Timer.tmod;
					p = getPos();
					if (tbl(p.x, p.y) != null) {
						recal(null, p.y + 1);
						state = NORMAL;
						break;
					}
				}
			case CLIMB_LEFT:
				sens = -1;
				if (tbl(p.x, p.y) == null && tbl(p.x, p.y + 1) == null && isLeftPressed()) {
					flRun = true;
					r += 5 * Timer.tmod;
					if (r >= 80) {
						r = 80;
					}
					y -= climb_speed * Timer.tmod;
				} else {
					r = 0;
					state = FALLING;
				}
				p = getPos();
				if (tbl(p.x - 1, p.y) == null) {
					recal(null, p.y);
					state = END_CLIMB_LEFT;
				}
			case END_CLIMB_LEFT:
				r -= 10 * Timer.tmod;
				if (r <= 0) {
					r = 0;
					x -= 11 * Cs.NEW_GEN_SCALE;
					state = NORMAL;
				}
			case CLIMB_RIGHT:
				sens = 1;
				if (tbl(p.x, p.y) == null && tbl(p.x, p.y + 1) == null && isRightPressed()) {
					flRun = true;
					r -= 5 * Timer.tmod;
					if (r <= -80) {
						r = -80;
					}
					y -= climb_speed * Timer.tmod;
				} else {
					r = 0;
					state = FALLING;
				}
				if (tbl(p.x + 1, p.y) == null) {
					recal(null, p.y);
					state = END_CLIMB_RIGHT;
				}
			case END_CLIMB_RIGHT:
				r += 10 * Timer.tmod;
				if (r >= 0) {
					r = 0;
					x += 11 * Cs.NEW_GEN_SCALE;
					state = NORMAL;
				}
			case DEATH:
				death_time -= Timer.deltaT;
				updateFeathers();
				if (death_time < 0) {
					KadoKadeoManager.kkm.gameOver(game.data);
					isEnd = true;
				}
		}

		mc._xscale = sens * 100;
		mc._prevState.xscale = mc._curState.xscale;
		if (flRun) {
			frame = (frame + Timer.tmod * 2) % 16;
		} else {
			frame = 0;
		}
		mc.gotoAndStop(Math.round(frame + 1));

		p = getPos();
		var k = tbl(p.x, p.y);
		if (k != null) {
			var b = game.level.getFalling(p.x, p.y + 1);
			if (b == null) {
				death();
			} else {
				mc._yscale = 100 - b.dy * 100 / Cs.BLK_HEIGHT;
			}
		} else {
			mc._yscale += 10 * Timer.tmod;
			if (mc._yscale >= 100) {
				mc._yscale = 100;
			}
		}

		switch (state) {
			case CLIMB_LEFT | END_CLIMB_LEFT:
				mc._x = x - 8 * Cs.NEW_GEN_SCALE;
			case CLIMB_RIGHT | END_CLIMB_RIGHT:
				mc._x = x + 8 * Cs.NEW_GEN_SCALE;
			case _:
				mc._x = x;
		}

		mc._y = y + Cs.BLK_HEIGHT;
		mc._rotation = r;
	}
}
