package judocommando;

typedef JumpSquare = {sq:Square, dist:Float}

/**
 * The monsters. After a fatality the hero is removed (Game.me.hero = null) and the monsters keep playing until the
 * game over: Flash read undefined for every field of the missing hero (NaN in a calculation, every comparison with
 * it false, a method call on it doing nothing); the reads of the hero go through the helpers at the end of this file,
 * which give the same values.
 */
class Mon extends Human {
	var flAware:Bool;

	public var flSafe:Bool;
	public var flDestructor:Bool;
	public var flPileDriver:Bool;
	public var flInvincible:Bool;

	public var mtype:MonsterType;

	var stress:Int;
	var cooldown:Int;
	var deathTimer:Null<Float>;
	var godTimer:Null<Float>;

	var tag:Null<Tag>;

	var walkSpeed:Float;
	var jumpSpeed:Float;
	var reactivity:Float;
	var hunter:Float;
	var dodge:Float;
	var recovery:Float;

	// (set to null by Hero.interrupt: NaN here, like Flash reads null in a comparison)
	public var fkoTimer:Float;

	var activity:Null<MonsterActivity>;
	var behaviours:Array<MonsterBehaviour>;

	public function new() {
		var mc = Game.me.dm.attach("mcMonsters", Game.DP_ENT);
		mc.stop();
		super(mc);
		Game.me.monsters.push(this);
		flSafe = false;
		life = 10;
		walkSpeed = 0.02;
		climbSpeed = 0.05;

		flAware = false;
		flInvincible = false;

		behaviours = [Puncher, Miner, LongJumper, Gunner];
		reactivity = 0.03;
		hunter = 3.0;
		dodge = 3.0;
		jumpSpeed = 0.25;
		recovery = 1.0;

		type = MONSTER;
		ray = 0.5;
		stress = 0;
		cooldown = 0;

		setSens(Seed.random(2) * 2 - 1);

		initNormal();
		fkoTimer = 0;
	}

	// no free square for it (Game.initEnemies, from level 16 on): Flash placed it at undefined coordinates, out of the
	// grid and out of sight, where every calculation gives NaN and it never moves; it still counts in the level
	var isGhost:Bool = false;

	public function ghost() {
		isGhost = true;
		root._visible = false;
	}

	override function update() {
		if (isGhost)
			return;
		if (cooldown > 0)
			cooldown--;
		if (godTimer > 0)
			godTimer--;
		if (stress > 0)
			stress--;
		if (fkoTimer > 0)
			fkoTimer--;

		if (deathTimer > 0) {
			deathTimer--;
			root._visible = Std.int((deathTimer + 200) / 3) % 2 == 0;
		}

		switch (state) {
			case Normal:
				updateNormal();
			case Crash:
				updateCrash();
			case KneeGrabbed:
				updateKneeGrabbed();
			case Wheel:
				updateWheel();
			case Jump:
				updateLongJump();
			case Held:
				updateHeld();
			case Seek:
				updateSeek();
			case null:
			default:
		}
		super.update();
	}

	public function setSkin(n:Int) {
		root.gotoAndStop(n + 1);
	}

	// DAMAGE
	public function mtag(t:Tag) {
		tag = t;
		Game.me.playInfo._t[Type.enumIndex(t)]++;
	}

	override function damage(n:Float) {
		super.damage(n);
		if (life <= 0 && deathTimer == null) {
			deathTimer = 40;
			Game.me.playInfo._k[Type.enumIndex(mtype)]++;
			Game.me.fxScore(root._x, root._y, Cs.SCORE_MONSTERS[Type.enumIndex(mtype)]);
		}
	}

	// GRAPPLED
	public function grappled() {
		interrupt();
		state = Held;
		coef = 0;
		playAnim("grappling");
		setSens(-Game.me.hero.sens);
	}

	public function held() {
		interrupt();
		state = Held;
		coef = 0;
		stopPhys();
		playAnim("held");
	}

