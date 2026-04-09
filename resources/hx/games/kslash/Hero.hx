package kslash;

import mt.bumdum.Lib;
import common_haxe_avm1.KeyboardManager;
import mt.Timer;

class McShadeSprite extends ASprite {
	public var shade:ASprite;
}

class HeroSprite extends ASprite {
	public var kunai:ASprite;
	public var shade:ASprite;
	public var bfx1:ASprite;
	public var bfx2:ASprite;
}

class Hero extends Ent {
	static var SPEED = 5 * Cs.NEW_GEN_SCALE;
	static var JUMP_EXTEND = 3 * Cs.NEW_GEN_SCALE;
	static var JUMP_START = 8 * Cs.NEW_GEN_SCALE;

	static var STAR_SPEED = 14 * Cs.NEW_GEN_SCALE; // 10
	// static var BLADE_SIZE = 48
	static var QUEUE_SPACE = 5;

	var rootSprite:HeroSprite;
	var flQueue:Bool;

	var flShootReady:Bool;
	var flMoving:Bool;
	var flCheckGroundSafe:Bool;
	var flDoubleJump:Bool;
	var flDoubleJumpReady:Bool;
	var flUp:Bool;
	var flGameOver:Bool;

	// var flWood:Bool;
	public var flInvicible:Bool;
	public var sTimer:Float;

	var flControl:Bool;

	var boost:Float;
	var cooldown:Float;
	var jvx:Float;
	var woodTimer:Float;
	var qTimer:Float;
	var blink:Float;
	var star:Int;

	public function new(mc) {
		super(mc);
		// mc.getGraphics().beginFill(0x0000FF, 0.5).drawRect(-Cs.SIZE / 2, -Cs.SIZE / 2, Cs.SIZE, Cs.SIZE);
		mc.stopOnFrame = [70, 91, 104, 128];
		mc.onFrame.set(26, () -> mc.gotoAndPlay(1));
		mc.onFrame.set(36, () -> mc.gotoAndPlay(33));
		mc.onFrame.set(103, () -> mc.gotoAndPlay(1));
		mc.onFrame.set(115, () -> mc.gotoAndPlay(106));
		mc.onFrame.set(127, () -> mc.gotoAndPlay(117));
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
		rootSprite = cast mc;
		rootSprite.kunai = rootSprite.attachMovie("heroKunai", "kunai");
		rootSprite.kunai._visible = false;
		// rootSprite.shade = rootSprite.attachMovie("hero_shade", "shade");
		rootSprite.bfx1 = rootSprite.attachMovie("heroBfx1", "bfx1");
		rootSprite.bfx2 = rootSprite.attachMovie("heroBfx2", "bfx2");
		x = Std.int(Game.XMAX * 0.5);
		y = 1;
		weight = 0.7 * Cs.NEW_GEN_SCALE + 0.2;
		flMoving = false;
		cooldown = 0;
		star = 0;
		incStar(40);
		jvx = 0;
		sens = 1;

		// flWood = true;
		flInvicible = false;
		flControl = true;
		flGameOver = false;
		qTimer = 0;
		// initStep(Cs.ST_NORMAL)
		fall();
	}

	public function initStep(n) {
		step = n;
		switch (step) {
			case Cs.ST_NORMAL:
				flMoving = false;
			case Cs.ST_FLY:
				jvx = vx;
				flUp = true;
				flGround = false;
			case Cs.ST_DEATH:
				root.gotoAndStop(animFrame.get("death"));
				nextAnim = null;
				vy = -8 * Cs.NEW_GEN_SCALE;
				vx *= 0.5;
				flCol = false;
				flInvicible = true;
				flGround = false;
		}
	}

