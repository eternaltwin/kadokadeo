package kanji;

import kanji.Game.FeatherSprite;
import kanji.Game.FeatherMain;
import pixi.core.math.shapes.Rectangle;
import mt.Timer;

class McSprite extends ASprite {
	public var col:ASprite;
}

class Jama {
	var game:Game;
	var col:ASprite;
	var tmp:ASprite;
	var mc:McSprite;
	var x:Float;
	var y:Float;
	var t:Int;
	var way:Bool;
	var speed:Float;
	var time:Float;
	var sx:Float;
	var sy:Float;
	var hitFromAbove:Bool;

	static inline var CIGOGNE = 0;
	static inline var BEE = 1;
	static inline var SANGLIER = 2;
	static inline var CIGOGNE_COL_ANCHOR_X = 92;
	static inline var CIGOGNE_COL_TOP = -16;
	static inline var CIGOGNE_COL_BOTTOM = 21;
	static inline var CIGOGNE_COL_W = 235;
	static inline var BEE_LEFT = -44;
	static inline var BEE_RIGHT = 41;
	static inline var BEE_TOP = -65;
	static inline var BEE_BOTTOM = 35;
	static inline var SANGLIER_LEFT = -91;
	static inline var SANGLIER_RIGHT = 84;
	static inline var SANGLIER_TOP = -88;
	static inline var SANGLIER_BOTTOM = 14;

	public function new(g:Game, p, t:Int) {
		game = g;
		this.t = t;
		mc = cast game.dmanager.attach("jama" + (t + 1), Cs.PLAN_JAMA);
		mc.loop = true;
		mc.play();
		if (t == CIGOGNE) {
			mc.col = mc.attachMovie("jama1col");
			mc.col._visible = false;
		}
		x = p.x;
		y = p.y;
		time = 0;
		sx = x;
		sy = y;
		way = (x > 0);
		init();
		mc._x = x;
		mc._y = y;
		game.entities.push(cast mc);
	}

	function init():Void {
		switch (t) {
			case CIGOGNE:
				col = mc.col;
				if (way) {
					mc._xscale = -100;
					x += 20 * Cs.NEW_GEN_SCALE;
				} else {
					x -= 20 * Cs.NEW_GEN_SCALE;
				}
				speed = (1 + 0.3 * game.level) * Cs.NEW_GEN_SCALE;
			case BEE:
				sx = (50 + Math.min(game.level, 5) * 10) * Cs.NEW_GEN_SCALE;
				if (sy + sx > Cs.MAXX) {
					sy = Cs.MAXX - sx;
				}
				if (sy - sx < 0) {
					sy = sx;
				}
				speed = (0.4 + 0.2 * game.level) * Cs.NEW_GEN_SCALE;
				if (way) {
					mc._xscale = -100;
				}
			case SANGLIER:
				y = Cs.MAXY;
				sx = 0;
				speed = 8 * Cs.NEW_GEN_SCALE;
				mc.stop();
				time = -2.7 + game.level * 0.15;

				tmp = game.dmanager.attach("prev", 6);
				tmp.play();
				tmp.removeOnFrame = 45;
				tmp._x = x + (way ? -20 : 20) * Cs.NEW_GEN_SCALE;
				tmp._y = y - 10 * Cs.NEW_GEN_SCALE;

				if (way) {
					mc._xscale = -100;
				} else {
					tmp._xscale = -100;
				}
		}
	}

	function localBox():{
		left:Float,
		right:Float,
		top:Float,
		bottom:Float
	} {
		if (t == CIGOGNE) {
			if (way) {
				return {
					left: -CIGOGNE_COL_W + CIGOGNE_COL_ANCHOR_X,
					right: CIGOGNE_COL_ANCHOR_X,
					top: CIGOGNE_COL_TOP,
					bottom: CIGOGNE_COL_BOTTOM
				};
			}
			return {
				left: -CIGOGNE_COL_ANCHOR_X,
				right: CIGOGNE_COL_W - CIGOGNE_COL_ANCHOR_X,
				top: CIGOGNE_COL_TOP,
				bottom: CIGOGNE_COL_BOTTOM
			};
		}
		if (t == BEE) {
			return {
				left: BEE_LEFT,
				right: BEE_RIGHT,
				top: BEE_TOP,
				bottom: BEE_BOTTOM
			};
		}
		if (t == SANGLIER) {
			if (way) {
				return {
					left: -SANGLIER_RIGHT,
					right: -SANGLIER_LEFT,
					top: SANGLIER_TOP,
					bottom: SANGLIER_BOTTOM
				};
			}
			return {
				left: SANGLIER_LEFT,
				right: SANGLIER_RIGHT,
				top: SANGLIER_TOP,
				bottom: SANGLIER_BOTTOM
			};
		}
		return {
			left: 0,
			right: 0,
			top: 0,
			bottom: 0
		};
	}