	override function land() {
		flSafe = false;
		flDestructor = false;
		fkoTimer = 0;
		var pow = Math.sqrt(vx * vx + vy * vy);
		stopPhys();
		if (knockOutTimer > 0 || life <= 0) {
			state = Crash;
			// (deathTimer undefined: NaN < 18 is false in Flash)
			if (deathTimer != null && deathTimer < 18)
				deathTimer = 18;
			playAnim("crash");
		} else {
			if (mtype == Gorilla && flPileDriver) {
				playAnim("impact");
				Game.me.fxShake(60);
				Game.me.updateLifeBar();
				scr(Game.me.initGameOver, 0);
			} else {
				playAnim("crouch");
				scr(backToNormal, 7);
			}
		}
	}

	function updateHeld() {
		var inc = reactivity;

		switch (Game.me.hero.holdStyle) {
			case KNEE, LIFT:
				inc = 0;
			case SHOULDER:
				inc *= 0.5;
			case GRAPPLE:
			case null:
		}
		coef += inc;
		if (coef > 1)
			freedom();
	}

	function freedom(vvx = 0) {
		var h = Game.me.hero;
		var sx = -Game.me.hero.sens;
		var hs = Game.me.hero.holdStyle;

		h.hit(sx, Cs.DAMAGE_FREEDOM);
		setSens(sx);
		jump();

		knockOutTimer = Math.NaN;
		vy = -3.5;
		switch (hs) {
			case SHOULDER:
				playAnim("highKick2");
				vx = -sens;
			case null:
				playAnim("highKick");
			default:
				playAnim("highKick");
		}
	}

	// KNEE GRABBED
	public function kneeGrabbed() {
		interrupt();
		setSens(Game.me.hero.sens);
		playAnim("kneeGrabbed");
		scr(gotoState.bind(KneeGrabbed), 10);
		scr(playAnim.bind("walk"), 0);
		updateKneeGrabbed();
	}

	public function updateKneeGrabbed() {
		walk(sens * walkSpeed);

		var h = Game.me.hero;

		h.copyPos(this);
		h.oy = 1 / Cs.CS;
		h.setSens(sens);

		if (Seed.random(20) == 0)
			setSens(-sens);
	}

	// KNOCKOUT
	override function updateKnockOut() {
		super.updateKnockOut();
		if (flSafe || fkoTimer > 0)
			return;
		var a = getNears(8, MONSTER);
		for (m in a) {
			if (m.isBodyCollidable()) {
				var flDodge = false;
				if (m.py + m.oy - 0.25 > py + oy) {
					m.tryDodge();
					flDodge = m.flCrouch;
				}

				if (!flDodge) {
					flSafe = true;
					m.flSafe = true;
					m.knockOut(vx * 0.35, -1);
					vx *= -0.25;
					vy -= 1;
					playAnim("walk");
					playAnim("knockOut");
					damage(Cs.DAMAGE_BODY_COLLISION);
					m.damage(Cs.DAMAGE_BODY_COLLISION);
					return;
				}
			}
		}

		// FATAL FALL
		if (py > Cs.YMAX + 10)
			kill();
	}

	override function onCollision(sx:Int, sy:Int) {
		super.onCollision(sx, sy);
		if (state == KnockOut) {
			if (sx != 0) {
				playAnim("hitWall");
				damage(Cs.DAMAGE_WALL_COLLISION);
			}
			if (sy == -1) {
				playAnim("hitCeiling");
				damage(Cs.DAMAGE_WALL_COLLISION);
			}
		}
	}

	override function confirmCol(sx:Int, sy:Int):Bool {
		if (flDestructor && py + sy < Cs.YMAX - 1) {
			Game.me.explodeSquare(px + sx, py + sy);
			return false;
		}

		if (state == KnockOut && sx != 0) {
			var sq = Game.me.getSq(px + sx, py + sy);
			if (sq.type == BLOCK && Seed.rand() * Cs.PROBA_PIERCE_WALL < 1) {
				damage(Cs.DAMAGE_WALL_PIERCE);
				Game.me.explodeSquare(px + sx, py + sy);
				return false;
			}
		}
		return true;
	}

	// FLY
	override function updateFly() {
		super.updateFly();

		checkSlash();

		// FATAL FALL
		if (py > Cs.YMAX + 10)
			kill();
	}

