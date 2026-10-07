package kanjigaiden;

enum MonkeyBehaviour {
	Wait;
	Break;
	Walk;
	Ouch;
	Jump;
	Stunted;
}

// Monkey.hx of the original: a monkey on a plane, which walks, waits, and jumps to the plane in front of it (from the
// first plane: onto the player, the game over)
class Monkey extends Phys {
	public var mcMonkey:MC;

	public static var me:Monkey;

	var target:Int;
	var progress:Float;

	var mspeed:Int;
	var diff:Int;
	var life:Int;
	var mtype:Int;
	var btype:Int;

	var coolDown:Float;
	var coolJump:Float;
	var z:Float;
	var cz:Float;
	var stat:MonkeyBehaviour;
	var bound:Int;

	public var pl:Int;

	public var protected:Bool;

	var isSmart:Bool;

	// (Haxe 4: the fields are set after super(); the random draws and the clip keep the original's order)
	public function new(zemc:MC, czf:Float, zf:Float, nbPl:Int, ?itype:Int, ?ilife:Int, ?idiff:Int, ?bstype:Int) {
		var bound = Math.ceil((300 + 600 * (1 - czf)));

		// (_x is still 0: sin(0))
		zemc._y = zf - (Cs.SPHERATIO + 5 * (1 - czf)) * Math.sin(zemc._x / bound * 3.14);

		var isSmart = !(Seed.random(100) + Game.me.diff < 20);

		if (!isSmart) {
			zemc._x = Seed.random(bound - Cs.mcw - 50) + 175;
		} else {
			if (Seed.random(10) > 4) {
				var maxPos = Seed.random(Math.floor(Game.me.pos * 100)) / 100;
				zemc._x = Seed.random(Math.floor(maxPos * (bound - 150))) + 180;
			} else {
				var maxPos = Game.me.pos + (Seed.random(Math.floor((1 - Game.me.pos) * 100)) / 100);
				zemc._x = Math.floor(maxPos * bound + Seed.random(Math.floor((1 - maxPos) * bound))) - 180;
			}
		}

		super(zemc);
		z = zf;
		cz = czf;
		me = this;
		pl = nbPl;
		stat = Wait;
		mspeed = Cs.MSPEED;
		mcMonkey = zemc;
		this.bound = bound;
		protected = true;
		this.isSmart = isSmart;

		if (ilife != null) {
			life = ilife;
			diff = idiff;
		} else {
			var d = Seed.random(50 + Game.me.diff);
			if ((Game.me.diff + d) > 50) {
				diff = 3;
				life = 2;
			} else if ((Game.me.diff + d) > 40) {
				diff = 2;
				life = 2;
			} else {
				diff = 1;
				life = 1;
			}
		}

		if (itype != null) {
			btype = bstype;
			mtype = itype;
		} else {
			if (Seed.random(100) > 87) {
				btype = Seed.random(4);
				mtype = 4;
			} else {
				var t = Seed.random(12000);

				if (t > 11000) {
					if (t > 11500) {
						if (t > 11750) {
							mtype = 3;
						} else
							mtype = 2;
					} else
						mtype = 1;
				} else
					mtype = 0;
			}
		}

		mcMonkey._xscale = (cz * 100);
		mcMonkey._yscale = mcMonkey._xscale;

		vx = 0;
		coolDown = 10;
		coolJump = Seed.random(4 + pl) + 4 - diff;
		if (coolJump < 3)
			coolJump = 3;

		initMCs();
		var smc = mcMonkey.sub("smc");
		if (smc != null)
			smc.gotoAndPlay("_land");
	}

	inline function waveY():Float {
		return z - (Cs.SPHERATIO + 5 * (1 - cz)) * Math.sin(mcMonkey._x / bound * 3.14);
	}

	override public function update() {
		mspeed = Cs.MSPEED + Game.me.diff;
		super.update();

		if ((x > bound) || (x < 0)) {
			vx = -vx;
			mcMonkey._xscale = -mcMonkey._xscale;
		}

		switch (stat) {
			case Wait:
				mcMonkey._y = waveY();
				if (coolDown > 0) {
					coolDown -= Timer.tmod;
				} else {
					protected = false;
					coolDown = Seed.random(Cs.mCool);
					destiny();
				}

			case Break:
				vx *= Cs.q(Math.pow(0.80, Timer.tmod));
				mcMonkey._y = waveY();
				// (vx < 0 when it walked to the left: it stops at once)
				if (vx < 0.05) {
					vx = 0;
					initWait();
				}

			case Walk:
				if (Math.abs(vx) < mspeed)
					vx *= Cs.q(Math.pow(1.05, Timer.tmod));
				mcMonkey._y = waveY();
				if ((x < target + mspeed) && (x > target - mspeed)) {
					stat = Break;
					var smc = mcMonkey.sub("smc");
					if (smc != null)
						smc.gotoAndPlay("_break");
				}

			case Ouch:
				mcMonkey._y = waveY();
				if (coolDown > 0) {
					coolDown -= Timer.tmod;
				} else {
					protected = false;
					coolDown = Seed.random(Cs.mCool);
					destiny();
				}

			case Jump:
				if (Math.abs(vy) < (2 * mspeed))
					vy *= Cs.q(Math.pow(1.1, Timer.tmod));

				if (y < 0)
					initSwapPlan();

			case Stunted:
				mcMonkey._y = waveY();
				if (coolDown > 0) {
					coolDown -= Timer.tmod;
				} else {
					protected = false;
					coolDown = Seed.random(Cs.mCool);
					destiny();
				}
		}
	}