	function hit(hray:Float):Bool {
		if (game.hero.mc._name == null) {
			return false;
		}

		mc._x = x;
		mc._y = y;

		var box = localBox();
		var hcX = Cs.q(game.hero.x + game.hero.colOffX - game.hero.colHalfW);
		var hcY = Cs.q(game.hero.y + game.hero.colOffY - game.hero.colHalfH);

		var hLeft = hcX;
		var hRight = Cs.q(hcX + game.hero.colHalfW * 2);
		var hTop = hcY;
		var hBottom = Cs.q(hcY + game.hero.colHalfH * 2);

		var oLeft = Cs.q(x + box.left + hray);
		var oRight = Cs.q(x + box.right - hray);
		var oTop = Cs.q(y + box.top);
		var oBottom = Cs.q(y + box.bottom);

		if (Cs.DEBUG) {
			game.drawBox({
				xMin: oLeft,
				yMin: oTop,
				xMax: oRight,
				yMax: oBottom
			}, 0, 0);
		}

		if (oRight < hLeft || oLeft > hRight) {
			return false;
		}

		if (oBottom < hTop || oTop > hBottom) {
			return false;
		}

		var oCenterY = Cs.q((oTop + oBottom) * 0.5);
		hitFromAbove = hcY < oCenterY;
		if (!hitFromAbove && Cs.DEBUG) {
			trace("hit side/below - enemy center:", oCenterY, "hero center:", hcY);
		}
		return true;
	}

	function remove():Bool {
		game.entities.remove(cast mc);
		mc.removeMovieClip();
		return false;
	}

	public function update():Bool {
		var ret = true;
		time += Timer.deltaT;

		switch (t) {
			case CIGOGNE:
				x += speed * Timer.tmod * (way ? -1 : 1);
				if (hit(10 * Cs.NEW_GEN_SCALE)) {
					if (hitFromAbove) {
						var p = Math.abs(game.hero.jump_pow);
						p *= 0.7;
						p = Math.max(p, 5);
						game.hero.jump_pow = p;
						game.hero.jump_time = true;
						game.hero.frame = 59;

						var feather:FeatherMain = cast game.dmanager.empty(Cs.PLAN_JAMA + 1);
						feather._x = x;
						feather._y = y;
						feather.timer = 50;
						feather.fList = [];
						var i = 0;
						while (i < 10) {
							var d:FeatherSprite = cast game.dmanager.attach("FXFeather", Cs.PLAN_JAMA + 1);
							d.loop = true;
							d.gotoAndPlay(1 + Seed.randomVfx(d._totalframes));
							d._xscale = d._yscale = 50 + Seed.randomVfx(100);
							var b:Rectangle = d.getBounds();
							d._x = feather._x - b.width / 2;
							d._y = feather._y - b.y;
							d.t = 10 + Seed.randomVfx(40);
							i++;
							feather.fList.push(d);
						}
						game.feathers.push(feather);
						// f._visible = false;

						var smoke = game.dmanager.attach("smoke", Cs.PLAN_HERO);
						smoke.play();
						smoke.removeOnFrame = 9;
						smoke._x = x;
						smoke._y = y;

						ret = remove();
					} else {
						if (Cs.DEBUG) {
							remove();
							return false;
						}
						game.kill();
					}
				}
				if (x > 340 * Cs.NEW_GEN_SCALE || x < -40 * Cs.NEW_GEN_SCALE) {
					ret = remove();
				}
			case BEE:
				x += speed * Timer.tmod * (way ? -1 : 1);
				y = Math.sin(time) * sx + sy;
				if (hit(5 * Cs.NEW_GEN_SCALE)) {
					game.kill();
				}
				if (x > 320 * Cs.NEW_GEN_SCALE || x < -20 * Cs.NEW_GEN_SCALE) {
					ret = remove();
				}
			case SANGLIER:
				if (time >= 0) {
					tmp.removeMovieClip();
					sx += Timer.tmod;
					mc.gotoAndStop(Std.int(sx % mc._totalframes) + 1);
					x += speed * Timer.tmod * (way ? -1 : 1);
					if (hit(10 * Cs.NEW_GEN_SCALE)) {
						game.kill();
					}
					if (x > 340 * Cs.NEW_GEN_SCALE || x < -40 * Cs.NEW_GEN_SCALE) {
						ret = remove();
					}
				}
		}
		mc._x = x;
		mc._y = y;
		return ret;
	}
}
