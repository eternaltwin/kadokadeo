package popcorn;

import popcorn.Game.GameAnimSprite;
import mt.bumdum.Lib.Num;
import common_haxe_avm1.KeyboardManager;
import mt.Timer;

class McJumpCircle extends ASprite {
	public var cran:ASprite;
}

class Hero extends Phys {
	static var WALK_FRAME_MAX = 12;
	static var FLIGHT_CONTROL = 0.35 * Cs.NEW_GEN_SCALE;

	static var RAY = 5 * Cs.NEW_GEN_SCALE;
	static var SP_FRICT = 0.7;
	static var ACC = 3 * Cs.NEW_GEN_SCALE;

	static var CLIMB_MAX = 24 * Cs.NEW_GEN_SCALE;
	static var CLIMB_SPEED = 2 * Cs.NEW_GEN_SCALE;

	public var step:Int;
	public var animFrame:Map<String, Int> = new Map();

	var comboIndex:Int;

	var extraJump:Int;

	var speed:Float;
	var frame:Float;

	public var jumpPower:Float;

	var jumpAngle:Float;
	var jumpCircle:McJumpCircle;
	var jumpCircleFrame = 0;

	public var trg:Corn;

	var px:Int;
	var py:Int;

	public function new(mc:ASprite) {
		mc = Cs.game.dm.attach("mcPiou", Game.DP_PIOU);
		super(mc);
		animFrame.set("walk", 1);
		animFrame.set("turn", 14);
		animFrame.set("fly", 44);
		mc.onFrame.set(13, function() {
			mc.gotoAndPlay(1);
		});
		mc.onFrame.set(43, function() {
			mc.gotoAndPlay(14);
		});
		mc.onFrame.set(45, function() {
			mc.gotoAndPlay(44);
		});
		initStep(0);
	}

	inline function isLeftDown():Bool {
		return KeyboardManager.isDown(KeyboardManager.LEFT)
			|| KeyboardManager.isDown(KeyboardManager.Q)
			|| KeyboardManager.isDown(KeyboardManager.A);
	}

