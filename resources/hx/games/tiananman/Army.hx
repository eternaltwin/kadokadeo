package tiananman;

import js.html.CSS;
import pixi.filters.colormatrix.ColorMatrixFilter;
import common_haxe_avm1.display.BBox;
import tiananman.tanks.*;
import pixi.core.math.shapes.Rectangle;
import pixi.core.text.Text;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;

class ArmyPartSprite extends ASprite {
	public var _weapon:ASprite;
}

class ArmyMcSprite extends ASprite {
	public var _p:ArmyPartSprite;
	public var _bBox:ASprite;
	public var _bBoxMove:ASprite;
}

class ArmyTargetSprite extends ASprite {
	public var _field:Text;
	public var _bBox:BBox;
}

enum MoveStep {
	Move;
	Explode;
}

class Army {
	static var BASE_SPEED = [0.44, 0.60, 0.32, 0.79, 0.25];
	static var POP_PROBS = [600, 400, 250, 100, 50];
	static var MAX_BLOCK = 400;
	static var SPEED_MULT = Cs.s(5.8);
	static var PROUTCH_SLOW = 0.2;
	static var ANIM_FRAMES = [
		{
			id: "drive",
			start: 1,
			frames: 40,
			next: "drive"
		},
		{
			id: "break",
			start: 42,
			frames: 1,
			next: "drive"
		}
	];

	static var WEAPON_LEVEL = 2;
	static var WEAPON_LIMIT_START_ANG = [60, 120];
	static var WEAPON_MAX_DELTA_ANG = 25;
	static var WEAPON_RANGE = {min: 2.6, max: 4.0};
	static inline var WEAPON_MUZZLE_X = 32.0;
	static inline var WEAPON_TARGET_SPREAD = 0.45;

	static public var PLACES = [[{l: null, t: [Cs.mcw[0], Cs.mcw[1]]}], [{l: null, t: [Cs.mch[0], Cs.mch[1]]}]];
	static public var NEXT_ID:Int = 0;

	public var level:Int;
	public var preWidth:Float;
	public var preHeight:Float;
	public var mc:Bad;
	public var x:Float;
	public var y:Float;
	public var typeDir:Int;
	public var dir:Array<Int>;
	public var place:{l:Array<Army>, t:Array<Float>}; // save place taken in static tab PLACES
	public var proutchTimer:Float;

	public var cAnim:{
		id:String,
		start:Int,
		frames:Int,
		next:String
	};

	var weaponTimer:Float;
	var weaponStep:Int;
	var weaponInfos:{
		ang:Float,
		fromAng:Int,
		toAng:Int,
		target:ArmyTargetSprite,
		bomb:ASprite,
		bsx:Float,
		bsy:Float
	};

	var warning:ASprite;
	var warningTimer:Float;

	public var speed:Float;

	var step:MoveStep;
	var timer:Float;
	var subStep:Int;

	var creationTime:Int;
	var moved:Bool;
	var blocked:{nb:Int, by:Army};

	public function new(diff:Int, ?forceLevel:Int) {
		var hide = Cs.HIDE_START;

		step = Move;
		subStep = 0;
		timer = 0;

		blocked = null;
		moved = false;
		proutchTimer = null;
		creationTime = NEXT_ID++;

		cAnim = ANIM_FRAMES[0];

		typeDir = Seed.random(4);

		// forceLevel = 2;

		var i = 0;
		var found = false;
		var rot = 0;

		while (!found) {
			level = forceLevel != null ? forceLevel : Cs.randomProbs(POP_PROBS.slice(0, Std.int(Math.min(diff + 1, POP_PROBS.length)) - i));
			var size = getTankSize(level);
			preWidth = size.width;
			preHeight = size.height;
			speed = 0.1;

			i++;

			var p = findPlace(typeDir, this);

			if (p == null) {
				if (i > 2)
					break;
				if (typeDir == 0 || typeDir == 2)
					typeDir = Seed.random(2) * 2 + 1;
				else
					typeDir = Seed.random(2) * 2;
				continue;
			}

			found = true;
			// typeDir = 1;

			switch (typeDir) {
				case 0: // from north
					dir = [0, 1];
					rot = -90;
					x = p;
					y = Cs.mch[0] - hide;
				case 1: // from east
					dir = [-1, 0];
					rot = 0;
					x = Cs.mcw[1] + hide;
					y = p;
				case 2: // from south
					dir = [0, -1];
					rot = 90;
					// mc._p._yscale = -100 ;
					x = p + preWidth;
					y = Cs.mch[1] + hide;
				case 3: // from west
					dir = [1, 0];
					rot = 180;
					// mc._p._yscale = -100 ;
					x = Cs.mcw[0] - hide;
					y = p + preHeight;
			}
		}

		if (!found) {
			kill();
			// trace("#################################### NOT FOUND ") ;
			return;
		}
		var tank = createTank(level);
		mc = Game.me.adm.root_mc.addChild(tank);
		mc._p.gotoAndStop(cAnim.start);
		mc._rotation = rot;
		mc._x = x;
		mc._y = y;
		initWarning();

		if (level == WEAPON_LEVEL)
			initWeapon();

		Game.me.army.push(this);

		// trace("new army : " + level + " # " + diff) ;
	}