	// SCRIPT ACTION
	public function tryDodge() {
		if (Seed.rand() * dodge < 1 && state != Script) {
			interrupt();
			crouch();
		}
	}

	function crouch(wait = 8) {
		flCrouch = true;
		playAnim("crouch");
		scr(backToNormal, wait);
	}

	override function backToNormal() {
		super.backToNormal();
		playAnim("stand");
		flCrouch = false;
		initNormal();
	}

	// IA MODE
	public function initNormal() {
		state = Normal;
		initActivity();
	}

	function updateNormal() {
		if (activity == null)
			newActivity();

		// SECURITY (the original traces these in its test build)
		if (flSafe)
			flSafe = false;
		if (fkoTimer > 0)
			fkoTimer = 0;
		if (life <= 0)
			life = 1;

		switch (activity) {
			case Walk:
				walk(walkSpeed * sens);
				if (Seed.random(120) == 0 && !viewHero())
					setSens(-sens);
				if (state != Normal)
					return;
			case null:
			default:
		}

		// (|| Game.FL_TEST && Key.isDown(CONTROL): test build only)
		if (stress > 8) {
			magicJump();
			return;
		}

		// Awareness
		if (!flAware && Game.me.hero != null) {
			if (getSDist(Game.me.hero) < 5)
				flAware = true;
			return;
		}

		for (bh in behaviours) {
			switch (bh) {
				case Puncher:
					if (isHeroPunchable()) {
						playAnim("prepare");
						scr(punch, 14);
						scr(backToNormal, 10);
					}

				case Gunner:
					var dist = getHeroDist();
					if (dist > 25 && dist < 150 && (getFacedOpponent() == Game.me.hero)) {
						if (Seed.rand() * dist < 2) {
							if (heroCrouch() || Seed.random(3) == 0) {
								flCrouch = true;
								playAnim("crouchAim");
								scr(shoot, 20);
								scr(backToNormal, 6);
							} else {
								playAnim("aim");
								scr(shoot, 14);
								scr(backToNormal, 6);
							}
						}
					}

				case Croucher:
					if (Seed.rand() * 500 < 1) {
						crouch(50);
					}

				case Acrobat:
					if (heroPy() == py) {
						var dist = getDist(Game.me.hero);
						if (Seed.rand() * 500 < 1 || (Seed.rand() * 50 < 1 && dist < 30))
							initWheel();
					}

				case LadderClimber:
					if (heroPy() != py && Seed.rand() * 50 < 1) {
						var dy = heroPy() - py;
						var sy = Std.int(dy / Math.abs(dy));
						if (dy == 0)
							sy = 1;

						if (heroState() != Fly || Math.abs(dy) > 2) {
							if (sq.ladder && sy == -1) {
								if (isLadderFree(sq))
									grabLadder(sy);
							}
							var ground = Game.me.getSq(px, py + 1);
							if (ground.ladder && sy == 1) {
								if (isLadderFree(sq)) {
									grabLadder(sy);
									swapSquare(1);
									oy = 0;
								}
							}
						}
					};

				case LongJumper:
					if (Seed.rand() * 50 < 1)
						longJump();

				case Miner:
					var dist = heroDist();
					if (dist > 40 && Seed.rand() * 250 < 1) {
						var a = getSquares(1);
						var flOk = true;
						for (sq in a) {
							flOk = !sq.ladder;
							if (!flOk)
								break;
						}
						if (flOk) {
							playAnim("crouch");
							scr(dropMine, 25);
							scr(backToNormal, 10);
						}
					}

				case Jumper:
					if (Seed.rand() * 100 < 1 && (py != heroPy() || Seed.rand() * 3 < 1))
						seekJump();

				case God:
					jumpSpeed = Math.min(jumpSpeed + 0.0002, 1);
					walkSpeed = Math.min(walkSpeed + 0.0001, 0.25);

					// JUMP
					if (Seed.rand() * (30 + godTimer) < 1)
						magicJump();

					// SEEK
					if (Seed.rand() * (500 - godTimer * 0.5) < 1)
						initSeek(50 + Seed.rand() * godTimer * 0.5);

					// FATALITY
					if (py == heroPy() && getHeroHorDist() <= 0.7 && heroLife() > 0) {
						if (Seed.random(5) == 0) {
							jump();
							vx = sens * 4;
							vy = -5;
						} else {
							playAnim("stand");
							flAutoTurn = true;
							scr(tryFatality, 7);
						}
					}
				case Sword:
					var dist = heroSDist();
					if (dist < 1.5) {
						setSens(heroSens());
						playAnim("prepareSlash");
						scr(slash, 16);
						scr(backToNormal, 10);
					}

				case Rocketer:
					var dist = getHeroDist();
					if (cooldown == 0 && dist > 35 && dist < 150 && Seed.rand() < 0.2 && (getFacedOpponent() == Game.me.hero)) {
						cooldown = 300 + Seed.random(200);
						flCrouch = true;
						playAnim("crouchAimRocket");
						scr(shootRocket, 28);
						scr(backToNormal, 10);
					}

				default:
			}
		}
	}

