package ironchouquette;

import common_haxe_avm1.KKApi;
import mt.Timer;
import mt.bumdum.Lib;
import pixi.core.Pixi.BlendModes;

class Bads extends Phys {
	public static var scoreDisplayLimit = 100;

	public var flDeath:Bool;
	public var flInvicible:Bool;
	public var flSide:Bool;
	public var flOrient:Bool;
	public var hp:Float;
	public var score:Int;
	public var score2:Int;
	public var mid:Int;

	public var dif:Float;
	public var spawnDist:Float;

	public var a:Float;
	public var va:Float;
	public var speed:Float;
	public var speedCoef:Float;
	public var trg:PointWithGetter;
	public var acc:{c:Float, lim:Float}

	public var turnCoef:Float;

	public var wave:Wave;
	public var pathIndex:Int;
	public var waveIndex:Int;
	public var bounceId:Int;

	public var way:Float;
	public var level:Float;
	public var turnSpeed:Float;
	public var shieldLim:Float;

	public var waitTimer:Float;
	public var shootTimer:Float;
	public var flameTimer:Float;
	public var outSafeTimer:Float;

	public var shootRate:Int;
	public var cooldown:Float;

	public var weapons:Array<Rafale>;
	public var rafale:Rafale;

	public var bList:Array<Int>;
	public var partList:Array<{b:Bads, dx:Float, dy:Float}>;

	public var ond:{
		decal:Float,
		speed:Float,
		amp:Float,
		by:Float,
		vx:Float,
		sens:Float,
		svy:Float
	}
	public var rect:{rw:Float, rh:Float}

	public var beeRange:Array<{
		w:Int,
		xMin:Float,
		xMax:Float,
		yMin:Float,
		yMax:Float
	}>;
	public var seekerLimit:Float;
	public var speedColorPhase:Int;

	public function new(mc) {
		if (mc == null)
			mc = Cs.game.dm.attach("mcBads", Game.DP_BADS);
		Cs.game.badsList.push(this);
		super(mc);

		bList = new Array();

		a = 1.57;
		va = 0.1;
		turnCoef = 0.1;
		speed = KadoKadeoManager.I(3);

		hp = 2;

		dif = 1;
		mid = 0;
		ray = KadoKadeoManager.I(16);
		level = 0;

		shootRate = 30;
		shootTimer = 0;

		speedCoef = 1;

		ond = {
			decal: 314,
			speed: 16,
			amp: KadoKadeoManager.S(0.1),
			by: KadoKadeoManager.I(50),
			vx: KadoKadeoManager.I(3),
			sens: 1,
			svy: 0
		}

		waitTimer = 200;
		speedColorPhase = Seed.random(2);
	}

	public function setLevel(lvl:Float) {
		if (level != null)
			Stykades.monsterLevel -= level;
		level = lvl;
		Stykades.monsterLevel += level;
	}

	public function setRect(w, h) {
		rect = {rw: w, rh: h}
		ray = Math.min(h, w);
	}

	public function setScore(sc) {
		score = sc;
	}

	public override function update() {
		if (this.root == null) {
			return;
		}
		updateBehaviour();
		updateFlash();
		checkCols();
		updateShoot();
		updateParts();
		if (bounceId != null)
			bounceFamily();

		// ORIENT
		if (flOrient)
			root._rotation = Math.atan2(vy, vx) / 0.0174;

		// CHECK OUT;
		if (outSafeTimer > 0) {
			outSafeTimer -= Timer.tmod;
		} else {
			var lim:Float = KadoKadeoManager.I(10);
			if (ray != null)
				lim += ray;
			if (rect != null)
				lim += Math.max(rect.rw, rect.rh);
			if (isOut(lim))
				kill();
		}

		//

		super.update();
	}

	public function dropBonus(?bonusId:Int, ?bonusDir:Int) {
		var b = new Bonus(null, bonusId, bonusDir);
		b.x = x;
		b.y = y;
	}

