package kanjisnightmare;

import mt.bumdum.Lib;
import pixi.core.renderers.webgl.filters.Filter;
import common_haxe_avm1.KeyboardManager;
import kado.KadoKadeoManager;
import mt.Timer;
import pixi.core.graphics.Graphics;
import pixi.core.math.Matrix;
import pixi.core.text.Text;
import pixi.core.textures.RenderTexture;

class StarCountSprite extends ASprite {
	public var field:Text;
}

class HeroSprite extends ASprite {
	public var kunai:ASprite;
	public var bfx1:ASprite;
	public var bfx2:ASprite;
	public var hero:ASprite;
}

class Hero extends Phys {
	public inline static var FLY = 0;
	public inline static var GROUND = 1;
	public inline static var DEATH = 2;
	public inline static var KICK = 3;

	public static var DL = Cs.S(560);
	static var CEIL = Cs.S(30);
	static var WEIGHT = Cs.S(0.5);

	public static var SPEED:Float = Cs.S(6);
	static var JUMP_EXTEND = Cs.S(3);
	static var JUMP_START = Cs.S(6);
	static var GSPEED = Std.int(Cs.S(40)); // 30;

	static var GP_DIST = Cs.S(30);
	static var GP_POWER = Cs.S(0.6);

	static var FL_MOUSE_CONTROL = false;
	static var FL_EXTRA_JUMP = false;

	public var plat:Plat;
	public var optList:Array<Bool>;
	public var rootSprite:HeroSprite;

	var kunaiMax:Int;
	var kunaiLeft:Int;

	var auraTimer:Float;

	var starMax:Int;
	var starLeft:Int;

	public var hp:Int;

	var wframe:Float;
	var noColTimer:Float;
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
	var boost:Float;
	var checkGroundSafe:Float;
	var noControlTimer:Float;

	var cooldown:Float;

	var gp:Grap;
	var step:Int;

	public var nextAnim:String;
	public var animFrame:Map<String, Int> = new Map();

	var kickBmp:RenderTexture;

	var auraColId:Int;
	var auraColSens:Int;
	var auraLoopTimer:Float;
	var auraCol:Array<Int>;

	var mcStarCount:StarCountSprite;
	var kList:Array<ASprite>;
	var iconList:Array<ASprite>;

	public function new(mc) {
		super(mc);

		frict = 0.99;
		x = Cs.mcw * 0.5;
		y = Cs.mch * 0.5;

		flBall = false;
		flDeath = false;
		flEat = false;

		ray = Cs.S(12);
		cooldown = 0;
		kunaiMax = 3;
		kunaiLeft = kunaiMax;
		hp = 1;

		starMax = 200;
		starLeft = 30;

		// optList = [true, true, true, true, true];
		optList = [false, false, false, false, false];
		iconList = [];

		initStep(FLY);
		setSens(1);

		initInterface();
		rootSprite = cast mc;
		rootSprite.hero = mc.attachMovie("mcHero", "hero");
		setupAnims(rootSprite.hero);
		// mc.getGraphics().beginFill(0x0000FF, 0.5).drawRect(-30, -30, 60, 60);
		animFrame.set("wait", 1);
		animFrame.set("run", 29);
		animFrame.set("run_loop", 33);
		animFrame.set("fly_up", 60);
		animFrame.set("fly_down", 71);
		animFrame.set("fall", 76);
		animFrame.set("land", 92);
		animFrame.set("death", 104);
		animFrame.set("ball", 105);
		animFrame.set("walk", 116);
		animFrame.set("walk_loop", 117);
		animFrame.set("tronc", 128);
		animFrame.set("rope", 129);
		animFrame.set("kick", 138);
		animFrame.set("doubleStrike", 144);
		rootSprite.bfx1 = rootSprite.attachMovie("heroBfx1", "bfx1");
		rootSprite.bfx2 = rootSprite.attachMovie("heroBfx2", "bfx2");
	}

	public function setupAnims(sp:ASprite) {
		sp.stopOnFrame = [70, 91, 104, 128];
		sp.onFrame.set(26, () -> sp.gotoAndPlay(1));
		sp.onFrame.set(36, () -> sp.gotoAndPlay(33));
		sp.onFrame.set(103, () -> sp.gotoAndPlay(1));
		sp.onFrame.set(115, () -> sp.gotoAndPlay(106));
		sp.onFrame.set(127, () -> sp.gotoAndPlay(117));
		sp.onFrame.set(137, () -> sp.gotoAndPlay(129));
		sp.onFrame.set(143, () -> sp.gotoAndPlay(138));
		sp.onFrame.set(154, () -> sp.gotoAndPlay(1));
	}

