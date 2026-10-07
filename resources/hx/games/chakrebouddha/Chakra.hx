package chakrebouddha;

import chakrebouddha.Anim;
import chakrebouddha.Common;
import chakrebouddha.Gfx;
import chakrebouddha.MC.FilterDef;

class Chakra {
	var game:Game;

	public var mc:MC;

	var mcActive:Active;

	public var type:Int;

	// glow / bglow: GradientGlowFilter(0, 45, [color, color], [0, 1], [0, 255], 8 / 2, 8 / 2, 2, 3, "outer"); the
	// strength of glow changes every frame (update)
	var glowColor:Int;
	var glowBlur:Float;
	var glowStrength:Float;
	var bglowColor:Int;
	var guest:Guest;
	var angle:Int;
	var strength:Int;
	var cycles:Float;
	var baseCycle:Float;
	var initDone:Bool;
	var fadeAlpha:Float;
	var lock:Bool;
	var animated:Chakra_Move;
	// temps d'attente avant de lancer l'animation
	var tempo:Int;
	// si le chakra est celui à toucher
	var activated:Bool;
	var rad:Float;
	var posY:Float;
	var factor:Int;
	var phys:Phys;

	public var color:Int;

	var useTempo:Bool;
	var invert:Bool;
	var transition:Float->Float;

	public var bonus:Bool;
	public var trap:Bool;
	public var missed:Bool;
	public var gameMissedFlag:Bool;

	public function new(game:Game, x:Float, y:Float, type:Int) {
		trap = false;
		bonus = false;
		baseCycle = 0;
		activated = false;
		tempo = 0;
		animated = null;
		lock = false;
		initDone = false;
		// (never set before miss: undefined, false in the tests)
		missed = false;
		gameMissedFlag = false;
		invert = false;
		useTempo = false;
		cycles = 0;
		this.game = game;
		this.type = type;
		mc = game.dm.attach("chakra", Const.DP_CHAKRAS, Game.K);
		mc._x = x;
		mc._y = y;
		mc.gotoAndStop(this.type);
		// (mc.smc.gotoAndStop(1): the symbols have one frame)

		mcActive = game.dm.add(new Active(), Const.DP_CHAKRAS);
		mcActive._x = mc._x;
		mcActive._y = mc._y;
		mcActive._xscale = mcActive._yscale = mc._xscale;
		mcActive._visible = false;
		mcActive.gotoAndStop(1);
		color = Const.COLORS[type - 1];
		glowColor = color;
		glowBlur = 8;
		glowStrength = 2;
		bglowColor = color;
		initGlow();
		// (desat = new ColorMatrixFilter(): never used)
		rad = 0;
		angle = 0;
		posY = y;
		factor = 0;
		phys = null;
		useTempo = false;
	}

	public function initGlow() {
		mcActive.gotoAndStop(1);
		mcActive._visible = false;
		initDone = true;
		cycles = 0;
		baseCycle = 0;
		fadeAlpha = 0;
		mcActive._alpha = 100;
		mcActive._xscale = mc._xscale;
		mcActive._yscale = mc._yscale;
		strength = 2;
		lock = false;
		activated = false;
		setGlow();
		trap = false;
	}

	function setGlow() {
		glowColor = Std.int(color);
		glowBlur = 8;
	}

	public function activate(cycles:Float) {
		bonus = false;

		if (Seed.random(KKApi.val(Const.BONUS_CHANCE)) == 0) {
			bonus = true;
			// ct.rgb = color, then the multipliers 0.3: 30 % of the picture plus the colour (Transform.colorTransform
			// also sets the alpha back to 100)
			mcActive.cx = [0.3, 0.3, 0.3, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF];
			mcActive._alpha = 100;
		} else if (Seed.random(KKApi.val(Const.TRAP_CHANCE)) == 0) {
			trap = true;
			// (the colour transform of the previous activation stays)
			mcActive.gotoAndStop(2);
		} else {
			mcActive.cx = [0.3, 0.3, 0.3, 255, 255, 255];
			mcActive._alpha = 100;
		}

		mcActive._visible = true;
		// (initGlow may have shrunk it back in this Flash frame: not shown shrinking from the end of the previous one)
		mcActive.snapNext();
		this.cycles = cycles;
		baseCycle = cycles;
		initDone = false;
		fadeAlpha = 100 / cycles;
		activated = true;
		invert = false;
		transition = null;
		gameMissedFlag = false;
	}