	public override function update() {
		var jvx = vx;

		if (flQueue)
			queue();

		super.update();

		if (!flGround)
			vx = jvx; // PATCH pour no friction en l'air

		switch (step) {
			case Cs.ST_NORMAL:
				control();
			case Cs.ST_FLY:
				control();
				if (flUp && vy > 0 && flDoubleJump) {
					flUp = false;
					if (nextAnim == null)
						nextAnim = "fly_down";
				}
			case Cs.ST_DEATH:
				var yLim = (Cs.mch * 2) - 18 * Cs.NEW_GEN_SCALE;
				if (root._y > yLim) {
					vy *= -1.25;
					if (!flGameOver) {
						Cs.game.stats.dif = Std.int(Cs.game.dif);
						KadoKadeoManager.kkm.gameOver(Cs.game.stats);
						flGameOver = true;
					}
					root._y = yLim;
				}
				vr = 5;
		}

		if (woodTimer != null) {
			woodTimer -= Timer.tmod;
			if (woodTimer < 0) {
				woodTimer = null;
				flControl = true;
				flInvicible = false;
				teleport();
			}
		} else {
			// if (root._rotation != 0)
			// 	root._rotation = 0;
		}

		if (boost != null) {
			boost *= Math.pow(0.8, (Timer.tmod * 0.5) + 0.5);
			if (boost < 0.1)
				boost = null;
		}

		if (sTimer != null)
			updateSupa();

		if (flCol) {
			if (!flInvicible) {
				checkDeath();
				checkBonus();
			}
		}
	}

	public function checkDeath() {
		for (tx in 0...3) {
			if (x + tx - 1 < 0 || x + tx - 1 >= Game.XMAX)
				continue;
			for (ty in 0...3) {
				if (y + ty - 1 < 0 || y + ty - 1 >= Game.YMAX)
					continue;
				var list = Cs.game.grid[x + tx - 1][y + ty - 1].list;
				for (m in list) {
					var dist = getDist(m);

					if (dist < 24 * Cs.NEW_GEN_SCALE) {
						if (sTimer == null) {
							if (step == Cs.ST_FLY && !m.flSpike) {
								var da = Math.abs(1.57 - getAng(m));
								if (da < 1.3) {
									if (vy > 0) {
										vy = -8 * Cs.NEW_GEN_SCALE;
										m.harm(21);
									}
									return;
								}
							}
							if (dist < 18 * Cs.NEW_GEN_SCALE) {
								initStep(Cs.ST_DEATH);
							}
						} else {
							burst(m);
						}
					}
				}
			}
		}
	}

	public function checkBonus() {
		for (b in Cs.game.bList) {
			if (getDist(cast b) < 24 * Cs.NEW_GEN_SCALE) {
				b.take();
			}
		}
	}

