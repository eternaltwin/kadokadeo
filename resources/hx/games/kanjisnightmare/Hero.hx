package kanjisnightmare;

import common_haxe_avm1.KeyboardManager;

// target of a shot or of a slash: a monster or the mouse pointer
typedef Target = {x:Float, y:Float, ?m:Monster};

class Hero extends Phys {
	public static inline var FLY = 0;
	public static inline var GROUND = 1;
	public static inline var DEATH = 2;
	public static inline var KICK = 3;

	public static inline var DL = 560;
	public static inline var CEIL = 30;
	public static inline var WEIGHT = 0.5;

	public static var SPEED:Float = 6;
	public static inline var JUMP_EXTEND = 3;
	public static inline var JUMP_START = 6;
	public static inline var GSPEED = 40;

	public static inline var GP_DIST = 30;
	public static inline var GP_POWER = 0.6;

	public static var FL_EXTRA_JUMP = false;

	public var plat:Plat;
	public var optList:Array<Bool>;

	var kunaiMax:Int;
	var kunaiLeft:Int;
	var auraTimer:Null<Float>;
	var starMax:Int;
	var starLeft:Int;

	public var hp:Int;

	var wframe:Float;
	var noColTimer:Null<Float>;
	var flShootReady:Bool;
	var flFlyUp:Bool;
	var flWalk:Bool;
	var flBall:Bool;

	public var flDeath:Bool;
	public var flEat:Bool;

	var flDownReady:Bool;
	var flExtraJumpReady:Bool;

	public var sens:Int;

	var pitch:Int;
	var extraJump:Int;
	var boost:Null<Float>;
	var checkGroundSafe:Null<Float>;
	var noControlTimer:Null<Float>;
	var cooldown:Float;

	public var gp:Grap;
	public var step:Int;

	var nextAnim:String;

	var auraColId:Int;
	var auraColSens:Int;
	var auraLoopTimer:Float;
	var auraCol:Array<Int>;

	var mcStarCount:Clip;
	var starField:Digits;
	var kList:Array<Clip>;
	var iconList:Array<Clip>;

	// position unit of the root: 1 in the map, the pixels of Medusa's head once eaten
	var posK:Float;

	var kickSnap:Clip;
	var kickRot:Float;
	var kickScale:Float;

	public function new(mc:ASprite) {
		super(mc);
		frict = 0.99;
		x = Cs.mcw * 0.5;
		y = Cs.mch * 0.5;
		posK = 1;

		flBall = false;
		flDeath = false;
		flEat = false;
		flShootReady = false;
		flFlyUp = false;
		flWalk = false;
		flDownReady = false;
		flExtraJumpReady = false;

		ray = 12;
		cooldown = 0;
		kunaiMax = 3;
		kunaiLeft = kunaiMax;
		hp = 1;
		pitch = 0;
		extraJump = 0;
		wframe = 0;
		auraLoopTimer = 0;

		starMax = 200;
		starLeft = 30;

		optList = [false, false, false, false, false];
		iconList = [];

		initStep(FLY);
		setSens(1);
		initInterface();
	}

	inline function clip():Clip {
		return cast root;
	}

	override public function updatePos() {
		if (root == null)
			return;
		root._x = x * posK;
		root._y = y * posK;
		if (!placed) {
			placed = true;
			root.updateState();
		}
	}

	public function initStep(n:Int) {
		step = n;
		switch (step) {
			case FLY:
				if (vy < 0) {
					nextAnim = "fly_up";
					flFlyUp = true;
				} else {
					nextAnim = "fly_down";
					flFlyUp = false;
				}
				weight = WEIGHT;
				flBall = false;
			case GROUND:
				fillKunai();
				vx = 0;
				vy = 0;
				weight = 0;
				if (nextAnim == null)
					nextAnim = "land";
				if (gp != null)
					releaseGrap();
				flWalk = false;
			case DEATH:
				weight = WEIGHT;
				flDeath = true;
				Cs.game.gameOver();
				nextAnim = "death";
		}
	}