	static function getTankSize(level:Int):{width:Float, height:Float} {
		switch (level) {
			case 0:
				return {width: Tank1._preWidth, height: Tank1._preHeight};
			case 1:
				return {width: Tank2._preWidth, height: Tank2._preHeight};
			case 2:
				return {width: Tank3._preWidth, height: Tank3._preHeight};
			case 3:
				return {width: Tank4._preWidth, height: Tank4._preHeight};
			case 4:
				return {width: Tank5._preWidth, height: Tank5._preHeight};
			case _:
				return {width: Tank1._preWidth, height: Tank1._preHeight};
		}
	}

	function createTank(level:Int):Bad {
		switch (level) {
			case 0:
				return new Tank1(this);
			case 1:
				return new Tank2(this);
			case 2:
				return new Tank3(this);
			case 3:
				return new Tank4(this);
			case 4:
				return new Tank5(this);
			case _:
				return new Tank1(this);
		}
	}

	function initWarning():Void {
		warning = Game.me.mdm.attach("warning", Game.DP_WARNING);
		warningTimer = 100;
		var warningDelta = Cs.s(4);
		var c = getCenter();

		switch (typeDir) {
			case 0: // from north
				warning._rotation = -90;
				warning._x = c.x;
				warning._y = Cs.mch[0] + warningDelta;
			case 1: // from east
				warning._rotation = 0;
				warning._x = Cs.mcw[1] - warningDelta;
				warning._y = c.y;
			case 2: // from south
				warning._rotation = 90;
				warning._x = c.x;
				warning._y = Cs.mch[1] - warningDelta;
			case 3: // from west
				warning._rotation = 180;
				warning._x = Cs.mcw[0] + warningDelta;
				warning._y = c.y;
		}
	}

	public function setProutch() {
		if (proutchTimer != null)
			return;
		proutchTimer = 0;
		speed -= PROUTCH_SLOW;
	}

	function getStart():Float {
		switch (typeDir) {
			case 0: // from north
				return Cs.mch[0] - Cs.HIDE_START;
			case 1: // from east
				return Cs.mcw[1] + Cs.HIDE_START;
			case 2: // from south
				return Cs.mch[1] + Cs.HIDE_START;
			case 3: // from west
				return Cs.mcw[0] - Cs.HIDE_START;
			case _:
				return null;
		}
	}

	function initWeapon(?inGame = false) {
		if (mc.travelDone(65.0)) {
			if (weaponInfos.target != null)
				weaponInfos.target.removeMovieClip();
			weaponInfos = null;
			return;
		}

		if (mc._p._weapon == null)
			return;

		weaponTimer = 100;
		weaponStep = 0;

		var left = false;
		var right = false;
		var t = [];
		var fromAng = 0;
		var sway = 1;
		if (inGame) {
			fromAng = Std.int(mc._p._weapon._rotation);
			if (fromAng == 0)
				fromAng = 1;
			sway = Std.int((fromAng / Math.abs(fromAng)) * (if (Math.abs(fromAng) > (WEAPON_LIMIT_START_ANG[1] - WEAPON_LIMIT_START_ANG[0]
				+ WEAPON_LIMIT_START_ANG[0]) / 2) -1 else 1));
			// trace("new sway " + fromAng + " ==> " + sway) ;
		} else {
			var pc = 0.6;
			var wd = Cs.s(32);
			// var wd = Cs.s(77);
			var minPlace = WEAPON_RANGE.max * wd * pc;
			switch (typeDir) {
				case 0:
					right = x - Cs.mcw[0] >= minPlace;
					left = Cs.mcw[1] - x >= minPlace;
				case 1:
					right = y - Cs.mch[0] >= minPlace;
					left = Cs.mch[1] - y >= minPlace;
				case 2:
					left = x - Cs.mcw[0] >= minPlace;
					right = Cs.mcw[1] - x >= minPlace;
				case 3:
					left = y - Cs.mch[0] >= minPlace;
					right = Cs.mch[1] - y >= minPlace;
			}

			if (left)
				t.push([WEAPON_LIMIT_START_ANG[0], WEAPON_LIMIT_START_ANG[1], -1]);
			if (right)
				t.push([WEAPON_LIMIT_START_ANG[0], WEAPON_LIMIT_START_ANG[1], 1]);

			if (t.length == 0)
				return;

			var r = t[Seed.random(t.length)];
			fromAng = Std.int((r[0] + Seed.random(r[1] - r[0])) * r[2]);
			sway = r[2] * (if (Math.abs(fromAng) > (WEAPON_LIMIT_START_ANG[1] - WEAPON_LIMIT_START_ANG[0]) / 2 + WEAPON_LIMIT_START_ANG[0]) -1 else 1);

			// trace("minPlace " + minPlace + " # " + x + ", " + y + " ==>" + left + " / " + right + " ==> " + fromAng + " -- " + sway) ;
		}

		weaponInfos = {
			ang: 0.0,
			fromAng: fromAng,
			toAng: fromAng + (sway * (10 + Seed.random(Std.int(WEAPON_MAX_DELTA_ANG - 10)))),
			target: null,
			bomb: null,
			bsx: null,
			bsy: null
		};

		mc._p._weapon._rotation = fromAng;
	}