	override function walk(speed:Float, ?f0:Void->Void, ?f1:Void->Void, ?f2:Void->Void) {
		if (f1 == null) {
			if (is(Faller) && heroPy() > py)
				f1 = null;
			else
				f1 = turnBack;
		}

		super.walk(speed, f0, f1, turnBack);
	}

	function initActivity() {
		switch (activity) {
			case Walk:
				playAnim("walk");
			case null:
			default:
		}
	}

	function newActivity() {
		activity = Walk;
		initActivity();
	}

	function isHeroPunchable():Bool {
		if (heroState() == Crash)
			return false;
		var hp = heroPos();
		var dx = -(Cs.getX(px + ox) - hp.x) * sens;
		return dx > 0 && dx < 11 && heroPy() == py;
	}

	function getHeroDist():Float {
		var hp = heroPos();
		var dx = -(Cs.getX(px + ox) - hp.x) * sens;
		if (dx < 0 || heroPy() != py)
			return 9999;
		return dx;
	}

	function getFacedOpponent(max = 10):Human {
		var ppx = px;
		var ppy = py;
		for (i in 0...max) {
			var sq = Game.me.getSq(ppx, ppy);
			if (sq.type == BLOCK)
				return null;
			for (e in sq.ent) {
				var h:Human = null;
				if (ppx != px || (e.ox - ox) * sens > 0) {
					if (e != this && (e.type == MONSTER || e.type == HERO)) {
						if (h == null || Game.me.hero == h)
							h = cast e;
					}
				}
				if (h != null)
					return h;
			}
			ppx += sens;
		}
		return null;
	}

	// ACTION
	function punch() {
		playAnim("punch");
		var h = Game.me.hero;
		if (isHeroPunchable() && h.state != Crouch) {
			if (h.holdStyle == LIFT && h.sens != sens) {
				h.bodyShieldDrop();
			} else {
				h.hit(sens, Cs.DAMAGE_PUNCH);
			}
		}
	}

	function shoot() {
		var bullet = new Bullet();
		var dy = -0.35;
		if (flCrouch)
			dy = 0;
		bullet.setPos(Cs.getX(px + ox + sens * 0.3), Cs.getY(py + oy + dy));
		bullet.setSens(sens);
		bullet.vx = 3 * sens;
	}

	function shootRocket() {
		var bullet = new Rocket();
		var dy = -0.35;
		if (flCrouch)
			dy = 0;
		bullet.setPos(Cs.getX(px + ox + sens * 0.3), Cs.getY(py + oy + dy));
		bullet.setSens(sens);
		bullet.vx = 5 * sens;
	}

	function dropMine() {
		var mine = new Mine();
		mine.moveTo(px, py);
		mine.ox = ox;
		mine.oy = 1 - (1 / Cs.CS);
	}

	function slash() {
		playAnim("attackSlash");

		var cx = Cs.getX(px + ox + sens);
		var cy = Cs.getY(py + oy) - 2;

		// FX
		var mc = Game.me.fxAttach("mcSwordSlash", cx, cy);
		mc._xscale = 100 * sens;

		var h = Game.me.hero;
		if (h != null && h.isTargetable() && h.getPDist(cx, cy, -6) < Cs.CS) {
			for (i in 0...3)
				h.fxBleed();
			h.hit(sens, Cs.DAMAGE_SWORD);
		}
	}