	override public function update() {
		super.update();
		// CHECK CEIL
		if (y < CEIL) {
			y = CEIL;
			vy *= 0.5;
		}
		if (flDeath)
			return;
		if (step != KICK)
			root._rotation = 0;

		updateNoCol();

		// CONTROL
		if (!flEat)
			control();

		// BOOST
		if (boost != null) {
			boost *= Math.pow(0.7, Timer.tmod);
			if (boost < 0.1)
				boost = null;
		}

		// CHECK
		checkDeath();
		checkBonus();

		// AURA
		if (auraTimer != null)
			updateAura();

		switch (step) {
			case FLY:
				// CHECK DEATH
				if (y > DL) {
					flDeath = true;
					Cs.game.gameOver();
					releaseGrap();
					nextAnim = "fly_down";
				}

				// GP
				if (gp != null) {
					if (!gp.flFly) {
						var dist = getDist(gp);
						var a = getAng(gp);
						if (dist > GP_DIST) {
							var c = (dist - GP_DIST) / GP_DIST;
							vx = Cs.q(vx + Math.cos(a) * c * GP_POWER * 1.5);
							vy = Cs.q(vy + Math.sin(a) * c * GP_POWER);
						}
						Cs.game.drawRope(x, y - 15, gp.x, gp.y);

						// ROPE ARM
						var dx = gp.x - x;
						var dy = gp.y - y;
						var angle = Math.atan2(dy, dx * sens);
						root._rotation = vx * 0.5;
						var r = Cs.normRot(root._rotation);
						var mc = clip();
						mc.setOverride("arm", angle / 0.0174 - r, null, null);
						var lim = 30;
						mc.setOverride("head", Cs.mm(-lim, vy, lim), null, null);
						lim = 50;
						mc.setOverride("leg0", Cs.mm(-lim, vx * 4 * sens, lim), null, null);
						mc.setOverride("leg1", Cs.mm(-lim, vx * 4 * sens, lim), null, null);
					}
				}

				// PLAT
				checkPlatCol();

				if (flFlyUp && vy > 0) {
					if (nextAnim == null)
						nextAnim = "fly_down";
					flFlyUp = false;
				}

			case GROUND:
				if (x < plat.x || x > plat.x + plat.w) {
					initStep(FLY);
					vy = -2;
					plat = null;
				}
			case KICK:
				checkPlatCol();
				updateKick();
		}

		// RECAL
		if (x < 13 - Cs.game.scrollMin)
			x = 13 - Cs.game.scrollMin;

		// ANIM
		if (nextAnim != null) {
			root.gotoAndPlay(nextAnim);
			nextAnim = null;
		}
	}