	public function resetMoveFlag() {
		moved = false;
	}

	function warningUpdate():Bool {
		if (warning == null)
			return false;

		if (warningTimer != null) {
			warningTimer = Math.max(0.0, warningTimer - 3.0 * mt.Timer.tmod);
			if (warningTimer == 0 || !Cs.outOfBounds(x, y, 25))
				warningTimer = null;
			return (warningTimer != null && warningTimer > 15.0);
		}

		warning._alpha -= 2.0 * mt.Timer.tmod;
		if (warning._alpha <= 0.0) {
			warning.removeMovieClip();
			warning = null;
		}
		return false;
	}

	public function update(mod:Float) {
		if (warningUpdate())
			return;

		switch (step) {
			case Move:
				var isBlocked = checkBlock(mod);

				if (weaponInfos != null)
					updateWeapon(isBlocked, mod);

				if (!isBlocked) {
					switch (subStep) {
						case 0:
							/*if (timer == 0.0)
								mc.gotoAndPlay("_start") ; */

							timer = Num.mm(0.0, timer + 0.05 * /*mt.Timer.tmod*/ mod, 1.0);

							var delta = Math.pow(timer, 3);
							speed = BASE_SPEED[level] * delta;

							if (timer == 1.0) subStep = 2;

						case 2: // normal move, nothing to do here
							if (proutchTimer != null) {
								proutchTimer = Num.mm(0.0, proutchTimer + 0.05 * /*mt.Timer.tmod*/ mod, 1.0);

								var delta = Math.pow(proutchTimer, 5);
								speed = BASE_SPEED[level] - PROUTCH_SLOW + PROUTCH_SLOW * delta;

								if (proutchTimer == 1)
									proutchTimer = null;
							}
					}

					if (speed > 0.0) {
						updateAnim(mod);
						move(mod);
					}
				}

			case Explode:
				switch (subStep) {
					case 0:
						if (timer == 0) {
							for (a in Game.me.army) {
								if (a != this && a.blocked != null && a.blocked.nb > MAX_BLOCK / 2)
									a.blocked.nb -= Std.int(MAX_BLOCK / 6);
							}
						}

						timer = Math.min(timer + 0.05 * /*mt.Timer.tmod*/ mod, 1);
						Col.setPercentColor(mc._p, timer * 100, 0xFFFFFF);
						if (timer == 1.0) {
							timer = 0;
							subStep = 1;
						}

					case 1:
						timer = Math.min(timer + 0.08 * /*mt.Timer.tmod*/ mod, 1);
						mc._p._alpha = if (mc._p._alpha < 50) 100 else 20;
						if (timer == 1.0) {
							timer = 0;
							subStep = 2;
						}

					case 2:
						explose();
				}
		}
	}

	function getAnim(name:String) {
		for (a in ANIM_FRAMES) {
			if (a.id == name)
				return a;
		}
		// trace("anim name : " + name + " not found.") ;
		return null;
	}

	function updateAnim(mod:Float) {
		if (mc == null) {
			return;
		}
		var fps = Cs.FPS;
		var c = mc._p._currentframe;
		var nf = Std.int(fps * mod);

		var a = cAnim;

		if (nf + c <= a.start + a.frames)
			mc._p.gotoAndStop(nf + c);
		else {
			if (a.next == a.id) // repeat anim
				mc._p.gotoAndStop(a.start + (nf + c - a.start) % a.frames);
			else // goto next
				mc.gotoAndStop(parseNextFrame(a, c, nf));
		}

		if (weaponInfos == null || weaponInfos.bomb == null)
			return;

		c = weaponInfos.bomb._currentframe;
		var tot = weaponInfos.bomb._totalframes;

		// weaponInfos.bomb.gotoAndStop((c + nf) % tot);
		weaponInfos.bomb.gotoAndStop((weaponInfos.bomb._currentframe + nf) % weaponInfos.bomb._totalframes);

		c = weaponInfos.bomb._currentframe;
		tot = weaponInfos.bomb._totalframes;
		if (c + nf < tot) {
			weaponInfos.bomb.gotoAndStop(Std.int(Math.min(c + nf, tot - 1)));
		}
	}