	function throwShuriken() {
		var sh = new Shuriken();
		var dy = -0.35;
		sh.setPos(Cs.getX(px + ox + sens * 0.2), Cs.getY(py + oy + dy));
		sh.updatePos();
		sh.aimAt(Game.me.hero, 3);
	}

	// TEST
	public function checkStealth():Bool {
		if (!is(Stealth))
			return false;

		// AUTO TELEPORT
		if (is(Teleport)) {}

		return true;
	}

	// SEEK
	var waitTimer:Float;

	function initSeek(wait = 60.0) {
		playAnim("seek");
		state = Seek;
		waitTimer = wait;
	}

	function updateSeek() {
		if (waitTimer-- <= 0 || viewHero()) {
			backToNormal();
			return;
		}
	}

	public function viewHero():Bool {
		var dyMax = 3;
		for (dx in 0...30) {
			// (the bound is read at each turn: a block above shortens the next columns)
			var dy = 0;
			while (dy < dyMax) {
				var x = px + dx * sens;
				var y = py - dy;
				var sq = Game.me.getSq(x, y);
				if (sq.type == BLOCK && x > 0 && x < Cs.XMAX) {
					if (dy == 0)
						return false;
					dyMax = dy;
				} else {
					for (e in sq.ent)
						if (e.type == HERO)
							return true;
				}
				dy++;
			}
		}
		return false;
	}

	// GOD
	function checkSlash() {
		if (!is(God))
			return;
		var h = Game.me.hero;
		if (h == null)
			return; // (undefined: h.state != KnockOut, but getDist(undefined) < 10 is false)

		if (h.state != KnockOut && getDist(h) < 10 && h.life > 0) {
			if (getDist(h) < 8 && py < Cs.YMAX - 3 && Seed.rand() * godTimer < 10) {
				Game.me.hero.fatalityGrabbed(this);
				jump();
				vx = 0;
				vy = -6.8;
				playAnim("piledriver");
				flDestructor = true;
				flPileDriver = true;
			} else {
				h.hit(-getSens(h), 2);

				var x = (h.root._x + root._x) * 0.5;
				var y = (h.root._y + root._y) * 0.5;

				// BLOOD
				var mc = fxBleed();
				mc._x = x;
				mc._y = y;

				// SLASH
				var mc = Game.me.dm.attach("mcSlash", Game.DP_FX);
				mc._x = x;
				mc._y = y;
				mc._xscale = (Seed.randomVfx(2) * 2 - 1) * 100;

				jump();
				vy = -(3.5 + Seed.rand());
				vx = (Seed.rand() * 2 - 1) * 2;
				playAnim((Seed.random(2) == 0) ? "highKick" : "highKick2");
			}
		}
	}

	function tryFatality() {
		var h = Game.me.hero;
		if (h != null && getDist(h) <= (Cs.CS - 2)) {
			var dy = root._y - h.root._y;
			if (dy > -5) {
				playAnim("fatalityGrab");
				if (dy > 6) {
					var s = root.sub2("smc", "smc");
					if (s != null)
						s.gotoAndPlay(10);
				}
				Game.me.hero.fatalityGrabbed(this);

				var rnd = Seed.random(2);
				switch (rnd) {
					case 0:
						scr(playAnim.bind("fatality0"), 30);
						scr(Game.me.updateLifeBar, 3);
						scr(Game.me.fxShake.bind(10), 0);

					case 1:
						scr(playAnim.bind("fatality1"), 20);
						scr(Game.me.updateLifeBar, 22);
						scr(Game.me.fxShake.bind(15), 0);
				}
				scr(Game.me.initGameOver, 10);
				flInvincible = true;

				return;
			}
		}
		// ECHEC
		playAnim("backToNormal");
		scr(backToNormal, 7);
	}

	// WHEEL
	function initWheel() {
		state = Wheel;
		playAnim("wheel");
		setSens(heroSens());
	}

	function updateWheel() {
		walk(sens * 0.1);
		if (heroSens() != sens && heroDist() > 30) {
			setSens(-sens);
			initNormal();
		}
	}