	public function initStep(n) {
		if (step == n)
			return;
		step = n;
		switch (step) {
			case FLY:
				if (rootSprite != null) {
					rootSprite.hero._rotation = 0;
				}
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
				if (rootSprite != null) {
					rootSprite.hero._rotation = 0;
				}
				fillKunai();
				vx = 0;
				vy = 0;
				weight = 0;
				if (nextAnim == null)
					nextAnim = "land";
				if (gp != null) {
					releaseGrap();
				}
				flWalk = false;

			case DEATH:
				weight = WEIGHT;
				flDeath = true;
				KadoKadeoManager.kkm.gameOver(Cs.game.stats);
				nextAnim = "death";
		}
	}

	public override function update() {
		// updateKick()

		super.update();
		// CHECK CEIL
		if (Num.q(y) < CEIL) {
			y = CEIL;
			vy *= 0.5;
		}
		//
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
				// DEATH CUT
				if (flDeath)
					return;

				// CHECK DEATH
				if (Num.q(y) > DL) {
					initStep(DEATH);
					releaseGrap();
					nextAnim = null;
				}

				// GP
				if (gp != null) {
					if (!gp.flFly) {
						var dist = getDeterministicDist(gp.x, gp.y);
						var a = getAng({x: gp.x, y: gp.y});
						if (dist > GP_DIST) {
							var c = (dist - GP_DIST) / GP_DIST;

							vx += Math.cos(a) * c * GP_POWER * 1.5;
							vy += Math.sin(a) * c * GP_POWER;
						}
						var st = [[4, 0x7E2301], [2, 0xFEAA8B]];
						for (i in 0...2) {
							Cs.game.mcLine.lineStyle(Cs.S(st[i][0]), st[i][1], 100);
							Cs.game.mcLine.moveTo(x, y - Cs.S(15)); // traceLine();
							Cs.game.mcLine.lineTo(gp.x, gp.y); // traceLine();
						}
						// root._rotation = (a/0.0174 + 90 )*0.3;

						// ROPE ARM
						var dx = gp.x - x;
						var dy = gp.y - y;
						var angle = Math.atan2(dy, dx * sens);

						root._rotation = (vx / Cs.NEW_GEN_SCALE) * 0.5;

						// var mc:Dynamic = cast root;

						// FIXME: following lines are to be uncommented
						// mc.arm._rotation = angle / 0.0174 - root._rotation;
						// var lim = 30;
						// mc.head._rotation = Num.mm(-lim, vy, lim);
						// lim = 50;
						// mc.leg0._rotation = Num.mm(-lim, vx * 4 * sens, lim);
						// mc.leg1._rotation = Num.mm(-lim, vx * 4 * sens, lim);
					}
				}

				// PLAT
				checkPlatCol();

				// Log.print(flFlyUp);
				if (flFlyUp && vy > 0) {
					if (nextAnim == null)
						nextAnim = "fly_down";
					flFlyUp = false;
				}

			case GROUND:
				var px = Num.q(x);
				if (px < Num.q(plat.x) || px > Num.q(plat.x + plat.w)) {
					initStep(FLY);
					vy = Cs.S(-2);
					plat = null;
				}

			case KICK:
				checkPlatCol();
				updateKick();
		}