	function parseNextFrame(a:{
		start:Int,
		next:String,
		id:String,
		frames:Int
	}, from:Int, f:Int):Int {
		var todo = a.start + a.frames - from;
		if (f <= todo) {
			cAnim = a;
			return from + f;
		}

		return parseNextFrame(getAnim(a.next), a.start + a.frames, f - todo);
	}

	public function explose() {
		var c = getCenter();
		var bmc = Game.me.mdm.attach("tankBoom", Game.DP_PARTS);

		bmc.removeOnFrame = 20;
		bmc._x = c.x;
		bmc._y = c.y;
		bmc._xscale = 120;
		bmc._yscale = bmc._xscale;
		bmc.gotoAndStop(1);
		Game.ExplosionList.push(bmc);

		kill();
	}

	function updateWeapon(isBlocked:Bool, mod:Float) {
		if (weaponInfos == null || (Cs.outOfBounds(x, y) && beginTravel()))
			return;

		switch (weaponStep) {
			case 0: // sleep
				if (Cs.outOfBounds(x, y))
					return;

				weaponTimer = Math.max(0.0, weaponTimer - 9 * mod);
				if (weaponTimer == 0) {
					weaponStep = 1;
					weaponTimer = 100;
				}

			case 1: // rotate weapon
				weaponInfos.ang = Num.q(weaponInfos.ang + mod * 0.4);
				var delta = Num.q(weaponInfos.toAng - weaponInfos.fromAng);
				var pdelta = Num.q(Math.abs(delta));
				if (weaponInfos.ang > pdelta) {
					weaponStep = 2;
					weaponTimer = 100;
					weaponInfos.ang = pdelta;
					if (mc != null) {
						mc._p._weapon._rotation = Num.q(weaponInfos.toAng);
					}

					initWeaponTarget();
					if (weaponStep != 2 || weaponInfos == null || mc == null)
						return;
				}

				if (weaponInfos != null && mc != null) {
					mc._p._weapon._rotation = Num.q(weaponInfos.fromAng + weaponInfos.ang * delta / pdelta);
				}

			case 2: // init fire
				var wp = getWeaponPoint();
				if (mc == null) {
					return;
				}
				Cs.rotateMc(mc._p._weapon, weaponInfos.target._x, weaponInfos.target._y, wp.x, wp.y, -mc._rotation);

				var save = weaponTimer;
				weaponTimer = Num.q(Math.max(0.0, weaponTimer - 3.0 * mod));

				var tier = 100 / 3;
				for (i in 1...4) {
					if (save > 100 - tier * i && weaponTimer <= 100 - tier * i) {
						var t = 3 - i;
						weaponInfos.target._field.text = Std.string(t);
						break;
					}
				}

				if (weaponInfos.bomb != null) {
					var bt = Num.q(weaponTimer * 2 / 100);
					weaponInfos.bomb._x = Num.q(weaponInfos.bsx * bt + weaponInfos.target._x * (1 - bt));
					weaponInfos.bomb._y = Num.q(weaponInfos.bsy * bt + weaponInfos.target._y * (1 - bt));
					// weaponInfos.bomb._rotation += mod * 20 ;
				} else {
					if (weaponTimer < 50) {
						weaponInfos.bomb = Game.me.mdm.attach("bomb", Game.DP_BOMB);
						weaponInfos.bomb.gotoAndStop(1);
						var b = getWeaponMuzzlePoint();
						weaponInfos.bsx = b.x;
						weaponInfos.bsy = b.y;
						weaponInfos.bomb._x = weaponInfos.bsx;
						weaponInfos.bomb._y = weaponInfos.bsy;
						weaponInfos.bomb._rotation = Seed.randomVfx(360);
					}
				}

				if (weaponTimer == 0) {
					weaponStep = 0;
					weaponTimer = 100;

					fire();

					initWeapon(true);
				}
		}
	}