	function destiny() {
		if (coolJump > 1) {
			initWalk();
			coolJump -= Timer.tmod;
		} else {
			initJump();
		}
	}

	function initMCs() {
		mcMonkey.gotoAndStop(diff);

		var smc = mcMonkey.sub("smc");
		var ban = smc != null ? smc.getClip("smc") : null;
		if (ban != null) {
			if (mtype != 4)
				ban.gotoAndStop(mtype + 1);
			else
				ban.gotoAndStop(5 + btype);
		}
	}

	function initWait() {
		stat = Wait;
		vx = 0;
		coolDown = Seed.random(Cs.mCool - Game.me.diff);
		protected = false;
		initMCs();
	}

	function initWalk() {
		progress = 0;
		stat = Walk;
		protected = false;
		var delta:Float = 0;
		var sens:Float = 1;

		if (isSmart) {
			// left
			if (mcMonkey._x < (bound * Game.me.pos)) {
				while (Math.abs(delta) < 40) {
					var maxPos = Seed.random(Math.floor(Game.me.pos * 100)) / 100;
					target = Math.floor(maxPos * (bound - 340)) + 170;
					delta = Math.floor(target - mcMonkey._x);
					sens = Math.floor(delta / Math.abs(delta));
				}
			} else {
				while (Math.abs(delta) < 40) {
					var maxPos = Game.me.pos + (Seed.random(Math.floor((1 - Game.me.pos) * 100)) / 100);
					target = Math.floor(maxPos * (bound - 340)) + 170;
					delta = Math.floor(target - mcMonkey._x);
					sens = Math.floor(delta / Math.abs(delta));
				}
			}
		} else {
			while (Math.abs(delta) < 40) {
				target = Seed.random(bound - Cs.mcw - 100) + 160;
				delta = Math.floor(target - mcMonkey._x);
				sens = Math.floor(delta / Math.abs(delta));
			}
		}

		if (target < 170)
			target = 170;
		else if (target > (bound - 170))
			target = bound - 170;

		vx = sens * (mspeed * 0.5);

		mcMonkey._xscale = -sens * Math.abs(mcMonkey._xscale);
		var smc = mcMonkey.sub("smc");
		if (smc != null)
			smc.gotoAndPlay("_startrun");
		initMCs();
	}

	function initJump() {
		protected = true;
		stat = Jump;
		coolDown = Seed.random(Cs.mCool);
		var smc = mcMonkey.sub("smc");
		if (smc != null)
			smc.gotoAndPlay("_jump");
		initMCs();
		vy = -mspeed;
	}

	function initSwapPlan() {
		#if debug
		Game.me.stats.jumps++;
		#end
		vy = 0;
		destroy();
		Game.me.addAMonkeySpecial(pl - 1, mtype, life, diff, btype);
	}

	function initStunted() {
		#if debug
		Game.me.stats.stunned++;
		#end
		stat = Stunted;
		vx = 0;
		coolDown = Seed.random(150) + 100;
		protected = false;
		var smc = mcMonkey.sub("smc");
		if (smc != null)
			smc.gotoAndPlay("_stunted");
		initMCs();
	}

	public function ouch(type:Int) {
		#if debug
		Game.me.stats.hits++;
		#end
		if (type == 4) {
			if (stat == Stunted) {
				if (life <= 0) {
					kill();
				} else {
					stat = Ouch;
					vx = 0;
					coolDown = 15;
					protected = true;
					var smc = mcMonkey.sub("smc");
					if (smc != null)
						smc.gotoAndPlay("_ouch");
					initMCs();
				}
			} else {
				initStunted();
			}
		} else {
			if (type == 3) {
				life -= 2;
			} else
				life--;

			if (life <= 0) {
				kill();
			} else {
				stat = Ouch;
				vx = 0;
				coolDown = 15;
				protected = true;
				var smc = mcMonkey.sub("smc");
				if (smc != null)
					smc.gotoAndPlay("_ouch");
				initMCs();
			}
		}
	}

	// (not Phys.kill: the clip stays, its "_die" animation removes it, _parent.removeMovieClip() on frame 155)
	override public function kill() {
		#if debug
		Game.me.stats.kills++;
		Game.me.stats.kinds[mtype]++;
		#end
		Game.me.monkeys.remove(this);
		if (mtype == 4) {
			Game.me.scoreIt(Cs.PTS[0]);
		} else if (mtype == 0) {
			Game.me.scoreIt(Cs.PTS[pl]);
		} else
			Game.me.scoreIt(Cs.BONUS[mtype]);

		var smc = mcMonkey.sub("smc");
		if (smc != null)
			smc.gotoAndPlay("_die");
		initMCs();
		if (mtype == 4)
			Game.me.bonusMe(btype);
	}

	public function destroy() {
		mcMonkey.removeMovieClip();
		Game.me.monkeys.remove(this);
	}

	// port: mcMonkey._width (Plan.hittest), measured on the SWF for the frame of the monkey (diff), of its smc and of
	// the banana it holds (Data.monkeyWidths), times its scale
	public function width():Float {
		if (mcMonkey.removed)
			return Math.NaN;
		var smc = mcMonkey.sub("smc");
		if (smc == null)
			return 0;
		var row:Dynamic = Data.monkeyWidths()[mcMonkey._currentframe - 1][smc.frame - 1];
		var w:Float;
		if (Std.isOfType(row, Array)) {
			var ban = smc.getClip("smc");
			w = (row : Array<Float>)[(ban != null ? ban.frame : 1) - 1];
		} else
			w = row;
		return w * Math.abs(mcMonkey._xscale) / 100;
	}
}