	inline function isRightDown():Bool {
		return KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D);
	}

	public function initStep(n:Int):Void {
		switch (step) {
			case 0: // FLY;
				weight = 0;
				removeBouncer();
				vx = 0;
				vy = 0;
				flOrient = false;
			case 1:
				y -= RAY;
		}

		step = n;

		switch (step) {
			case 0: // FLY;
				weight = 0.5 * Cs.NEW_GEN_SCALE;
				x = Num.mm((RAY + 3 * Cs.NEW_GEN_SCALE), x, Cs.mcw - (RAY + 3 * Cs.NEW_GEN_SCALE));
				bouncer = new RoundBouncer(this);
				bouncer.onBounceAngle = this.col;
			// root.gotoAndStop(2);

			case 1: // WALK;
				comboIndex = 0;
				// root.gotoAndStop(1);
				speed = 0;
				root._rotation = 0;
				y += RAY;
				px = Std.int(x);
				py = Std.int(y);
				frame = 0;
		}
	}

	override public function update():Void {
		super.update();
		var lim = RAY + 4 * Cs.NEW_GEN_SCALE;
		switch (step) {
			case 0: // FLY;

				bouncer.px = Std.int(Num.mm(lim, bouncer.px, Cs.mcw - lim));
				if (Cs.game.step == 1) {
					if (trg == null) {
						// COL CORN
						for (sp in Cs.game.cList) {
							if ((sp.bouncer != null || sp.step == 0) && getDist({x: sp.x, y: sp.y}) < 16 * Cs.NEW_GEN_SCALE) {
								initJump();
								trg = sp;
								vx = 0;
								vy = 0;
								root.gotoAndStop(animFrame.get("turn"));
								root._rotation = 0;
								flOrient = false;
							}
						}

						// COL BOSS
						if (Cs.game.boss.step < 3 && getDist({x: Cs.game.boss.x, y: Cs.game.boss.y}) < 32 * Cs.NEW_GEN_SCALE) {
							Cs.game.boss.hit();
						}

						// CONTROL FLIGHT
						var sens = 0;
						if (isLeftDown())
							sens = -1;
						if (isRightDown())
							sens = 1;
						vx += sens * FLIGHT_CONTROL * Timer.tmod;
					}
					updateJump();
				}

				if (bouncer != null && bouncer is RoundBouncer) {
					var b:RoundBouncer = cast bouncer;
					while (b.isRoundFree(b.px, b.py) != null) {
						b.py--;
					}
				}

			case 1: // WALK;
				walk();
				if (Cs.game.step == 1) {
					updateJump();
					if (Cs.game.cList.length == 0 && Cs.game.boss.step == 4) {
						Cs.game.initStep(9);
					}
				}
				x = Std.int(Num.mm(lim, x, Cs.mcw - lim));

			case 2: // KICK !
		}
		if (y > Cs.HEIGHT) {
			Cs.game.initStep(9);
		}
	}

	public function col(a:Float, n:Float):Void {
		// LAND
		// var p = Math.min(Math.sqrt(vx*vx+vy*vy)*0.1, 0.8)
		if (Math.abs(Num.hMod(1.57 - n, 3.14)) < 1.57) {
			initStep(1);
		}
	}

	public function walk():Void {
		// CONTROL

		if (isLeftDown()) {
			speed -= ACC * Timer.tmod;
			root._xscale = -100;
			root._prevState.xscale = root._curState.xscale;
		}
		if (isRightDown()) {
			speed += ACC * Timer.tmod;
			root._xscale = 100;
			root._prevState.xscale = root._curState.xscale;
		}
		speed *= Math.pow(SP_FRICT, Timer.tmod);

		if (jumpPower != null) {
			speed = 0;
		}

		var parc = Math.abs(speed);
		var sens = Std.int(speed / parc);

		if (jumpPower == null) {
			frame = (frame + parc) % WALK_FRAME_MAX;
			root.gotoAndStop(Std.int(frame) + 1);
		}

		while (parc > 1) {
			var rot = 0;
			var cl = null;
			var flJump = false;
			for (i in 0...CLIMB_MAX) {
				if (Cs.game.isFree(px + sens, py - i)) {
					cl = i;
					break;
				}
			}
			if (cl == 0) {
				for (i in 0...CLIMB_MAX) {
					if (Cs.game.isFree(px + sens, py + 1 - cl)) {
						cl--;
					} else {
						break;
					}
				}
				if (cl == -CLIMB_MAX) {
					cl = null;
					flJump = true;
				}
			}

			if (cl != null) {
				if (cl <= CLIMB_SPEED && cl >= -CLIMB_SPEED) {
					px += sens;
					py -= cl;
				} else {
					py -= Std.int(Num.mm(-CLIMB_SPEED, cl, CLIMB_SPEED));
				}
			} else {
				if (flJump) {
					initStep(0);
					if (bouncer != null && bouncer is RoundBouncer) {
						var b:RoundBouncer = cast bouncer;
						while (b.isRoundFree(b.px, b.py) != null) {
							b.py--;
						}
					}
					vx = sens * 3 * Cs.NEW_GEN_SCALE;
					vy = -3 * Cs.NEW_GEN_SCALE;
					root.gotoAndStop(animFrame.get("fly"));
					flOrient = true;
				} else {
					speed *= -1;
				}

				break;
			}
			parc--;
		}

		// Y RECAL
		while (!Cs.game.isFree(px, py))
			py--;

		// CORN
		for (sp in Cs.game.cList) {
			if (sp.bouncer != null && getDist({x: sp.x, y: sp.y}) < 16 * Cs.NEW_GEN_SCALE) {
				sp.vx += 5 * sens * Cs.NEW_GEN_SCALE;
				sp.vy -= 2 * Cs.NEW_GEN_SCALE;
			}
		}

		x = px;
		y = py;
	}

	public function updateJump():Void {
		if (jumpPower != null) {
			// CONTROL

			var acc = 0.1; // 0.15;
			if (isLeftDown()) {
				jumpAngle -= acc;
			}
			if (isRightDown()) {
				jumpAngle += acc;
			}
			// jumpAngle *= 0.9

			// POWEER
			jumpPower += 5 * Cs.NEW_GEN_SCALE * Timer.tmod;
			jumpPower *= Math.pow(0.8, Timer.tmod);

			// TRG
			if (trg != null) {
				var a = jumpAngle - 1.57;
				var dx = Math.cos(a) * 6 * Cs.NEW_GEN_SCALE;
				var dy = Math.sin(a) * 6 * Cs.NEW_GEN_SCALE;
				if (bouncer != null) {
					bouncer.setPos(trg.x + dx, trg.y + dy);
				}
				root._rotation = a / 0.0174 + 90;
			}

			// CIRCLE
			jumpCircle._xscale = 1.25 * jumpPower;
			jumpCircle._yscale = jumpCircle._xscale;
			jumpCircle._x = x;
			jumpCircle._y = y;
			jumpCircle._visible = jumpCircleFrame++ % 2 == 0;
			jumpCircle.cran._rotation = jumpAngle / 0.0174;
			jumpCircle.cran._x = x;
			jumpCircle.cran._y = y;

			// AUTO RELEASE
			if (jumpPower > 18 * Cs.NEW_GEN_SCALE)
				releaseJump();
		}
	}

	public function action():Void {
		if (Cs.game.step == 1) {
			if (step == 0 && trg == null && extraJump > 0) {
				var sens = 0;
				if (isLeftDown())
					sens = -1;
				if (isRightDown())
					sens = 1;
				vy = -10 * Cs.NEW_GEN_SCALE;
				vx += sens * 3 * Cs.NEW_GEN_SCALE;
				extraJump--;

				var mc:GameAnimSprite = cast Cs.game.dm.attach("mcImpact", Game.DP_PART);
				mc._x = x;
				mc._y = y;
				mc._xscale = 50;
				mc._yscale = mc._xscale;
				mc.frame = 0;
				mc.fs = 9;
				mc.play();
				Cs.game.animator.push(mc);
			}

			if (jumpPower != null) {
				releaseJump();
			}

			if (jumpPower == null && step == 1) {
				initJump();
			}
		}
	}

	public function releaseJump():Void {
		if (jumpPower > 5 * Cs.NEW_GEN_SCALE) {
			initStep(0);

			if (bouncer != null && bouncer is RoundBouncer) {
				var b:RoundBouncer = cast bouncer;
				while (b.isRoundFree(b.px, b.py) != null) {
					b.py--;
				}
			}

			vx = Math.cos(jumpAngle - 1.57) * jumpPower;
			vy = Math.sin(jumpAngle - 1.57) * jumpPower;

			flOrient = true;
			root.gotoAndStop(animFrame.get("fly"));
			root._xscale = 100;
		}
		jumpCircle.cran.removeMovieClip();
		jumpCircle.removeMovieClip();
		jumpPower = null;
		jumpCircleFrame = 0;

		if (trg != null) {
			var sc = Cs.COMBO[comboIndex];
			Cs.game.setScore(trg.x, trg.y, sc, 100);
			comboIndex = Std.int(Math.min(comboIndex + 1, 8));

			//
			trg.explode(-vx * 0.5, -vy * 0.5);
			trg = null;
		}
	}

	public function initJump():Void {
		Cs.game.initGrey();
		if (jumpPower != null) {
			jumpCircle.cran.removeMovieClip();
			jumpCircle.removeMovieClip();
		}
		extraJump = 1;
		jumpPower = 0;
		jumpCircle = cast Cs.game.dm.attach("mcPowerCircle", Game.DP_BG);
		jumpCircle.cran = Cs.game.dm.attach("cran", Game.DP_BG);
		// if (trg == null)
		//	jumpCircle.cran._visible = false;
		jumpAngle = 0;
	}
}