	function fire() {
		// mc._p._weapon.smc.gotoAndPlay(2) ;
		var bmc = Game.me.mdm.attach("mcExplosion", Game.DP_PARTS);
		bmc.removeOnFrame = 24;
		bmc.gotoAndStop(1);
		bmc._x = weaponInfos.target._x;
		bmc._y = weaponInfos.target._y;
		Game.ExplosionList.push(bmc);

		// bmc._rotation = Seed.randVfx() * 360 ;

		for (a in Game.me.army) {
			if (a != this && a.mc._bBox.hitTestBbox(weaponInfos.target._bBox))
				a.explose();
		}

		var p:Array<pixi.core.math.Point> = [];
		for (pt in Game.me.mcGroup.groupPolygon) {
			p.push(Game.me.mcGroup.toGlobal(pt));
		}
		if (!Game.me.fever && weaponInfos.target._bBox.hitTestPolygon(p)) {
			for (tf in Game.me.followers) {
				for (i in 0...tf.length) {
					var f = tf[i];
					if (f != null && f.mc._bBox.hitTestBbox(weaponInfos.target._bBox)) {
						Game.me.killFollower(f);
						if (f != Game.me.leader) {
							tf[i] = null;
							Game.me.updateMcGroupPolygon();
						}
					}
				}
			}
		}

		weaponInfos.bomb.removeMovieClip();
		weaponInfos.target.removeMovieClip();
		weaponInfos.target = null;

		if (Game.me.lifeLeader <= 0 || Game.me.lifeFollowers <= 0)
			Game.me.setGameOver();
	}

	function getWeaponPoint():{x:Float, y:Float} {
		var s = {x: null, y: null};
		if (mc == null || mc._p._weapon == null)
			return s;
		switch (typeDir) {
			case 0:
				s.x = mc._x + mc._p._y + mc._p._weapon._y;
				s.y = mc._y - mc._p._x - mc._p._weapon._x;
			case 1:
				s.x = mc._x + mc._p._x + mc._p._weapon._x;
				s.y = mc._y + mc._p._y + mc._p._weapon._y;
			case 2:
				s.x = mc._x - mc._p._y - mc._p._weapon._y;
				s.y = mc._y + mc._p._x + mc._p._weapon._x;
			case 3:
				s.x = mc._x - mc._p._x - mc._p._weapon._x;
				s.y = mc._y - mc._p._y - mc._p._weapon._y;
		}

		return s;
	}

	function getWeaponMuzzlePoint():{x:Float, y:Float} {
		var p = mc._p._weapon.toGlobal(new pixi.core.math.Point(Cs.s(WEAPON_MUZZLE_X), 0));
		return {x: Num.q(p.x), y: Num.q(p.y)};
	}

	function initWeaponTarget() {
		if (mc == null) {
			return;
		}
		var b = getWeaponMuzzlePoint();
		var s = getWeaponPoint();
		if (s.x == null || s.y == null) {
			initWeapon(true);
			weaponTimer = 100;
			weaponStep = 0;
			return;
		}
		var sx = Num.q(s.x);
		var sy = Num.q(s.y);
		var tx = Num.q(b.x);
		var ty = Num.q(b.y);
		var dx = Num.q(tx - sx);
		var dy = Num.q(ty - sy);
		var px = Num.q(-dy);
		var py = Num.q(dx);
		var tt:{x:Float, y:Float} = null;
		var fallback:{x:Float, y:Float} = null;
		var maxTries = 10;
		for (i in 0...maxTries) {
			var range = Num.q(WEAPON_RANGE.min + Seed.rand() * (WEAPON_RANGE.max - WEAPON_RANGE.min));
			var spread = Num.q((Seed.rand() * 2 - 1) * WEAPON_TARGET_SPREAD);
			var candidate = {x: Num.q(sx + dx * range + px * spread), y: Num.q(sy + dy * range + py * spread)};
			fallback = candidate;
			if (tt == null && !Cs.outOfBounds(candidate.x, candidate.y, 20))
				tt = candidate;
		}
		if (tt == null && fallback != null) {
			var margin = Cs.s(15);
			tt = {
				x: Num.q(Math.max(Cs.mcw[0] + margin, Math.min(Cs.mcw[1] - margin, fallback.x))),
				y: Num.q(Math.max(Cs.mch[0] + margin, Math.min(Cs.mch[1] - margin, fallback.y)))
			};
		}

		if (tt == null || Cs.outOfBounds(tt.x, tt.y, 15)) {
			initWeapon(true);
			weaponTimer = 100;
			weaponStep = 0;
			return;
		}

		var mcTarget = Game.me.mdm.attach("target", Game.DP_TARGET);
		mcTarget._x = tt.x;
		mcTarget._y = tt.y;

		// trace("put target : " + tt.x + ", " + tt.y + " # by " + Std.string(this)) ;

		weaponInfos.target = cast mcTarget;
		weaponInfos.target._bBox = weaponInfos.target.attachBBox(new BBox(Cs.s(-20), Cs.s(-20), Cs.s(40), Cs.s(40)));
		weaponInfos.target._field = mcTarget.initTextField("targetField", {
			font: 'Arial',
			size: 36,
			align: 'center',
			color: 0xF2D604,
		});
		weaponInfos.target._field.x = Cs.s(0);
		weaponInfos.target._field.y = Cs.s(-7.5);
		weaponInfos.target._field.text = "3";
	}