	// COLS
	public function checkCols() {
		// HERO
		{
			var h = Cs.game.hero;
			var flHit = getDist({x: h.x, y: h.y}) < ray + h.ray;
			if (rect != null)
				flHit = Math.abs(h.x - x) < rect.rw + h.ray && Math.abs(h.y - y) < rect.rh + h.ray;
			if (flHit && !h.isDead) {
				heroCollide();
			}
		}
		// LASER
		var power = Cs.game.hero.weapons[Hero.WP_LASER][0];
		var rl = 2 + Cs.game.hero.weapons[Hero.WP_LASER][1] * 2.5;
		if (power > 0 && Cs.game.hero.laserList != null) {
			for (pos in Cs.game.hero.laserList) {
				var flHit = Math.abs(pos[0] - x) + Math.abs(pos[1] - y) < ray + rl;
				if (rect != null)
					flHit = Math.abs(pos[0] - x) < rect.rw + rl && Math.abs(pos[1] - y) < rect.rh + rl;
				if (flHit) {
					if (Seed.randomVfx(Std.int((3 / Timer.tmod) / Game.PM)) == 0) {
						var p = new Part(Cs.game.dm.attach("partLaser", Game.DP_PARTS));
						var a = Seed.randVfx() * 6.28;
						var ca = Math.cos(a);
						var sa = Math.sin(a);
						var sp = KadoKadeoManager.S(3 + Seed.randVfx() * 3);
						p.x = x + ca * ray;
						p.y = y + sa * ray;
						p.vx = ca * sp + vx;
						p.vy = sa * sp + vy;
						p.setScale(100 + power * 10 + Seed.randVfx() * 50);
						p.timer = 10 + Seed.randVfx() * 10;
						p.fadeType = 0;
						p.root.blendMode = BlendModes.ADD;
						// p.plasmaId = 1
					}
					var isDead = damage((0.02 + power * 0.05) * Timer.tmod);
					if (isDead) {
						Cs.game.stats.spk[Hero.WP_LASER] += 1;
					}
					break;
				}
			}
		}

		// SPEED COLOR
		if (Cs.game.hero.weapons[Hero.WP_SPEED][0] > 0 && Cs.game.speedField.active) {
			if ((Cs.game.frameId + speedColorPhase) % 2 == 0) {
				var px = Std.int(root._x * Cs.game.pq);
				var py = Std.int((root._y + Game.PLASMA_CACHE) * Cs.game.pq);
				if (px >= 0 && py >= 0) {
					var col = Cs.game.speedField.getPixel(px, py);
					var o = Cs.colToObj32(col);
					var lim = 50;
					var score = o.r * 1.2;
					if (o.g == 0 && score > lim) {
						var c = (score - lim) / (255 - lim);
						var isDead = damage((0.07 + 1 * c) * Timer.tmod * 2);
						if (isDead) {
							Cs.game.stats.spk[Hero.WP_SPEED] += 1;
						}
						if (Seed.randomVfx(Std.int(Math.max(1, 2 / Timer.tmod))) == 0) {
							var mc = Cs.game.dm.attach("partStatic", Game.DP_PARTS);
							mc.removeOnFrame = 5;
							mc.play();
							mc._x = x + (Seed.randVfx() * 2 - 1) * ray;
							mc._y = y + (Seed.randVfx() * 2 - 1) * ray;
							mc._xscale = 100 + c * 100;
							mc._yscale = mc._xscale;
							mc._rotation = Seed.randVfx() * 360;
							mc.blendMode = BlendModes.ADD;
						}
					}
				}
			}
		}
	}

	public function heroCollide() {
		var h = Cs.game.hero;
		if (h.invincibleTimer == null) {
			h.explode();
		}
		score = null;
		var isDead = damage(10);
		if (isDead && Cs.game.hero.invincibleTimer != null) {
			Cs.game.stats.sak[Hero.WP_LASER][Cs.game.stats.sak[Hero.WP_LASER].length - 1][0] += 1;
		}
	}

	public function bounceFamily() {
		for (i in 0...Cs.game.badsList.length) {
			var b = Cs.game.badsList[i];
			if (b != this && b.bounceId == bounceId) {
				var dist = getDist({x: b.x, y: b.y});
				var dif = (ray + b.ray) - dist;
				if (dif > 0) {
					var a = getAng({x: b.x, y: b.y});
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					x -= ca * dif * 0.5;
					y -= sa * dif * 0.5;
					b.x += ca * dif * 0.5;
					b.y += sa * dif * 0.5;
				}
			}
		}
	}