	// JUMP
	var jumpData:{sx:Float, sy:Float, end:Square, speed:Float};
	var oldx:Float;
	var oldy:Float;

	public function longJump() {
		var a = getJumpZone(5);
		genJumpData(a);
		initJump("jumpRoll");
	}

	public function seekJump() {
		var a = getJumpZone(4);
		filterJumpZoneFollow(a);
		genJumpData(a);
		initJump();
	}

	public function magicJump() {
		var a = getJumpZone(12);
		genJumpData(a, false);
		initJump();
	}

	function initJump(anim = "jump") {
		flJumpUp = true;
		if (jumpData == null)
			return;
		state = Jump;
		coef = 0;
		// (the position of the clip in the offsets, meant for oldx / oldy: the monster is drawn far away for one frame,
		// until updateLongJump places it; kept)
		ox = root._x;
		oy = root._y;
		playAnim(anim);
		if (sens * (jumpData.end.x - px) < 0)
			setSens(-sens);

		var dx = jumpData.sx - Cs.getX(jumpData.end.x + 0.5);
		var dy = jumpData.sy - Cs.getY(jumpData.end.y + 0.5);
		var dist = Math.sqrt(dx * dx + dy * dy) + 50;
		jumpData.speed = (Cs.CS * jumpSpeed) / dist;
	}

	function getJumpPos(c:Float):{x:Float, y:Float} {
		var ex = Cs.getX(jumpData.end.x + 0.5);
		var ey = Cs.getY(jumpData.end.y + 0.5);
		var x = jumpData.sx * (1 - c) + ex * c;
		var y = jumpData.sy * (1 - c) + ey * c - Cs.q(Math.sin(c * 3.14) * 30);
		return {x: x, y: y};
	}

	function updateLongJump() {
		coef = Math.min(coef + jumpData.speed, 1);
		var p = getJumpPos(coef);

		if (flJumpUp && p.y > root._y && anim == "jump") {
			flJumpUp = false;
			playAnim("jumpDown");
		}

		var jvx = p.x - oldx;
		var jvy = p.y - oldy;
		setPos(p.x, p.y);
		oldx = p.x;
		oldy = p.y;

		var h = Game.me.hero;

		// HIT
		if (is(LongJumper)) {
			if (h != null && getDist(h) < 12 && h.state == Fly) {
				playAnim("highKick");
				h.hit(this.getSens(h), Cs.DAMAGE_JUMP_KICK);
				jump();
				vy = -3;
				setSens(this.getSens(h));
				return;
			}
		}

		if (coef == 1) {
			oy = 0.5;
			setSens(heroSens());
			land();
		}

		for (bh in behaviours) {
			switch (bh) {
				case God:
					Game.me.explodeSquare(px, py);
					checkSlash();

				case Shuriken:
					if (coef > 0.4 && coef < 0.7 && getHeroHorDist() > 2) {
						if (Seed.rand() > 0.5 && heroSDist() < 10 && anim == "jumpRoll") {
							setSens(heroSens());
							playAnim("airThrow");
							throwShuriken();
							jump();
							vy = -5;
							vx = jvx * 0.5;
							anim = "jump";
						}
					}

				default:
			}
		}
	}

	function getJumpZone(ray:Int):Array<Square> {
		var a = [];
		for (dx in 0...1 + ray * 2) {
			for (dy in 0...1 + ray * 2) {
				var x = dx - ray;
				var y = dy - ray;
				var dist = Math.sqrt(x * x + y * y);
				if (dist > 1 && dist <= ray) {
					x += px;
					y += py;
					var sq = Game.me.getSq(x, y);
					var gr = Game.me.getSq(x, y + 1);
					if (sq.type == EMPTY && Game.me.isGround(gr.type)) {
						a.push(sq);
					}
				}
			}
		}
		return a;
	}

	function checkJumpLine():Bool {
		var max = 30;
		for (i in 0...max) {
			var c = i / max;
			var p = getJumpPos(c);
			var px = Cs.getPX(p.x);
			var py = Cs.getPY(p.y);
			if (!Game.me.isJumpFree(px, py))
				return false;
		}
		return true;
	}