	function checkBlock(mod) {
		if (blocked == null)
			return false;

		if (blocked.by.mc != null && hit(this, blocked.by, mod, blocked.nb) != null) {
			blocked.nb++;

			if (blocked.nb > MAX_BLOCK)
				setStep(Explode);
			moved = true;
			return true;
		} else {
			unblock();
			return false;
		}
	}

	public function move(mod:Float) {
		if (mc == null)
			return;
		if (mc.travelDone()) {
			if (weaponInfos != null && weaponInfos.target != null) {
				// trace("block in fire : " + Std.string(this) + " # "+ speed) ;
				return;
			}
			kill();
			return;
		}
		var delta = [dir[0] * mod * speed * SPEED_MULT, dir[1] * mod * speed * SPEED_MULT];

		x += delta[0];
		y += delta[1];

		var b = getBlockers(this);
		if (b.length > 0) {
			for (a in b) {
				if ((a.blocked == null || a.blocked.by != this)) {
					var h = hit(this, a, mod);
					if (h == null)
						continue;
					if (h == this) {
						block(a);
					} else {
						if (a.blocked == null) {
							a.block(this);
						}
					}
				}
			}
		}

		moved = true;
		if (blocked != null)
			return;

		// if (level == 0 || level == 3)
		mc.makeTraces();

		mc._x = x;
		mc._y = y;
	}

	public function block(?by:Army) {
		if (by != null)
			blocked = {nb: 1, by: by};
		// trace("paf : " + Std.string(this)) ;
		if (mc._p._currentframe == 1 && speed > 0.30)
			mc._p.gotoAndPlay("_brake");
		speed = 0.0;
		subStep = 0;
		timer = 0;
	}

	public function unblock() {
		blocked = null;
		setStep(Move);
		// BOTH LINES COMMENTED BECAUSE BLOCKED SET TO NULL
		// if (blocked.by.typeDir == typeDir)
		// 	speed -= 0.02;
	}

	function setStep(s:MoveStep) {
		if (step != s) {
			subStep = 0;
			timer = 0;
		}
		step = s;
	}

	function beginTravel(?delta:Float = 0.0):Bool {
		delta = Cs.s(delta);
		switch (typeDir) {
			case 0: // from north
				return y < Cs.mch[0] + delta;
			case 1: // from east
				return x > Cs.mcw[1] - delta;
			case 2: // from south
				return y > Cs.mch[1] - delta;
			case 3: // from west
				return x < Cs.mcw[0] + delta;
			case _:
				return true;
		}
	}

	function toString() {
		return "#" + typeDir + " - " + level + " -- " + x + ", " + y + " -- " + step + ", " + subStep;
	}

	public function kill() {
		var vv = null;

		if (place != null && place.l != null && place.l.length > 1) {
			place.l.remove(this);
		} else {
			vv = getPlaceTab(typeDir);
			var index = null;
			for (i in 0...vv.length) {
				if (vv[i] != place)
					continue;
				index = i;
				break;
			}

			if (index == null) {
				// trace("place index not found for kill wtf") ;
			} else {
				var done = false;
				var pi = place;
				while (!done) {
					var prev = vv[index - 1];
					var next = vv[index + 1];

					if (prev == null && next == null) {
						done = true;
						continue;
					}

					var neighbour = null;
					if (index == 0) {
						neighbour = next;
						done = true;
					} else if (index == vv.length - 1) {
						neighbour = prev;
						done = true;
					} else {
						if (prev.l == null && next.l != null)
							neighbour = prev;
						else if (prev.l != null && next.l == null)
							neighbour = next;
						else
							neighbour = if (Seed.random(2) == 0) next else prev;
					}

					if (neighbour.l == null) {
						if (neighbour == prev) {
							index = index - 1;
							neighbour.t[1] = pi.t[1];
						} else
							neighbour.t[0] = pi.t[0];
						vv.remove(pi);
						pi = neighbour;
					} else {
						done = true;
						place.l = null;
					}
				}
			}
		}

		if (mc != null) {
			mc.kill();
		}
		mc = null;
		if (warning != null)
			warning.removeMovieClip();
		if (weaponInfos != null) {
			if (weaponInfos.target != null)
				weaponInfos.target.removeMovieClip();
			if (weaponInfos.bomb != null)
				weaponInfos.bomb.removeMovieClip();
		}
		Game.me.army.remove(this);
	}