	public function control() {
		if (!flControl)
			return;
		// RUN
		// if(flGround)vx = 0;

		var flMove = false;
		if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
			setSens(-1);
			flMove = true;
		}
		if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
			setSens(1);
			flMove = true;
		}

		if (flMove) {
			if (flGround) {
				vx = SPEED * sens;
			} else if (flDoubleJump) {
				var dvx = SPEED * sens - vx;
				var lim = 0.25 * Cs.NEW_GEN_SCALE;
				vx += Math.min(Math.max(-lim, dvx * 0.1 * Cs.NEW_GEN_SCALE), lim); // vx = SPEED*sens;
			}
			if (!flMoving) {
				flMoving = true;
				if (flGround) {
					nextAnim = "walk";
					for (i in 0...3) {
						if (x - i * sens < 0 || x - i * sens >= Game.XMAX || y < 0 || y >= Game.YMAX)
							continue;
						if (Cs.game.grid[x - i * sens][y].list.length > 0) {
							nextAnim = "run";
							break;
						}
					}
				}
			}
		} else {
			if (flMoving) {
				flMoving = false;
				if (flGround)
					nextAnim = "wait";
			}
		}

		if (flGround) {
			vx *= Math.pow(0.8, Timer.tmod);
		} else {
			// vx = jvx
		}

		// JUMP
		// Log.print(flDoubleJump)
		// Log.print(flDoubleJumpReady)
		if (KeyboardManager.isDown(KeyboardManager.UP)) {
			if (flGround) {
				flDoubleJump = true;
				flDoubleJumpReady = false;
				jump();
			} else if (flDoubleJump && flDoubleJumpReady) {
				flDoubleJump = false;
				jump();
				nextAnim = "ball";
				if (flMove)
					vx = SPEED * sens;
			} else {
				if (boost != null) {
					vy -= JUMP_EXTEND * boost * Timer.tmod;
				}
			}
		} else {
			flDoubleJumpReady = true;
		}

		// DOWN
		if (flGround && KeyboardManager.isDown(KeyboardManager.DOWN) && y + 2 < Game.YMAX) {
			jump();
			boost = 0;
			vy *= 0.65;
			flCheckGroundSafe = true;
		}

		// SHOOT
		cooldown -= Timer.tmod;
		if (KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(KeyboardManager.CONTROL)) {
			if (cooldown < 0 && flShootReady)
				shoot();
		} else {
			flShootReady = true;
		}
	}

	public function jump() {
		initStep(Cs.ST_FLY);
		boost = 1;
		vy = -JUMP_START;
		nextAnim = "fly_up";
	}

	public override function land() {
		if (woodTimer != null) {
			if (vy > 4) {
				vr = (Cs.rand() * 2 - 1) * Math.abs(vy) * 3;
			}
			vx *= 0.8;
			vy *= -1;
			return;
		}
		super.land();

		initStep(Cs.ST_NORMAL);
		// if (nextAnim == null)
		nextAnim = "land";
		flDoubleJump = true;

		for (i in 0...3) {
			var p = Cs.game.newPart("partDust");
			p.x = root._x + (Cs.rand() * 2 - 1) * 14;
			p.y = root._y + 12 + Cs.rand() * 24;
			p.weight = 0.1 + Cs.rand() * 0.3;
			p.scale = 50 + Cs.rand() * 70;
			p.timer = 20 + Cs.rand() * 10;
			p.fadeType = 0;
			if (Cs.game.flNight) {
				p.root.gotoAndStop(2);
			} else {
				p.root.stop();
			}
		}
	}

	public override function checkGround() {
		if (flCheckGroundSafe) {
			flCheckGroundSafe = false;
			return false;
		}
		return super.checkGround();
	}

	public override function fall() {
		initStep(Cs.ST_FLY);
		super.fall();
		nextAnim = "fall";
		flUp = false;
	}

	public function shoot() {
		var list = Cs.game.getClosestMonsters();

		flShootReady = false;

		// CHECK BLADE
		var trg = list[0].m;
		var dx = trg.root._x - root._x;
		var dy = (trg.root._y - root._y) * 1.5;
		var dist = Math.sqrt(dx * dx + dy * dy);
		var flNear = dist < (Cs.game.optList[Cs.OPT_KATANA] ? 72 * Cs.NEW_GEN_SCALE : 48 * Cs.NEW_GEN_SCALE); // BLADE_SIZE
		if (flNear || star == 0) {
			slash(trg, flNear);
			return;
		}

		var max = 1;
		if (step == Cs.ST_FLY && !flDoubleJump) {
			max = Std.int(Math.min(star, list.length));
		}

		for (i in 0...max) {
			var o = list[i];
			if (o == null || o.d > 8)
				continue;
			throwStar(o.m);
		}
	}

	public function slash(trg:Monster, flNear:Bool) {
		cooldown = 10;
		var bfx = Cs.game.optList[Cs.OPT_KATANA] ? rootSprite.bfx2 : rootSprite.bfx1;
		bfx.gotoAndPlay(2);
		if (flNear) {
			var a = getAng(trg);
			if ((trg.x - x) * sens < 0)
				setSens(-sens);
			trg.cut(21);
			if (trg.hp > 0) {
				vx = -5 * sens;
			}
		}
	}

	public function throwStar(trg:Monster) {
		incStar(-1);
		cooldown = 2;
		var a = getAng(trg);
		var skinName = Cs.game.optList[Cs.OPT_FLAMES] ? "mcNinjaShot2" : "mcNinjaShot1";
		var s = new Star(Cs.game.mdm.attach(skinName, Game.DP_SHOOT));
		s.root.play();
		s.x = x;
		s.y = y;
		s.dx = dx + (cx - 1) * Cs.SIZE * 0.5;
		s.dy = dy + (cy - 1) * Cs.SIZE * 0.5;
		// s.vr = 13;
		s.vx = Math.cos(a) * STAR_SPEED;
		s.vy = Math.sin(a) * STAR_SPEED;
		if (Cs.game.optList[Cs.OPT_FLAMES]) {
			s.damage = 8;
		}
	}

	public function incStar(n) {
		star = Std.int(Math.min(Math.max(0, star + n), 200));
		Cs.game.inter.fieldStar.text = Std.string(star);
	}

	public function hit(s:Shoot) {
		if (Cs.game.optList[Cs.OPT_SCROLL]) {
			Cs.game.optList[Cs.OPT_SCROLL] = false;
			Cs.game.updateIcons();
			setSens(1);
			root.gotoAndStop(animFrame.get("tronc"));
			rootSprite.kunai._rotation = s.root._rotation;
			rootSprite.kunai._visible = true;
			smoke();
			flFreezeAnim = true;
			flInvicible = true;
			flControl = false;
			woodTimer = 30;
			//
			var vitx = s.vx * 0.5;
			var vity = s.vy * 0.5 - 3;
			if (flGround) {
				vity = Math.min(0, vity);
				if (vity < 0)
					initStep(Cs.ST_FLY);
			}
			vx += vitx;
			vy += vity;
		} else {
			initStep(Cs.ST_DEATH);
		}
	}

	public function teleport() {
		vr = 0;
		x = Std.int(Game.XMAX * 0.5);
		y = 1;
		vx = 0;
		vy = 0;
		flFreezeAnim = false;
		fall();
		smoke();
		rootSprite.kunai._visible = false;
		root._rotation = 0;
	}

	public function smoke() {
		var p = Cs.game.newPart("partSmoke");
		p.x = (x + 0.25 + (cx * 0.5)) * Cs.SIZE + dx;
		p.y = (y + 0.25 + (cy * 0.5)) * Cs.SIZE + dy;
		p.root.play();
		p.timer = 20;
	}

	public function initSupa() {
		sTimer = 500;
		blink = 0;
		SPEED = 9 * Cs.NEW_GEN_SCALE;
	}

	public function updateSupa() {
		sTimer -= Timer.tmod;
		qTimer -= Timer.tmod;
		if (qTimer < 0) {
			qTimer = QUEUE_SPACE;
			var mc:McShadeSprite = cast Cs.game.mdm.attach("mcShade", Game.DP_SHADE);
			mc.shade = mc.attachMovie("???.shade", "shade");
			mc._x = root._x;
			mc._y = root._y;
			mc._xscale = root._xscale;
			mc.shade.gotoAndStop(root._currentframe);
		}

		var blinkSpeed = 67;
		if (sTimer < 100)
			blinkSpeed = 127;
		blink = (blink + blinkSpeed * Timer.tmod) % 628;

		var prc = (Math.cos(blink / 100) + 1) * 40;
		if (sTimer < 0) {
			sTimer = null;
			prc = 0;
			SPEED = 5 * Cs.NEW_GEN_SCALE;
		}
		Col.setPercentColor(root, prc, 0xFFDDFF);
	}

	public function queue() {}

	public function burst(m:Monster) {
		m.harm(100); // var a = getAng(m)
		var max = 8;
		for (v in 0...max) {
			for (n in 0...2) {
				var p = Cs.game.newPart("partLight");
				p.x = m.root._x;
				p.y = m.root._y;
				var a = ((v + 0.5 * n) / max) * 6.28;
				var speed = (3 + n * 2);
				p.vx += Math.cos(a) * speed;
				p.vy += Math.sin(a) * speed;
				p.timer = 26 + Cs.rand() * 4 - n * 10;
				p.frict = 0.9;
			}
		}
	}
}