	function control() {
		// COOLDOWN
		if (cooldown > 0)
			cooldown -= Timer.tmod;

		if (noControlTimer != null) {
			noControlTimer -= Timer.tmod;
			if (noControlTimer < 0)
				noControlTimer = null;
			return;
		}

		// PITCH
		pitch = 0;
		if (KeyboardManager.isDown(KeyboardManager.LEFT))
			pitch = -1;
		if (KeyboardManager.isDown(KeyboardManager.RIGHT))
			pitch = 1;
		if (pitch != 0 && pitch != sens && step != KICK)
			setSens(pitch);

		var flDown = false;
		if (KeyboardManager.isDown(KeyboardManager.DOWN)) {
			if (flDownReady)
				flDown = true;
		} else {
			flDownReady = true;
		}

		switch (step) {
			case FLY:
				if (!flBall) {
					var dvx = SPEED * pitch - vx;
					var lim = 0.5;
					var coef = 0.1;
					vx += Math.min(Math.max(-lim, dvx * coef), lim);
				}
				if (KeyboardManager.isDown(KeyboardManager.UP)) {
					if (flExtraJumpReady) {
						if (extraJump > 0) {
							jump();
							vx = SPEED * pitch;
							flBall = true;
							nextAnim = "ball";
							extraJump--;
						} else {
							rope();
						}
						flExtraJumpReady = false;
					} else {
						if (boost != null)
							vy -= JUMP_EXTEND * boost * Timer.tmod;
					}
				} else {
					flExtraJumpReady = true;
				}
				if (flDown) {
					if (gp != null) {
						rope();
					} else {
						kick();
					}
				}

			case GROUND:
				if (pitch != 0) {
					if (sens != pitch)
						setSens(pitch);
					vx = SPEED * pitch;
					if (!flWalk) {
						nextAnim = "walk";
						wframe = 0;
						flWalk = true;
					}
				} else {
					vx = 0;
					if (flWalk) {
						nextAnim = "wait";
						flWalk = false;
					}
				}
				if (flWalk) {
					wframe = (wframe + (SPEED / 7) * Timer.tmod) % 11;
					nextAnim = Std.string(128 + Std.int(wframe));
				}
				if (KeyboardManager.isDown(KeyboardManager.UP)) {
					if (FL_EXTRA_JUMP)
						extraJump = 1;
					jump();
				}
				if (flDown) {
					jump();
					vy = -2.5;
					boost = 0;
					checkGroundSafe = 16;
				}
			default:
		}

		// TIR
		if (KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(KeyboardManager.CONTROL)) {
			if (flShootReady && cooldown <= 0)
				shoot();
			flShootReady = false;
		} else {
			flShootReady = true;
		}
	}

	function updateNoCol() {
		if (noColTimer == null)
			return;
		noColTimer -= Timer.tmod;
		var prc = 50 + Math.cos(((noColTimer * 100) % 628) * 0.01) * 50;
		if (noColTimer < 0) {
			noColTimer = null;
			prc = 0;
		}
		Cs.setPercentColor(root, prc, 0xFFFFFF);
	}

	function checkDeath() {
		for (m in Cs.game.mList) {
			var dist = getDist(m);
			if (m.flCol && dist < 26) {
				if (auraTimer != null) {
					m.knockOut();
					m.vx = vx * 2;
					m.vy = -(7 + Seed.rand() * 4);
					m.flCol = false;
					Cs.game.genScore(m.x, m.y, Cs.C200);
					return;
				}
				if (!m.flSpike) {
					if (vy > 0) {
						vy = -7;
						y = m.y - 20;
						m.harm(21, false);
						fillKunai();
						if (step == KICK) {
							vx *= 0.4;
							step = FLY;
							nextAnim = "fly_up";
							setSens(Std.int(vx / Math.abs(vx)));
						}
						return;
					}
				}
				if (noColTimer == null && dist < 18)
					harm();
			}
		}
	}

	function checkBonus() {
		var i = 0;
		while (i < Cs.game.bonusList.length) {
			var sp = Cs.game.bonusList[i];
			if (getDist(sp) < 20) {
				sp.take();
				i--;
			}
			i++;
		}
	}

	override public function checkPlatCol() {
		if (checkGroundSafe != null) {
			checkGroundSafe -= Timer.tmod;
			if (checkGroundSafe < 0)
				checkGroundSafe = null;
			return;
		}
		super.checkPlatCol();
	}

	override public function land(pl:Plat) {
		initStep(GROUND);
		plat = pl;
		for (i in 0...3) {
			var p = Cs.game.newPart("partDust");
			p.x = x + (Seed.randVfx() * 2 - 1) * 14;
			p.y = y + 12 + Seed.randVfx() * 24;
			p.weight = 0.1 + Seed.randVfx() * 0.3;
			p.setScale(50 + Seed.randVfx() * 70);
			p.timer = 20 + Seed.randVfx() * 10;
		}
	}

	function jump() {
		boost = 1;
		vy = -JUMP_START;
		flExtraJumpReady = false;
		initStep(FLY);
		nextAnim = "fly_up";
	}