	// BEHAVIOUR
	public function updateBehaviour() {
		if (shootTimer > 0)
			shootTimer -= Timer.tmod;
		if (waitTimer > 0)
			waitTimer -= Timer.tmod;
		var i = 0;
		while (i < bList.length) {
			var n = bList[i];
			switch (n) {
				case 0: // PATH

					var sp = wave.speed * Timer.tmod;
					way += sp * speedCoef;
					if (way > wave.pl[pathIndex]) {
						pathIndex++;
						if (pathIndex == wave.pl.length) {
							kill();
						} else {
							var p0 = wave.path[pathIndex - 1];
							var p1 = wave.path[pathIndex];
							var dx = p1[0] - p0[0];
							var dy = p1[1] - p0[1];
							var a = Math.atan2(dy, dx);
							var dist = Math.sqrt(dx * dx + dy * dy);
							var op = wave.pl[pathIndex - 1];
							var ecart = wave.pl[pathIndex] - op;
							var c = (way - op) / ecart;
							var ca = Math.cos(a);
							var sa = Math.sin(a);

							x = p0[0] + ca * c * sp;
							y = p0[1] + sa * c * sp;

							if (!wave.flLinear) {
								speedCoef = (ecart / 5) / wave.speed;
							}

							vx = ca * wave.speed * speedCoef;
							vy = sa * wave.speed * speedCoef;

							// SHOT
							switch (p0[2]) {
								case 0: // EACH SHOT
									initShot();
								case 1: // ALL SHOT
									for (k in 0...wave.bList.length) {
										wave.bList[k].initShot();
									}
									p0.splice(2, 1);
								case _:
							}
						}
					}

				case 1: // WANDERING
					va += (Seed.rand() * 2 - 1) * 0.06;
					va *= Math.pow(0.8, Timer.tmod);
					a += va;
					updateVit();

				case 2: // ONDULE
					ond.decal = (ond.decal + ond.speed * Timer.tmod) % 628;
					a += Math.cos(ond.decal / 100) * ond.amp;
					updateVit();

				case 3: // FOLLOW TARGET ANGLE
					var da = getAng(trg) - a;
					while (da > 3.14)
						da -= 6.28;
					while (da < -3.14)
						da += 6.28;
					a += Num.mm(-va, da * turnCoef, va) * Timer.tmod;

					vx = Math.cos(a) * speed;
					vy = Math.sin(a) * speed;
					if (getDist(trg) < KadoKadeoManager.I(50)) {
						onTargetReach();
					}

				case 4: // SHOOTER
					if (shootTimer <= 0) {
						if (Seed.random(Std.int(shootRate / Timer.tmod)) == 0) {
							initShot();
						}
					}

				case 5: // ONDULEUR HORIZONTAL
					if (vy > 0) {
						if (y >= ond.by) {
							ond.svy = vy;
							vy = 0;
							y = ond.by;
							ond.decal = 0;
						}
					} else if (vy < 0) {} else {
						ond.decal = (ond.decal + ond.speed * Timer.tmod) % 628;
						y = ond.by + Math.sin(ond.decal / 100) * (ond.amp * 100);
						x += ond.vx * ond.sens * Timer.tmod;
						var m = KadoKadeoManager.I(10);
						if (x < (ray + m) || x > Cs.mcw - (ray + m)) {
							ond.sens *= -1;
							x = Num.mm(ray + m, x, Cs.mcw - (ray + m));
						}

						if (waitTimer <= 0) {
							vy = -ond.svy;
						}
					}

				case 6: // BEE
					if (trg == null)
						chooseBeeTrg();

					// towardSpeed(trg,0.1,1)
					towardSpeed(trg, acc.c, acc.lim);

					var dx = trg.x - x;
					var dy = trg.y - y;
					if (Math.abs(dx) + Math.abs(dy) < KadoKadeoManager.I(20) + ray) {
						trg = null;
					}

				case 7: // FLAMER

					var pa = 0.3;
					var da = Num.hMod(getAng({x: Cs.game.hero.x, y: Cs.game.hero.y}) - 1.57, 3.14);

					if (Math.abs(da) < pa && getDist({x: Cs.game.hero.x, y: Cs.game.hero.y}) < KadoKadeoManager.I(100)) {
						flameTimer = 8;
					}
					if (flameTimer > 0) {
						flameTimer -= Timer.tmod;
						var shot = new Shot(null);
						shot.setSkin(22, 1);
						var a = 1.57 + (Seed.rand() * 2 - 1) * pa;
						var ca = Math.cos(a);
						var sa = Math.sin(a);
						var sp = KadoKadeoManager.S(5 + Seed.rand() * 3);
						shot.x = x + ca * ray;
						shot.y = y + sa * ray;
						shot.vx = ca * sp;
						shot.vy = sa * sp;
						shot.ray = 8;
						shot.timer = 10 + Seed.rand() * 10;
						shot.vr = (Seed.rand() * 2 - 1) * 20;
						shot.root.blendMode = BlendModes.ADD;
						shot.plasmaId = 1;
						shot.updatePos();
					}

				case 8: // SEEKER
					if (y > seekerLimit) {
						vy = 0;
						bList.splice(i, 1);
						i--;
						bList.push(3);
						trg = Cs.game.hero;
						hp = 2;
						root.play();
						score = score2;
						flOrient = true;
					}

				case 9: // STAGNE
					if (waitTimer > 0) {
						if (y > trg.y) {
							if (vy > 0)
								shootTimer = 0;
							vy = 0;
						}
					} else {
						vy -= KadoKadeoManager.S(0.3);
						shootTimer = 200;
					}

				case 10: // SHIELD

					for (shot in Cs.game.shotList) {
						if (shot.flGood && shot.skin != 14) {
							var dist = getDist({x: shot.x, y: shot.y});
							if (dist < shieldLim) {
								var d = shieldLim - dist;
								shot.x += Math.cos(a) * d;
								shot.y += Math.sin(a) * d;
							}
						}
					}
				case _:
			}
			i++;
		}

		//
	}