	// (the moves only change the picture: their random is the visual one)
	public function animate(a:Chakra_Move, config:Int) {
		animated = a;
		tempo = type * 10;
		switch (animated) {
			case Right:
				rad = 0;
				factor = 150;
				switch (config) {
					case 0:
						if (Seed.randomVfx(2) == 0) {
							animated = Null;
						}
					case 1:
						if (type % 2 == 0) {
							animated = Null;
						}
					case 2:
						if (type % 2 != 0) {
							animated = Null;
						}
					case 3:
						invert = true;
				}

			case Rotation:
				rad = 0;
				switch (config) {
					case 0:
						if (type % 2 == 0) {
							animated = Null;
						}
					case 1:
						if (type % 2 != 0) {
							animated = Null;
						}
					case 2:
						// (never true)
						if (type < 3 && type > 5) {
							animated = Null;
						}
					case 3:
						if (type < 2 && type > 6) {
							animated = Null;
						}
				}

			case Cardioid:
				useTempo = Seed.randomVfx(2) == 0;
				rad = 0;
				switch (config) {
					case 0:
						if (type == 4 || type == 6)
							animated = Rotation;
					case 1:
						if (type == 5 || type == 7)
							animated = Rotation;
					case 2:
						if (type < 4)
							animated = Null;
				}

			case Conchoid:
				useTempo = Seed.randomVfx(2) == 0;
				rad = 0;
				if (type < 3)
					animated = Null;
				switch (config) {
					case 0:
						if (type == 4 || type == 6)
							animated = Null;
					case 1:
						if (type == 3 || type == 5)
							animated = Null;
					case 2:
						if (type > 5)
							animated = Null;
				}

			case CBounce:
				rad = 0;
				transition = TransitionFunctions.get(Bounce);
				switch (config) {
					case 0:
						invert = true;
					case 1:
						if (type % 2 == 0)
							invert = true;
					case 2:
						if (type % 2 != 0)
							invert = true;
					case 3:
						useTempo = Seed.randomVfx(2) == 0;
				}

			case CElastic:
				// (rad is not set back to 0: what the previous move left)
				transition = TransitionFunctions.get(Elastic(3.5));
				if (type % 2 == 0)
					invert = true;
				switch (config) {
					case 0:
						useTempo = Seed.randomVfx(2) == 0;
				}

			case CQuint:
				rad = 0;
				transition = TransitionFunctions.get(Quint);
				if (type % 2 == 0)
					invert = true;
				switch (config) {
					case 0:
						useTempo = true;
				}

			case Test:
			case Null:
		}
	}

	public function setGuest(g) {
		guest = g;
	}

	public function miss() {
		missed = true;
		mc.gotoAndStop(mc._totalframes);
		color = 0x303030;
	}

	public function touch():Float {
		if (cycles <= 0)
			return -1.0;
		if (lock)
			return -1.0;
		lock = true;
		return cycles;
	}