	function rope() {
		if (gp != null) {
			releaseGrap();
			if (vy < 0)
				nextAnim = "ball";
		} else {
			if (kunaiLeft > 0) {
				kunaiLeft--;
				var a = -1.57 + pitch * 0.7;
				gp = new Grap(Clip.attach(Cs.game.mdm, "mcKunai", Game.DP_HERO));
				gp.x = x;
				gp.y = y;
				gp.vx = Cs.q(Math.cos(a) + (vx * 0.05));
				gp.vy = Cs.q(Math.sin(a));
				gp.speed = GSPEED;
				gp.flFly = true;
				gp.orient();
				Cs.game.stats.gu += 1;
			}
			updateInterface();
		}
	}

	public function grap() {
		nextAnim = "rope";
	}

	function shoot() {
		var o = getNextMonster();
		var speed = 16;
		var a = sens * 1.57 - 1.57;
		if (o != null) {
			var trg = {x: o.t.x, y: o.t.y};
			if (o.t.m != null) {
				var d = getDist(trg);
				var coef = d / speed;
				trg.x += o.t.m.vx * coef;
				trg.y += o.t.m.vy * coef;
			}
			a = getAng(trg);
		}

		var dsLim = 60;
		if (o != null && step == GROUND && o.dist < dsLim) {
			var list = getMonsterList();
			var dx = o.t.x - x;
			var side = Math.abs(dx) / dx;
			for (o2 in list) {
				if ((o2.m.x - x) * side < 0 && o2.d < dsLim) {
					doubleStrike([o.t, {x: o2.m.x, y: o2.m.y, m: o2.m}]);
					return;
				}
			}
		}

		var flNear = o != null && o.dist < (optList[0] ? 76 : 52);
		if (flNear || starLeft == 0) {
			slash(o == null ? null : o.t, flNear);
			return;
		}

		incStar(-1);
		updateInterfaceField();
		var shot = new Star(Clip.attach(Cs.game.mdm, "mcNinjaShot", Game.DP_SHOT));
		shot.x = x;
		shot.y = y;
		shot.vx = Cs.q(Math.cos(a) * speed);
		shot.vy = Cs.q(Math.sin(a) * speed);
		if (optList[1]) {
			shot.damage *= 2;
			shot.root.gotoAndStop(2);
		} else {
			shot.root.stop();
		}
		shot.frict = 1;
		cooldown = 2;
	}

	function slash(trg:Target, flNear:Bool) {
		cooldown = 8;
		var bfx = clip().getClip("bfx");
		if (bfx != null) {
			bfx.gotoAndPlay(2);
			var blade = bfx.getClip("blade");
			if (blade != null)
				blade.gotoAndStop(optList[0] ? 2 : 1);
		}
		if (flNear) {
			if ((trg.x - x) * sens < 0)
				setSens(-sens);
			if (trg.m != null) {
				trg.m.cut(21);
				if (trg.m.hp > 0)
					vx = -5 * sens;
			}
		}
	}

	function kick() {
		if (optList[5] != true)
			return;
		flDownReady = false;
		var distMin = 9999.0;
		var mons:Monster = null;
		for (m in Cs.game.mList) {
			var dx = m.x - x;
			var dy = m.y - y;
			if (dy > 20 && dy < 220 && Math.abs(dx) < 80) {
				var dist = Math.abs(dx) + Math.abs(dy);
				if (dist < distMin) {
					mons = m;
					distMin = dist;
				}
			}
		}
		if (mons != null) {
			var sp = 16;
			var dy = mons.y - y;
			var c = dy / sp;
			var npx = mons.x + mons.vx * c;
			var dx = npx - x;
			vx = dx / c;
			vy = sp;
			step = KICK;
			root.gotoAndPlay("kick");
			nextAnim = "kick";
			setSens(1);
			// the kick follows the dive (the typed MTypes compiler reads the ternary as the operand of +)
			root._rotation = Math.atan2(vy, vx) / 0.0174 + (sens == -1 ? 180 : 0);
			// the afterimages of the kick all show the picture taken now
			kickSnap = clip().snapshot();
			kickRot = root._rotation;
			kickScale = root._xscale;
		}
	}