	function filterJumpZoneFollow(a:Array<Square>) {
		var hdy = heroPy() - py;
		var b = a.copy();
		for (sq in b) {
			// (a <= b is !(a > b) in the Flash bytecode: true for NaN, the hero removed by a fatality)
			if (!((sq.y - py) * hdy > 0))
				a.remove(sq);
		}
	}

	function genJumpData(a:Array<Square>, flCheckLine = true) {
		jumpData = null;

		if (Seed.rand() * hunter < 1) {
			var b = [];
			var hpx = heroPx();
			var hpy = heroPy();
			for (sq in a) {
				var dx = sq.x - hpx;
				var dy = sq.y - hpy;
				b.push({sq: sq, dist: Math.sqrt(dx * dx + dy * dy)});
			}
			var me = this;
			var f = function(a:JumpSquare, b:JumpSquare) {
				if (a.dist < b.dist && Seed.rand() * me.hunter < 1)
					return -1;
				return 1;
			}
			// (Array.sort with a random comparison: its result depends on the sort algorithm; Haxe's merge sort is the
			// same in every browser, Array.prototype.sort is not)
			haxe.ds.ArraySort.sort(b, f);

			a = [];
			for (o in b)
				a.push(o.sq);
		} else {
			Cs.randomizeList(a);
		}

		for (i in 0...50) {
			if (a.length == 0)
				return;
			// (the field sq, the square of the monster in the grid: it reads the last square tried until the monster
			// moves to another square; kept)
			sq = a.shift();

			jumpData = {
				sx: Cs.getX(px + ox),
				sy: Cs.getY(py + oy),
				end: sq,
				speed: 0.00001
			};
			if (!flCheckLine || checkJumpLine())
				return;
			jumpData = null;
		}
	}

	// CRASH
	function updateCrash() {
		if (life <= 0) {
			if (deathTimer <= 0) {
				dropBonus();
				kill();
			}
		} else {
			knockOutTimer--;
			// (!(a > b) like the Flash bytecode of <=: NaN after freedom() gets up too)
			if (!(knockOutTimer > 0)) {
				crouch();
			}
		}
	}

	public function groundDamage(n:Int) {
		damage(n);
		var s = sens;
		knockOut(0, 1, n);
		land();
		setSens(s);
		playAnim("crashCustom");
	}

	override public function kill() {
		Game.me.monsters.remove(this);
		super.kill();
	}

	// PERSO
	function turnBack() {
		if (is(God) && Seed.rand() * godTimer < 100 && heroPy() == py && sens == heroSens()) {
			Game.me.explodeSquare(px + sens, py);
			return;
		}

		stress += 3;
		ox = 0.5;
		setSens(-sens);
	}

	// MONSTER TYPE
	public function setType(t:MonsterType) {
		mtype = t;
		var hfr = 4;
		var bfr = 2;
		var gfr = 2;
		switch (mtype) {
			case Standard:
				life = 4;
				behaviours = [Puncher, Faller, Jumper, LadderClimber];
				reactivity = 0.01;
				dodge = 10000.0;

			case Soldat:
				life = 8;
				behaviours = [Puncher, Faller, Jumper, Gunner, LadderClimber];
				hfr = 1;
				gfr = 1;
				dodge = 2.0;

			case Sapper:
				life = 10;
				behaviours = [Puncher, Faller, Jumper, Gunner, Miner, LadderClimber];
				bfr = 1;
				hfr = 2;
				gfr = 1;

			case Heavy:
				life = 8;
				behaviours = [Puncher, Faller, Jumper, Rocketer, LadderClimber];
				bfr = 3;
				hfr = 1;

			case Ninja:
				hunter = 2.0;
				life = 8;
				reactivity = 0.05;
				dodge = 1.5;
				behaviours = [Acrobat, LongJumper, Sword, Shuriken, Stealth];

			case Gorilla:
				flAware = true;
				hunter = 1.0;
				walkSpeed = 0.14;
				godTimer = 800;
				life = 500;
				dodge = 1.0;
				behaviours = [Jumper, God, Faller, Stealth];

			case Super:
				behaviours = [Puncher, Faller, Jumper, Gunner, Miner, LadderClimber, Acrobat, LongJumper];
		}

		root.gotoAndStop(Type.enumIndex(mtype) + 1);
		// Reflect.setField(root.smc, "_hfr", hfr)...: read by the frame scripts of the head, body and gun
		var smc = root.sub("smc");
		if (smc != null) {
			smc.setVar("hfr", hfr);
			smc.setVar("bfr", bfr);
			smc.setVar("gfr", gfr);
		}
	}