	static function findPlace(td:Int, m:Army):Float {
		var vv = getPlaceTab(td);
		var need = m.preHeight;

		var disps = [];
		var otherSideDisps = [];
		for (i in 0...vv.length) {
			var v = vv[i];
			if (v.t[1] - v.t[0] >= need) {
				if (v.l == null)
					disps.push({index: i, v: v});
				else {
					var a:Army = v.l[0];
					if (a.typeDir == td) {
						if (canBeAdded(m, v.l))
							disps.push({index: i, v: v});
					} else {
						if (canBeAdded(m, v.l, true))
							otherSideDisps.push({index: i, v: v});
					}
				}
			}
		}

		if (disps.length == 0) {
			if (otherSideDisps.length == 0) {
				// trace("no place wtf for " + Std.string(m)) ;
				return null;
			} else {
				disps = otherSideDisps;
				td = (td + 2) % 4;
				m.typeDir = td;
			}
		}

		var d = disps[Seed.random(disps.length)];
		var res = d.v.t[0] + Seed.random(Std.int((d.v.t[1] - d.v.t[0]) - need));

		if (d.v.l != null) {
			d.v.l.push(m);
			m.place = d.v;
		} else {
			var vMid = null;
			var vEnd = null;

			var minSize = Cs.s(8.0);
			var oldEnd = d.v.t[1];
			if (res - d.v.t[0] < minSize) {
				d.v.t[1] = res + need;
				d.v.l = [m];
				vMid = {l: null, t: [res + need, oldEnd]};
				vv.insert(d.index + 1, vMid);
				m.place = d.v;
			} else {
				d.v.t[1] = res;
				vMid = {l: [m], t: [res, res + need]};
				if (oldEnd - (res + need) < minSize)
					vMid.t[1] = oldEnd;
				else
					vEnd = {l: null, t: [res + need, oldEnd]};

				vv.insert(d.index + 1, vMid);
				if (vEnd != null)
					vv.insert(d.index + 2, vEnd);
				m.place = vMid;
			}
		}

		return res;
	}

	public static function canBeAdded(m:Army, l:Array<Army>, ?otherSide = false):Bool {
		if (l == null)
			return true;

		var d = if (!otherSide) m.typeDir else ((m.typeDir + 2) % 4);

		for (a in l) {
			if (a.speed < m.speed) // speed
				return false;
			switch (d) { // place
				case 0:
					if (a.y - a.preHeight - Cs.MIN_DELTA_QUEUE < m.getStart())
						return false;
				case 1:
					if (a.x + a.preWidth + Cs.MIN_DELTA_QUEUE > m.getStart())
						return false;
				case 2:
					if (a.y + a.preHeight + Cs.MIN_DELTA_QUEUE > m.getStart())
						return false;
				case 3:
					if (a.x - a.preWidth - Cs.MIN_DELTA_QUEUE < m.getStart())
						return false;
			}
		}
		return true;
	}

	static public function getBlockers(m:Army):Array<Army> {
		var res = new Array();
		if (m.place.l != null) {
			for (a in m.place.l) {
				if (a == m)
					break;
				res.push(a);
			}
		}

		var vv = getPlaceTab(m.typeDir, true);
		var front = if (m.typeDir == 0 || m.typeDir == 2) m.y else m.x;
		var cut = false;
		var delta = 0;
		for (v in vv) {
			if (front >= v.t[0] - delta && front < v.t[1] + delta) {
				if (v.l != null) {
					cut = true;
					res = res.concat(v.l);
				} else {
					// if (v.t[1] - v.t[0] > 15)
					cut = true;
				}
			}

			if (cut)
				break;
		}

		return res;
	}

	public function getCenter():{x:Float, y:Float} {
		return mc.getCenter();
	}

	public function getMoveBox(?mod:Float = 0.0):Rectangle {
		if (mc == null)
			return null;
		var w = mc._bBoxMove.bboxWidth;
		var h = mc._bBoxMove.bboxHeight;
		if (typeDir == 0 || typeDir == 2) {
			var t = w;
			w = h;
			h = t;
		}

		var m = if (moved || blocked != null) [0.0, 0.0] else [
			Num.q(dir[0] * mod * speed * SPEED_MULT),
			Num.q(dir[1] * mod * speed * SPEED_MULT)
		];
		w = Num.q(w);
		h = Num.q(h);

		switch (typeDir) {
			case 0:
				return new Rectangle(Num.q(mc._bBoxMove.bboxY + x + m[0]), Num.q(-mc._bBoxMove.bboxX + y + m[1] - h), w, h);
			case 1:
				return new Rectangle(Num.q(mc._bBoxMove.bboxX + x + m[0]), Num.q(mc._bBoxMove.bboxY + y + m[1]), w, h);
			case 2:
				return new Rectangle(Num.q(-mc._bBoxMove.bboxY + x + m[0] - w), Num.q(mc._bBoxMove.bboxX + y + m[1]), w, h);
			case 3:
				return new Rectangle(Num.q(-mc._bBoxMove.bboxX + x + m[0] - w), Num.q(-mc._bBoxMove.bboxY + y + m[1] - h), w, h);
			case _:
				trace("bad dir for moveBox");
				return null;
		}
	}