	function doubleStrike(a:Array<Target>) {
		for (t in a) {
			if (t.m != null)
				t.m.harm(100, false);
			nextAnim = "doubleStrike";
			root.gotoAndPlay("doubleStrike");
		}
		noControlTimer = 5;
		vx = 0;
		var mc = Clip.attach(Cs.game.mdm, "mcOnde", Game.DP_ROPE);
		var sp = Cs.game.registerMc(mc, x, y);
		mc.onRemoved = sp.kill;
		Cs.game.genScore(x, y - 25, Cs.C1000);
	}

	public function releaseGrap() {
		if (flFlyUp && vy > 0) {
			if (nextAnim == null)
				nextAnim = "fly_down";
			flFlyUp = false;
		}
		if (!flFlyUp && vy < 0) {
			if (nextAnim == null)
				nextAnim = "fly_up";
			flFlyUp = true;
		}
		if (gp != null)
			gp.drop();
		gp = null;
	}

	public function initAura() {
		auraTimer = 500;
		auraCol = [255, 0, 0];
		auraColId = 1;
		auraColSens = 1;
		auraLoopTimer = 0;
	}

	function updateAura() {
		auraTimer -= Timer.tmod;
		if (auraTimer < 0)
			auraTimer = null;
		if (auraTimer != null && auraTimer > 20) {
			if (auraLoopTimer > 0) {
				auraLoopTimer -= Timer.tmod;
				return;
			}
			// auracol
			auraCol[auraColId] = Std.int(Cs.mm(0, auraCol[auraColId] + auraColSens * 50, 255));
			if (auraCol[auraColId] == 255) {
				auraColId = Std.int(Cs.sMod(auraColId - 1, 2));
				auraColSens = -1;
			} else if (auraCol[auraColId] == 0) {
				auraColId = Std.int(Cs.sMod(auraColId + 2, 2));
				auraColSens = 1;
			}
			var col = Cs.objToCol({r: auraCol[0], g: auraCol[1], b: auraCol[2]});
			Cs.game.ghost(clip(), x, y, Cs.normRot(root._rotation), root._xscale, Game.DP_ROPE, 15, 10, col, 30, true);
		}
	}

	function updateKick() {
		setSens(1);
		if (kickSnap != null)
			Cs.game.ghost(kickSnap, x, y, kickRot, kickScale, Game.DP_MONS, 10, 6, 0xFF00FF, 100, false);
	}

	public function harm() {
		if (hp > 0) {
			hp--;
			releaseGrap();
			root.removeMovieClip();
			setRoot(Clip.attach(Cs.game.mdm, "mcHeroSlip", Game.DP_HERO), true);
			setSens(sens);
			Cs.game.slipGlow(root);
			noColTimer = 70;
			initStep(FLY);
			var i = 0;
			while (i < 50) {
				var p = Cs.game.newPart("mcCombi");
				p.x = x + (Seed.randVfx() * 2 - 1) * 4;
				p.y = y + 10 - i * 4;
				p.vx = vx * (1.2 + Seed.randVfx() * 0.8);
				p.vy = vy * (1.2 + Seed.randVfx() * 0.8) - (2 + Seed.randVfx() * 7);
				p.timer = 50 + Seed.randVfx() * 10;
				p.weight = 0.1 + Seed.randVfx() * 0.2;
				p.vr = (Seed.randVfx() * 2 - 1) * 6;
				p.root.gotoAndStop(i + 1);
				if (i + 1 == p.root._totalframes) {
					p.flPlatCol = true;
					p.ray = 10;
					p.vr *= 3;
					break;
				}
				i++;
			}
		} else {
			initStep(DEATH);
		}
		vy -= 5;
		vx -= 3;
	}

	public function hpUp() {
		hp = 1;
		var fr = clip().frame;
		root.removeMovieClip();
		setRoot(Clip.attach(Cs.game.mdm, "mcHero", Game.DP_HERO), true);
		root.gotoAndStop(fr);
		setSens(sens);
	}