	public function update() {
		if (!lock && activated && cycles <= 1 && !gameMissedFlag && !trap) {
			gameMissedFlag = true;
			game.missedChakra(this);
			mcActive._visible = false;
		}

		var tmod = mt.Timer.tmod;
		if (angle++ > 180)
			angle = 0;
		glowStrength = Math.sin(angle * Math.PI / 180) * strength;
		cycles -= tmod;

		if (cycles > 0) {
			if (lock) {
				mcActive._alpha -= fadeAlpha * tmod * 2;
			} else {
				mcActive._xscale += fadeAlpha * tmod * 10;
				mcActive._yscale = mcActive._xscale;
				mcActive._alpha -= fadeAlpha * tmod;
			}
		}

		if (animated == null) {
			recal();
		} else {
			var x = 0.0;
			var y = 0.0;
			switch (animated) {
				case Right:
					if (tempo-- <= 0) {
						if (rad > 360) {
							if (mc._x > 149 && mc._x < 151)
								mc._x = 150;
							endMoveAnim();
						} else {
							if (invert)
								x = 150 - Math.sin(rad * Math.PI / 180) * (factor--);
							else
								x = 150 + Math.sin(rad * Math.PI / 180) * (factor--);
							replaceX(x);
							rad += Const.SPEED * tmod;
						}
					}
				case Rotation:
					if (rad > 359) {
						if (x > 149 && x < 151)
							x = 150;
						endMoveAnim();
					} else {
						var tt = rad * Math.PI / 180;
						x = 150 + Math.sin(tt) * (150 - posY);
						y = 150 + Math.cos(tt) * (posY - 150);
						replaceX(x);
						replaceY(y);
						var xs = 100 + 20 * Math.sin(tt);
						var ys = 100 + 20 * Math.sin(tt);
						rescale(xs, ys);
						rad += Const.SPEED * tmod;
					}
				case Cardioid:
					if (!useTempo)
						tempo = -1;
					if (tempo-- <= 0) {
						if (rad > 359) {
							if (x > 149 && x < 151)
								x = 150;
							endMoveAnim();
						} else {
							var tt = rad * Math.PI / 180;
							x = mc._x + (2 * Math.cos(tt) - Math.cos(2 * tt));
							y = mc._y + (2 * Math.sin(tt) - Math.sin(2 * tt));
							replaceX(x);
							replaceY(y);
							rad += Const.SPEED * tmod;
						}
					}
				case Conchoid:
					if (!useTempo)
						tempo = -1;
					if (tempo-- <= 0) {
						if (rad > 359) {
							if (x > 149 && x < 151)
								x = 150;
							endMoveAnim();
						} else {
							var tt = rad * Math.PI / 180;
							var a = 5;
							// (NaN where cos(2 tt) < 0: Flash ignores the position, see MC)
							x = mc._x + a * Math.cos(tt) * Math.sqrt(Math.cos(2 * tt));
							y = mc._y + a * Math.sin(tt) * Math.sqrt(Math.cos(2 * tt));
							replaceX(x);
							replaceY(y);
							rad += Const.SPEED * tmod;
						}
					}
				case CBounce:
					if (!useTempo)
						tempo = -1;
					if (tempo-- <= 0) {
						if (rad > 100) {
							if (x > 149 && x < 151)
								x = 150;
							endMoveAnim();
						} else {
							var j = ease(rad / 100);
							if (invert)
								x = 150 - 140 * j;
							else
								x = 150 + 140 * j;
							replaceX(x);
							rad += 5 * tmod;
						}
					}

				case CElastic:
					if (!useTempo)
						tempo = -1;
					if (tempo-- <= 0) {
						if (rad > 100) {
							if (x > 149 && x < 151)
								x = 150;
							endMoveAnim();
						} else {
							var j = ease(rad / 100);
							if (invert)
								x = 150 + 40 * j;
							else
								x = 150 + 40 * j;
							replaceX(x);
							rad += 2 * tmod;
						}
					}

				case CQuint:
					if (!useTempo)
						tempo = -1;
					if (tempo-- <= 0) {
						if (rad > 100) {
							if (x > 149 && x < 151)
								x = 150;
							endMoveAnim();
						} else {
							var j = ease(rad / 100);
							if (invert)
								x = 150 - 120 * j;
							else
								x = 150 + 120 * j;

							replaceX(x);
							rad += 5 * tmod;
						}
					}

				case Test:
				case Null:
					endMoveAnim();
			}
		}

		if (animated != null) {
			game.plasma.drawMc(mc);
		}

		if (!initDone && cycles <= 0) {
			game.resetChakra(this);
		}

		if (missed)
			mc.filters = null;
		else
			mc.filters = [Glow(2, 2, bglowColor, 3), Glow(glowBlur, glowStrength, glowColor, 3)];
	}

	// transition(t): activate sets transition to null, also while a CBounce / CElastic / CQuint move runs (the chakra
	// to touch is drawn during the moves); AVM1 calls the null function as undefined, x is NaN and ignored: the chakra
	// stays where it is until rad passes 100
	function ease(t:Float):Float {
		return transition == null ? Math.NaN : transition(t);
	}

	// mcActive._x = mc._x = x (AVM1 gives both the value x: a NaN is ignored by each)
	function replaceX(x:Float) {
		mc._x = x;
		mcActive._x = x;
		updateGuest(x, 0);
	}

	function replaceY(y:Float) {
		mc._y = y;
		mcActive._y = y;
		updateGuest(0, y);
	}

	function rescale(xs:Float, ys:Float) {
		/*
			mcActive._xscale = mc._xscale = xs;
			mcActive._yscale = mc._yscale = ys;
		 */
	}

	function recal() {
		if (mc._x != 150) {
			mc._x = Std.int(Math.round(mc._x));
			if (mc._x > 150) {
				if (mc._x > 152)
					mc._x -= 2;
				else
					mc._x--;
				mcActive._x = mc._x;
			} else if (mc._x < 150) {
				if (mc._x < 148)
					mc._x += 2;
				else
					mc._x++;
				mcActive._x = mc._x;
			}
		}
		if (mc._y != posY) {
			mc._y = Std.int(Math.round(mc._y));
			if (mc._y > posY) {
				mc._y--;
				mcActive._y = mc._y;
			} else if (mc._y < posY) {
				mc._y++;
				mcActive._y = mc._y;
			}
		}
	}

	function updateGuest(x:Float, y:Float) {
		if (guest == null)
			return;
		guest.updateCoord(x, y);
	}

	function endMoveAnim() {
		if (phys != null) {
			phys.kill();
			phys = null;
		}
		game.resetAnim(animated);
		animated = null;
		tempo = 0;
	}

	public function clean() {
		mc.removeMovieClip();
		mc = null;
		mcActive.removeMovieClip();
		mcActive = null;
	}
}