		// RECAL
		if (Num.q(x) < Num.q(Cs.S(13) - Cs.game.scrollMin)) {
			x = Cs.S(13) - Cs.game.scrollMin;
		}
		// ANIM
		if (nextAnim != null) {
			if (animFrame.exists(nextAnim)) {
				var anim = animFrame.get(nextAnim);
				rootSprite.hero.gotoAndPlay(anim);
				if (nextAnim == "death") {
					rootSprite.hero.gotoAndStop(anim);
					vr = 2;
				}
			} else {
				rootSprite.hero.gotoAndPlay(Std.parseInt(nextAnim));
			}
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
		if (isLeftDown())
			pitch = -1;
		if (isRightDown())
			pitch = 1;
		// if(noControlTimer!=null) pitch = 0;
		if (pitch != 0 && pitch != sens && step != KICK)
			setSens(pitch);

		var flDown = false;
		if (isDownDown()) {
			if (flDownReady) {
				flDown = true;
			}
		} else {
			flDownReady = true;
		}

		switch (step) {
			case FLY:
				if (!flBall) {
					var dvx = SPEED * pitch - vx;
					var lim = Cs.S(0.5); // 0.25;
					var coef = 0.1;
					vx += Math.min(Math.max(-lim, dvx * coef), lim);
				}
				if (isUpDown()) {
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
						if (boost != null) {
							vy -= JUMP_EXTEND * boost * Timer.tmod;
						}
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
					// wframe = (wframe + (SPEED / 7) * Timer.tmod) % 11;
					// nextAnim = Std.string(128 + Std.int(wframe)); // TODO: suspicious
				}

				if (isUpDown()) {
					if (FL_EXTRA_JUMP)
						extraJump = 1;
					jump();
				}
				if (flDown) {
					jump();
					vy = Cs.S(-2.5);
					boost = 0;
					checkGroundSafe = 16;
				}
		}

		// TIR
		if (KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(KeyboardManager.CONTROL)) {
			if (flShootReady && cooldown <= 0) {
				shoot();
			}
			flShootReady = false;
		} else {
			flShootReady = true;
		}
	}

	function isLeftDown():Bool {
		return KeyboardManager.isDown(KeyboardManager.LEFT)
			|| KeyboardManager.isDown(KeyboardManager.Q)
			|| KeyboardManager.isDown(KeyboardManager.A);
	}