	// swallowed by Medusa: the hero goes into her mouth (eatZone, masked by her lips), in the pixels of her head
	public function eaten(zone:ASprite, zx:Float, zy:Float, ppu:Float) {
		var link = hp == 0 ? "mcHeroSlip" : "mcHero";
		var fr = clip().frame;
		root.removeMovieClip();
		var mc = new Clip(link, ppu);
		zone.addChild(mc);
		mc.gotoAndPlay(fr);
		posK = ppu;
		x = zx;
		y = zy;
		setRoot(mc);
	}

	// INTERFACE
	function initInterface() {
		kList = [];
		mcStarCount = Clip.attach(Cs.game.dm, "mcStarCount", Game.DP_INTER);
		// the clip is in its texture pixels (pxPerUnit per Flash pixel)
		starField = new Digits(Data.DIGIT_STAR, mcStarCount.pxPerUnit());
		mcStarCount.addChild(starField);
		updateInterface();
	}

	function updateInterface() {
		for (i in 0...kunaiMax) {
			var mc = kList[i];
			if (mc == null) {
				mc = kList[i] = Clip.attach(Cs.game.dm, "mcInterKunai", Game.DP_INTER);
				mc._x = i * 12;
				mc._y = 0;
				mc.updateState();
			}
			mc.setOverride("smc", null, null, null, null, null, (kunaiLeft > i) ? 100 : 10);
		}
		mcStarCount._x = kunaiMax * 12 + 2;
		mcStarCount._y = 0;
		mcStarCount.updateState();
		updateInterfaceField();
	}

	function updateInterfaceField() {
		starField.setText(Std.string(starLeft));
	}

	public function updateIcons() {
		while (iconList.length > 0)
			iconList.pop().removeMovieClip();
		var x:Float = Cs.mcw;
		for (i in 0...optList.length) {
			if (optList[i]) {
				var mc = Clip.attach(Cs.game.dm, "mcIcon", Game.DP_INTER);
				mc.gotoAndStop(i + 1);
				mc._x = x;
				mc._y = 0;
				mc.updateState();
				x -= 20;
				iconList.push(mc);
			}
		}
	}

	function fillKunai() {
		kunaiLeft = kunaiMax;
		updateInterface();
	}

	public function incStar(n:Int) {
		starLeft = Std.int(Cs.mm(0, starLeft + n, starMax));
		updateInterfaceField();
	}

	public function incKunai(n:Int) {
		kunaiMax += n;
		fillKunai();
	}

	public function setSens(n:Int) {
		sens = n;
		root._xscale = n * 100;
		// no interpolation of the flip
		if (root._prevState != null)
			root._prevState.xscale = root._curState.xscale;
	}

	function getNextMonster():{t:Target, dist:Float} {
		var distMin = 250.0;
		var mons:Monster = null;
		for (m in Cs.game.mList) {
			var d = Math.abs(m.x - x) + Math.abs(m.y - y);
			if (d < distMin) {
				distMin = d;
				mons = m;
			}
		}
		if (mons != null)
			return {t: {x: mons.x, y: mons.y, m: mons}, dist: distMin};

		var g = Cs.game;
		if (!g.flMouseDead && g.mouseActive()) {
			var mp = {x: g.mouseMapX() + 7, y: g.mouseMapY() + 7};
			var dist = getDist(mp);
			if (dist < 140 && dist > 50)
				return {t: mp, dist: dist};
		}
		return null;
	}

	function getMonsterList():Array<{d:Float, m:Monster}> {
		var list:Array<{d:Float, m:Monster}> = [];
		for (m in Cs.game.mList) {
			var d = Math.abs(m.x - x) + Math.abs(m.y - y);
			var n = 0;
			while (n < list.length) {
				if (list[n].d > d)
					break;
				n++;
			}
			list.insert(n, {m: m, d: d});
		}
		return list;
	}
}