	// return null if no hit, army object to stop otherwise
	public static function hit(a:Army, b:Army, mod:Float, ?nb:Int = 0):Army {
		var ar = a.getMoveBox(mod);
		var br = b.getMoveBox(mod);

		if (ar == null || br == null)
			return null;

		var ax = Num.q(ar.x);
		var ay = Num.q(ar.y);
		var aw = Num.q(ar.width);
		var ah = Num.q(ar.height);
		var bx = Num.q(br.x);
		var by = Num.q(br.y);
		var bw = Num.q(br.width);
		var bh = Num.q(br.height);
		var left = Num.q(Math.max(ax, bx));
		var right = Num.q(Math.min(ax + aw, bx + bw));
		var top = Num.q(Math.max(ay, by));
		var bottom = Num.q(Math.min(ay + ah, by + bh));
		if (left >= right || top >= bottom)
			return null;
		var interWidth = Num.q(right - left);
		var interHeight = Num.q(bottom - top);

		// trace("hit found betWeen " + Std.string(a) + " [" + Std.string(ar) + "] " + " and" + Std.string(b) + " [" + Std.string(br) + "] "  + " ==> " + Std.string(inter)) ;

		var minInter = Num.q(Cs.s(2.0));
		var minInterOut = Num.q(Cs.s(2.0));

		if (a.typeDir == b.typeDir)
			return if (a.creationTime <= b.creationTime) b else a;
		else {
			var wArmy = if (a.typeDir == 0 || a.typeDir == 2) a else b;
			var hArmy = if (wArmy == a) b else a;
			if (interWidth > interHeight) {
				if (interWidth > minInter) {
					if (interHeight < minInterOut && isGoingAway(hArmy, wArmy))
						return null;
					else
						return wArmy;
				} else
					return null;
			} else if (interWidth < interHeight) {
				if (interHeight > minInter) {
					if (interWidth < minInterOut && isGoingAway(wArmy, hArmy))
						return null;
					else
						return hArmy;
				} else
					return null;
			} else {
				if (interWidth > minInter)
					return if (a.speed >= b.speed) a else b;
				else
					return null;
			}
		}
	}

	static function isGoingAway(a:Army, b:Army):Bool {
		var res = false;
		var ax = Num.q(a.x);
		var ay = Num.q(a.y);
		var bx = Num.q(b.x);
		var by = Num.q(b.y);
		switch (a.typeDir) {
			case 0:
				if (b.typeDir == 1)
					res = bx < ax;
				else if (b.typeDir == 3)
					res = bx > ax;
			case 1:
				if (b.typeDir == 0)
					res = by > ay;
				else if (b.typeDir == 2)
					res = by < ay;
			case 2:
				if (b.typeDir == 1)
					res = bx < ax;
				else if (b.typeDir == 3)
					res = bx > ax;
			case 3:
				if (b.typeDir == 0)
					res = by > ay;
				else if (b.typeDir == 2)
					res = by < ay;
		}

		return res;
	}

	static public function getPlaceTab(dir:Int, ?otherOne = false) {
		if (otherOne)
			return PLACES[if (dir == 0 || dir == 2) 1 else 0];
		else
			return PLACES[if (dir == 0 || dir == 2) 0 else 1];
	}

	// ########### FOR DEBUG ONLY
	// #######################

	static public function traceBoxes() {
		var mod = mt.Timer.tmod;
		// trace("trace boxes") ;
		for (a in Game.me.army) {
			var r = a.getMoveBox();
			var mc = Game.me.mdm.empty(Game.DP_TRACES);
			if (a.blocked != null)
				continue;

			mc.getGraphics()
				.beginFill(0xFFFFFF, 3)
				.moveTo(0, 0)
				.lineTo(r.width, 0)
				.lineTo(r.width, r.height)
				.lineTo(0, r.height)
				.lineTo(0, 0)
				.endFill();
			mc._x = r.x;
			mc._y = r.y;
			// trace(Std.string(a) + mc._x + ", "  +  mc._y) ;
			var p = new Phys(mc);
			p.fadeType = 6;
			p.timer = 28;
		}
	}
}