	function isRightDown():Bool {
		return KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D);
	}

	function isUpDown():Bool {
		return KeyboardManager.isDown(KeyboardManager.UP)
			|| KeyboardManager.isDown(KeyboardManager.W)
			|| KeyboardManager.isDown(KeyboardManager.Z);
	}

	function isDownDown():Bool {
		return KeyboardManager.isDown(KeyboardManager.DOWN) || KeyboardManager.isDown(KeyboardManager.S);
	}

	//
	function updateNoCol() {
		if (noColTimer == null)
			return;
		noColTimer -= Timer.tmod;

		var prc = 50 + Math.cos(((noColTimer * 100) % 628) * 0.01) * 50;
		if (noColTimer < 0) {
			noColTimer = null;
			prc = 0;
		}
		Col.setPercentColor(root, prc, 0xFFFFFF);
	}

	//
	function checkDeath() {
		for (i in 0...Cs.game.mList.length) {
			var m = Cs.game.mList[i];
			var distSq = getDeterministicDistSq(m.x, m.y);
			var hitRay = Cs.S(26);

			if (m.flCol && distSq < hitRay * hitRay) {
				if (auraTimer != null) {
					m.knockOut();
					m.vx = vx * 2;
					m.vy = -(Cs.S(7) + Cs.S(Seed.rand() * 4));
					m.flCol = false;
					Cs.game.genScore(m.x, m.y, Cs.C200);
					return;
				}

				if (!m.flSpike) {
					// var da  = Math.abs(getAng(m)-1.57)

					if (vy > 0) {
						vy = Cs.S(-7);
						y = m.y - Cs.S(20);
						m.harm(21, false);
						fillKunai();
						if (step == KICK) {
							vx *= 0.4;
							step = FLY;
							nextAnim = "fly_up";
							rootSprite.hero._rotation = 0;
							setSens(Std.int(vx / Math.abs(vx)));
						}
						return;
					}
				}
				var harmRay = Cs.S(18);
				if (noColTimer == null && distSq < harmRay * harmRay) {
					harm();
				}
			}
		}
	}

	function checkBonus() {
		var i = 0;
		while (i < Cs.game.bonusList.length) {
			var sp = Cs.game.bonusList[i];
			var pickupRay = Cs.S(20);
			if (getDeterministicDistSq(sp.x, sp.y) < pickupRay * pickupRay) {
				sp.take();
				i--;
			}
			i++;
		}
	}

	function getDeterministicDistSq(tx:Float, ty:Float):Float {
		var dx = Num.q(tx - x);
		var dy = Num.q(ty - y);
		return dx * dx + dy * dy;
	}

	function getDeterministicDist(tx:Float, ty:Float):Float {
		return Num.q(Math.sqrt(getDeterministicDistSq(tx, ty)));
	}

	//
	public override function checkPlatCol() {
		if (checkGroundSafe != null) {
			checkGroundSafe -= Timer.tmod;
			if (checkGroundSafe < 0)
				checkGroundSafe = null;
			return;
		}
		//
		super.checkPlatCol();
	}

	public override function land(pl) {
		initStep(GROUND);
		plat = pl;

		for (i in 0...3) {
			var p = Cs.game.newPart("partDust");
			p.x = x + (Seed.randVfx() * 2 - 1) * Cs.S(14);
			p.y = y + Cs.S(12 + Seed.randVfx() * 24);
			p.weight = Cs.S(0.1 + Seed.randVfx() * 0.3);
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
				if (FL_MOUSE_CONTROL)
					a = getMouseAngle(0.3);
				gp = new Grap(Cs.game.mdm.attach("mcKunai", Game.DP_HERO));
				gp.x = x;
				gp.y = y;
				gp.vx = Math.cos(a) + (vx / Cs.NEW_GEN_SCALE) * 0.05;
				gp.vy = Math.sin(a);
				gp.speed = GSPEED;
				gp.flFly = true;
				gp.orient();
			}
			updateInterface();
		}
	}

	public function grap() {
		nextAnim = "rope";
	}

	function shoot() {
		var o = getNextMonster();
		var speed = Cs.S(16);

		var a = sens * 1.57 - 1.57;

		if (o != null && o.mons != null) {
			var trg = {x: o.mons.x, y: o.mons.y};
			if (o.mons.vx != null) {
				var d = getDeterministicDist(trg.x, trg.y);
				var coef = d / speed;
				trg.x += o.mons.vx * coef;
				trg.y += o.mons.vy * coef;
			}
			a = getAng({x: trg.x, y: trg.y});
		}

		var dsLim = Cs.S(60);
		if (o != null && step == GROUND && o.dist < dsLim) {
			var list = getMonsterList();
			var dx = o.mons.x - x;
			var sens = Math.abs(dx) / dx;
			for (i in 0...list.length) {
				var o2 = list[i];
				if ((o2.m.x - x) * sens < 0 && o2.d < dsLim) {
					doubleStrike([o.mons, o2.m]);
					return;
				}
			}
		}

		var flNear = o != null && o.mons != null && o.dist < (optList[0] ? Cs.S(76) : Cs.S(52));
		if (flNear || starLeft == 0) {
			slash(o != null ? o.mons : null, flNear);
			return;
		}

		incStar(-1);
		updateInterfaceField();
		var idShot = optList[1] ? 2 : 1;
		var shot = new Star(Cs.game.mdm.attach("mcNinjaShot" + idShot, Game.DP_SHOT));
		shot.root.play();
		shot.root.loop = true;

		shot.x = x;
		shot.y = y;
		shot.vx = Math.cos(a) * speed;
		shot.vy = Math.sin(a) * speed;
		if (optList[1]) {
			shot.damage *= 2;
		}
		shot.frict = 1;
		cooldown = 2;
	}

	function slash(trg:Monster, flNear) {
		cooldown = 8;
		var bfx = optList[0] ? rootSprite.bfx2 : rootSprite.bfx1;
		bfx.gotoAndPlay(2);
		if (flNear) {
			if ((trg.x - x) * sens < 0)
				setSens(-sens);
			if (trg.cut != null) {
				trg.cut(21);
			}
			if (trg.hp > 0) {
				vx = Cs.S(-5) * sens;
			}
		}
	}

	function kick() {
		if (!optList[5])
			return;
		flDownReady = false;
		var distMin:Float = 9999;
		var mons = null;
		for (i in 0...Cs.game.mList.length) {
			var m = Cs.game.mList[i];

			var dx = m.x - x;
			var dy = m.y - y;

			if (dy > Cs.S(20) && dy < Cs.S(220) && Math.abs(dx) < Cs.S(80)) {
				var dist = Math.abs(dx) + Math.abs(dy);
				if (dist < distMin) {
					mons = m;
					distMin = dist;
				}
			}
		}

		if (mons != null) {
			var trg = {x: mons.x, y: mons.y};
			var sp = Cs.S(16);

			var dy = mons.y - y;
			var c = dy / sp;

			var npx = mons.x + mons.vx * c;
			var dx = npx - x;

			vx = dx / c;
			vy = sp;

			initStep(KICK);
			rootSprite.hero.gotoAndPlay(animFrame.get("kick"));
			nextAnim = "kick";

			setSens(1);
			rootSprite._rotation = Math.atan2(vy, vx) / 0.0174 + ((sens == -1) ? 180 : 0);
			rootSprite.updateState();
		}
	}

	function doubleStrike(a:Array<Monster>) {
		for (i in 0...a.length) {
			var mons = a[i];
			mons.harm(100, false);
		}
		nextAnim = "doubleStrike";
		rootSprite.hero.gotoAndPlay(animFrame.get("doubleStrike"));
		noControlTimer = 5;
		vx = 0;
		var mc = Cs.game.mdm.attach("mcOnde", Game.DP_ROPE);
		mc.play();
		mc._x = x;
		mc._y = y;
		Cs.game.genScore(x, y - Cs.S(25), Cs.C1000);
	}

	//
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
		if (gp != null) {
			gp.drop();
			gp = null;
		}
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
		if (auraTimer > 20) {
			if (auraLoopTimer > 0) {
				auraLoopTimer -= Timer.tmod; // Math.sqrt(vy*vy + vx*vx)*Timer.tmod;
				return;
			}
			// auraLoopTimer = 4;

			// auracol
			auraCol[auraColId] = Std.int(Num.mm(0, auraCol[auraColId] + auraColSens * 50, 255));
			if (auraCol[auraColId] == 255) {
				auraColId = Std.int(Num.sMod(auraColId - 1, 2));
				auraColSens = -1;
			} else if (auraCol[auraColId] == 0) {
				auraColId = Std.int(Num.sMod(auraColId + 2, 2));
				auraColSens = 1;
			}
			var col = {r: auraCol[0], g: auraCol[1], b: auraCol[2]};
			Cs.game.drawAura(root, col);
		}
	}

	//
	function getSnapshot(size) {
		var bmp = RenderTexture.create(Std.int(size), Std.int(size));

		var oldX = root.position.x;
		var oldY = root.position.y;
		var oldScaleX = root.scale.x;
		var oldScaleY = root.scale.y;
		var oldRotation = root.rotation;

		root.position.set(0, 0);
		root.scale.set(1, 1);
		root.rotation = 0;

		var m = new Matrix();
		m.scale(root._xscale / 100, root._yscale / 100);
		m.rotate(root._rotation * 0.0174);
		m.translate(size * 0.5, size * 0.5);
		bmp.draw(root, m);

		root.position.set(oldX, oldY);
		root.scale.set(oldScaleX, oldScaleY);
		root.rotation = oldRotation;

		return bmp;
	}

	function updateKick() {
		setSens(1);
		var bmp = getSnapshot(Cs.S(60));
		var mc = Cs.game.mdm.empty(Game.DP_MONS);
		mc.attachBitmap(bmp, 0);
		var p = new Part(mc);
		p.bmp = bmp;
		p.x = x - bmp.width * 0.5;
		p.y = y - bmp.height * 0.5;
		p.timer = 10;
		p.fadeLimit = 6;
		p.updatePos();
		Col.setPercentColor(p.root, 100, 0xFF00FF);
	}

	function harm() {
		if (hp > 0) {
			hp--;
			releaseGrap();

			rootSprite.hero.removeMovieClip();
			rootSprite.hero = root.attachMovie("mcHeroSlip", "heroSlip");
			setupAnims(rootSprite.hero);
			updatePos();
			setSens(sens);
			Filt.glow(root, 3, 2, 0x662200);

			noColTimer = 70;

			initStep(FLY);
			for (i in 0...50) {
				var p = Cs.game.newPart("mcCombi");
				p.x = x + (Seed.randVfx() * 2 - 1) * Cs.S(4);
				p.y = y + Cs.S(10 - i * 4);
				p.vx = vx * (1.2 + Seed.randVfx() * 0.8);
				p.vy = vy * (1.2 + Seed.randVfx() * 0.8) - Cs.S(2 + Seed.randVfx() * 7);
				p.timer = 50 + Cs.S(Seed.randVfx() * 10);
				p.weight = Cs.S(0.1 + Seed.randVfx() * 0.2);
				p.vr = (Seed.randVfx() * 2 - 1) * 6;

				p.root.gotoAndStop(i + 1);
				if (i + 1 == p.root._totalframes) {
					p.flPlatCol = true;
					p.ray = Cs.S(10);
					p.vr *= 3;
					break;
				}
			}
		} else {
			initStep(DEATH);
		}
		vy -= Cs.S(5);
		vx -= Cs.S(3);
	}

	public function hpUp() {
		hp = 1;
		var fr = rootSprite.hero._currentframe;
		rootSprite.hero.removeMovieClip();
		rootSprite.hero = root.attachMovie("mcHero");
		setupAnims(rootSprite.hero);
		rootSprite.hero.gotoAndPlay(fr);
		updatePos();
		setSens(sens);
	}

	// INTERFACE
	function initInterface() {
		kList = [];
		mcStarCount = cast Cs.game.dm.attach("mcStarCount", Game.DP_INTER);
		mcStarCount.field = mcStarCount.initTextField("field", {
			font: "Arial",
			size: 30,
			color: 0xFFFFFF,
		});
		mcStarCount.field.x = Cs.S(15);
		// Cs.glow(mcStarCount.field, 2, 2, 0);
		updateInterface();
	}

	function updateInterface() {
		for (i in 0...kunaiMax) {
			var mc = kList[i];
			if (mc == null) {
				kList[i] = Cs.game.dm.attach("mcInterKunai", Game.DP_INTER);
				untyped kList[i].smc = kList[i].attachMovie("mcInterKunaiKunai", "smc");
				mc = kList[i];
				mc._x = i * Cs.S(12);
			}
			mc.smc._alpha = (kunaiLeft > i) ? 100 : 10;
		}
		mcStarCount._x = kunaiMax * Cs.S(12) + Cs.S(2);
		updateInterfaceField();
	}

	function updateInterfaceField() {
		mcStarCount.field.text = Std.string(starLeft);
	}

	public function updateIcons() {
		while (iconList.length > 0)
			iconList.pop().removeMovieClip();
		var x:Float = Cs.mcw;
		for (i in 0...optList.length) {
			if (optList[i]) {
				var mc = Cs.game.dm.attach("mcIcon", Game.DP_INTER);
				mc.gotoAndStop(i + 1);
				mc._x = x;
				x -= Cs.S(20);
				iconList.push(mc);
			}
		}
	}

	function fillKunai() {
		kunaiLeft = kunaiMax;
		updateInterface();
	}

	public function incStar(n) {
		starLeft = Std.int(Num.mm(0, starLeft + n, starMax));
		updateInterfaceField();
	}

	public function incKunai(n) {
		kunaiMax += n;
		fillKunai();
	}

	//
	public function setSens(n) {
		sens = n;
		root._xscale = n * 100;
		if (root._prevState != null) {
			root._prevState.xscale = root._curState.xscale;
		}
	}

	function getNextMonster():{mons:Monster, dist:Float} {
		var distMin:Float = Cs.S(250);
		var mons:Monster = null;
		for (i in 0...Cs.game.mList.length) {
			var m = Cs.game.mList[i];
			var d = Num.q(Math.abs(m.x - x) + Math.abs(m.y - y));
			if (d < distMin) {
				distMin = d;
				mons = m;
			}
		}
		if (mons != null)
			return {mons: mons, dist: distMin};

		if (!Cs.game.flMouseDead && mons == null) {
			var mouse = Cs.game.getMapMouse();
			var mp = new PointWrapper({x: mouse.x + Cs.S(7), y: mouse.y + Cs.S(7)});
			var dist = getDeterministicDist(mp.x, mp.y);
			if (dist < Cs.S(140) && dist > Cs.S(50))
				return {mons: cast mp, dist: dist};
		}
		return null;
	}

	function getMonsterList():Array<{d:Float, m:Monster}> {
		var list:Array<{d:Float, m:Monster}> = [];

		for (i in 0...Cs.game.mList.length) {
			var m = Cs.game.mList[i];
			var d = Num.q(Math.abs(m.x - x) + Math.abs(m.y - y));
			var n = 0;
			do {
				if (list[n] != null && list[n].d > d)
					break;
				n++;
			} while (n < list.length);
			list.insert(n, {m: m, d: d});
		}
		return list;
	}

	function getMouseAngle(ma) {
		var mp = Cs.game.getMapMouse();
		return Num.mm(-3.14 + ma, getAng({x: mp.x, y: mp.y}), -ma);
	}
}