	public function updateVit() {
		vx = Math.cos(a) * speed;
		vy = Math.sin(a) * speed;
	}

	// SHOT
	public function initShot() {
		if (weapons == null) {
			return;
		}
		var max = 0;
		for (w in weapons)
			max += w.w;
		var rid = Seed.random(max);
		var sum = 0;
		for (raf in weapons) {
			sum += raf.w;
			if (sum > rid) {
				raf.init();
				break;
			}
		}

		/*
			shootTimer = cooldown;
			shot();
			if( rafale.index == null ){
				rafale.index = 0;
			}
		 */
	}

	public function updateShoot() {
		if (shootTimer == null)
			return;
		if (rafale == null) {
			shootTimer -= Timer.tmod;
			if (shootTimer <= 0)
				initShot();
		} else {
			rafale.update();
		}

		/*

			if(shootTimer<=0){
				if(weaponIndex!=null){
					var raf = weapons[weaponIndex];
					var si = raf.list[rafaleIndex];

					shootTimer = si.cooldown;
					raf.shot(si.type,si.params);

					rafaleIndex++;
					if(rafaleIndex==raf.list.length){
						weaponIndex = null;
						rafaleIndex = null;
					}
				}else{
					initShot();
				}

			}else{
				shootTimer-=Timer.tmod;
			}
		 */
	}

	public function newRafale() {
		if (weapons == null)
			weapons = new Array();
		var raf = new Rafale(this);
		weapons.push(raf);
		return raf;
	}

	// HIT
	public function hit(shot:Shot):Bool {
		return damage(shot.damage);
	}

	public function damage(n:Float):Bool {
		flash = 100;
		hp -= n;
		if (hp <= 0) {
			if (!flDeath) {
				die();
				return true;
			}
		}
		return false;
	}