	override function playAnim(str:String) {
		anim = str;
		var smc = root.sub("smc");
		if (smc != null)
			smc.gotoAndStop(str);
	}

	override function nextFrame() {
		var s = root.sub2("smc", "smc");
		if (s == null)
			return;
		if (s.frame == s.def.n)
			s.gotoAndStop(1);
		else
			s.stepFrame();
	}

	// BONUS
	function dropBonus() {
		var btype:Bonus = null;
		if (tag != null && Seed.rand() * Cs.PROBA_GEM < 1)
			btype = Gem(tag);
		if (Seed.random(Cs.PROBA_YAKITORI) == 0)
			btype = Yakitori;
		if (Seed.random(Cs.PROBA_BURGER) == 0)
			btype = Burger;
		if (btype == null)
			return;

		var bonus = new PowerUp(btype);
		bonus.copyPos(this);
		bonus.initPhys();
		bonus.vy = -2.5;
		bonus.weight = 0.5;
		bonus.bounceFrict = 0.6;
	}

	// IS
	public function is(b:MonsterBehaviour):Bool {
		for (bh in behaviours)
			if (Type.enumEq(b, bh))
				return true;
		return false;
	}

	// fkoTimer <= 0 is !(fkoTimer > 0) in the Flash bytecode (Greater, Not): true for the null that Hero.interrupt
	// writes (the hero hit while holding it); NaN <= 0 in JS would leave the monster impossible to grab for good
	public function isGrappable():Bool {
		return state != Crash && state != Held && state != Wheel && state != Jump && state != Fly && !flSafe && !(fkoTimer > 0)
			&& !is(God) && life > 0 && state != Ladder;
	}

	public function isLadderFree(sq:Square):Bool {
		for (e in sq.ent) {
			if (e.type == MONSTER) {
				var mon:Mon = cast e;
				if (mon.state == Ladder) {
					return false;
				}
			}
		}
		return true;
	}

	public function isHitable():Bool {
		return state != Crash && state != KnockOut && !is(God);
	}

	public function isBodyCollidable():Bool {
		return (state == Normal || state == Script || state == Ladder || state == KnockOut) && !flCrouch && !flInvincible;
	}

	// GET
	public function getHeroHorDist():Float {
		var h = Game.me.hero;
		if (h == null)
			return Math.NaN;
		return Math.abs((px + ox) - (h.px + h.ox));
	}

	// ---------------------------------------------------------------- the hero as Flash read it (undefined once removed)
	inline function heroPx():Float {
		return Game.me.hero == null ? Math.NaN : Game.me.hero.px;
	}

	inline function heroPy():Float {
		return Game.me.hero == null ? Math.NaN : Game.me.hero.py;
	}

	inline function heroState():Null<State> {
		return Game.me.hero == null ? null : Game.me.hero.state;
	}

	inline function heroLife():Float {
		return Game.me.hero == null ? Math.NaN : Game.me.hero.life;
	}

	inline function heroCrouch():Bool {
		return Game.me.hero != null && Game.me.hero.flCrouch;
	}

	inline function heroPos():{x:Float, y:Float} {
		return Game.me.hero == null ? {x: Math.NaN, y: Math.NaN} : Game.me.hero.getPos();
	}

	// getSens(undefined): int(NaN / NaN) = 0
	inline function heroSens():Int {
		return Game.me.hero == null ? 0 : getSens(Game.me.hero);
	}

	inline function heroDist():Float {
		return Game.me.hero == null ? Math.NaN : getDist(Game.me.hero);
	}

	inline function heroSDist():Float {
		return Game.me.hero == null ? Math.NaN : getSDist(Game.me.hero);
	}
}