	public function die() {
		onDeath();
		var v = KKApi.val(score);
		if (score != null) {
			KadoKadeoManager.kkm.addScore(score);
			if (v > scoreDisplayLimit) {
				var p = new Part(Cs.game.dm.empty(Game.DP_PARTS));
				p.x = x;
				p.y = y;
				p.timer = 20;
				p.fadeType = 0;
				var txt = p.root.initTextField('field', {
					font: "GAU",
					align: "center",
					size: 45,
					color: 0xFFFFFF,
					stroke: '#0000FF',
					strokeThickness: 6,
				});
				txt.text = Std.string(v);
			}

			// STATS
			var a:Array<Int> = null;
			for (i in 0...Cs.game.stats.k.length) {
				if (Cs.game.stats.k[i][0] == v) {
					a = Cs.game.stats.k[i];
					break;
				}
			}
			if (a == null) {
				a = [Std.int(v), 0];
				Cs.game.stats.k.push(a);
			}
			a[1]++;
		}
		explode();
		kill();
	}

	public function explode() {
		var max = 5 * Game.PM;
		for (i in 0...max) {
			var p = new Part(Cs.game.dm.attach("mcExploPart", Game.DP_PARTS));
			p.setScale(20 + Seed.randVfx() * 30);
			var a = Seed.randVfx() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var ray = KadoKadeoManager.I(8);
			var sp = KadoKadeoManager.S(3 + Seed.randVfx() * 5);
			p.x = x + ca * ray;
			p.y = y + sa * ray;
			p.vx = ca * sp;
			p.vy = sa * sp + Game.SCROLL_SPEED * (0.6 + Seed.randVfx() * 0.4);
			p.plasmaId = 1;
			p.timer = 10 + Seed.randVfx() * 10;
			// original: fadeType left undefined falls into Part.mt's default branch = alpha fade (the Int
			// default 0 here would scale-fade instead)
			p.fadeType = 6;
			p.root.blendMode = BlendModes.ADD;
			p.root._rotation = Seed.randVfx() * 360;
			p.root.play();
		}

		var mc = Cs.game.dm.attach("mcExploTrace", Game.DP_PARTS);
		mc.gotoAndStop(3);
		for (i in 0...3) {
			mc._x = x + (Seed.randVfx() * 2 - 1) * ray;
			mc._y = y + (Seed.randVfx() * 2 - 1) * ray;
			mc._xscale = 100 + Seed.randVfx() * 100;
			mc._yscale = mc._xscale;
			mc._rotation = Seed.randVfx() * 360;
			mc.blendMode = BlendModes.ADD;
			// mc.onFrame.set(3, function() {
			// 	Cs.game.plasmaDraw(mc, 1);
			// 	mc.removeMovieClip();
			// });

			Cs.game.plasmaDraw(mc, 1);
		}
		mc.removeMovieClip();
	}

	// PARTS
	public function setPart(b, dx, dy) {
		if (b == null) {
			return;
		}
		if (partList == null)
			partList = new Array();
		partList.push({b: b, dx: dx, dy: dy});
	}

	public function updateParts() {
		if (partList == null)
			return;
		for (i in 0...partList.length) {
			var o = partList[i];
			o.b.x = x + o.dx;
			o.b.y = y + o.dy;
		}
	}

	// SPECIFIC
	public function chooseBeeTrg() {
		var max = 0;
		for (r in beeRange)
			max += r.w;
		var rid = Seed.random(max);
		var cur = 0;
		for (i in 0...beeRange.length) {
			var o = beeRange[i];
			cur += o.w;
			if (cur > rid) {
				trg = {
					x: o.xMin + Seed.rand() * (o.xMax - o.xMin),
					y: o.yMin + Seed.rand() * (o.yMax - o.yMin),
				};
				break;
			}
		}
	}

	public function chooseNewTarget(xMin, xMax, yMin, yMax) {
		if (waitTimer <= 0) {
			trg = {x: x, y: KadoKadeoManager.S(-200)};
			return;
		}

		trg = {
			x: xMin + Seed.rand() * (xMax - xMin),
			y: yMin + Seed.rand() * (yMax - yMin),
		}
	}

	// ON
	public dynamic function onTargetReach() {}

	public dynamic function onDeath() {}

	public override function kill() {
		var i = 0;
		if (partList != null) {
			while (i < partList.length) {
				var b = partList[i].b;
				if (b.flDeath != true && b.flSide) {
					b.die();
				}
				partList.splice(i, 1);
			}
		}

		flDeath = true;
		if (level != null)
			Stykades.monsterLevel -= level;
		if (wave != null)
			wave.bList.remove(this);
		Cs.game.badsList.remove(this);
		super.kill();
	}
}
