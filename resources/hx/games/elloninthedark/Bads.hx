package elloninthedark;

class Bads extends Phys {
	public var bList:Array<Int>;

	public var flDeath:Bool;

	public var hp:Float;

	public var level:Float;
	public var score:Int;
	public var gid:Int;

	public var flash:Null<Float>;

	public var a:Null<Float>;
	public var va:Float;
	public var speed:Float;
	public var decal:Float;
	public var trg:{x:Float, y:Float};

	public var cooldown:Float;
	public var shootRate:Null<Float>;
	public var turnCoef:Float;

	public var wave:Wave;
	public var pathIndex:Int;
	public var waveIndex:Int;
	public var way:Float;

	public function new(mc:ASprite, level:Float) {
		super(mc);
		this.level = level;
		score = KKApi.const(0);
		bList = new Array();
		Cs.game.badsList.push(this);
		Cs.game.monsterLevel += level;
		flDeath = false;
		gid = 1;
		cooldown = 100;
	}

	override public function update() {
		super.update();
		updateBehaviour();
		checkCols();

		// SHOOT
		if (cooldown > 0) {
			cooldown -= Timer.tmod;
		} else {
			if (Seed.rand() * shootRate < 1) {
				shoot();
			}
		}

		// FLASH
		if (flash != null) {
			var prc = Math.min(flash, 100);
			flash *= 0.6;
			if (flash < 2) {
				flash = null;
				prc = 0;
			}
			Col.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	public function checkCols() {
		if (getDist(Cs.game.hero) < ray + Cs.game.hero.ray) {
			Cs.game.hero.death();
		}
	}

	public function updateBehaviour() {
		for (i in 0...bList.length) {
			var n = bList[i];
			switch (n) {
				case 0: // PATH
					var sp = wave.speed * Timer.tmod;
					way += sp;
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
							var op = wave.pl[pathIndex - 1];
							var c = (way - op) / (wave.pl[pathIndex] - op);
							var ca = Math.cos(a);
							var sa = Math.sin(a);

							x = p0[0] + ca * c * sp;
							y = p0[1] + sa * c * sp;

							vx = ca * wave.speed;
							vy = sa * wave.speed;

							setSens(vx / Math.abs(vx));
						}
					}

				case 1: // WANDERING
					va += (Seed.rand() * 2 - 1) * 0.06;
					va *= Math.pow(0.8, Timer.tmod);
					a += va;
					vx = Math.cos(a) * wave.speed;
					vy = Math.sin(a) * wave.speed;
					checkGround();
					if (isOut(ray + KadoKadeoManager.I(20)))
						kill();

				case 2: // ONDULE
					decal = (decal + 16 * Timer.tmod) % 628;
					y = trg.y + Math.cos(decal / 100) * KadoKadeoManager.S(20);
					root._rotation = Math.sin(decal / 100) * 40;
					if (x < -KadoKadeoManager.I(40))
						kill();

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
			}
		}
	}

	public function shoot() {}

	public function newShot() {
		var shot = new Shot();
		shot.x = x;
		shot.y = y;
		shot.frict = null;
		shot.flGood = false;
		return shot;
	}

	public function newAimedShot(speed:Float, ?sharp:Float) {
		if (sharp == null)
			sharp = 0;
		var shot = newShot();
		var a = getAng(Cs.game.hero) + (Seed.rand() * 2 - 1) * sharp;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		shot.x = x + ca * ray;
		shot.y = y + sa * ray;
		shot.vx = ca * speed;
		shot.vy = sa * speed;
		shot.orient();
		return shot;
	}

	public function hit(shot:Shot) {
		damage(shot.damage);
	}

	public function damage(n:Float) {
		flash = 100;
		hp -= n;
		if (hp <= 0) {
			if (!flDeath)
				explode();
		}
	}

	public function explode() {
		// ONDE
		{
			var p = Cs.game.mdm.attach("partOnde", Game.DP_UNDERPARTS);
			p._x = x;
			p._y = y;
			var sc = Cs.u(ray) * 2 + 30;
			p._xscale = sc;
			p._yscale = sc;
			p.removeOnFrame = 5;
			p.play();
		}

		// PAILLETES
		{
			var p = new Part(Cs.game.mdm.attach("partExplosion", Game.DP_UNDERPARTS));
			p.x = x;
			p.y = y;
			p.updatePos();
			p.root._rotation = Seed.randVfx() * 360;
			var sc = 20 + Cs.u(ray) * 6;
			p.root._xscale = sc;
			p.root._yscale = sc;
			p.root.onFrame.set(17, () -> p.kill());
			p.root.play();
		}
		// DEBRIS
		var fr = 0;
		while (true) {
			fr++;
			var p = new Part(Cs.game.mdm.attach("debris" + gid, Game.DP_PARTS));
			p.root.gotoAndStop(fr);

			var flBreak = (fr + 1) > p.root._totalframes;
			var a = Seed.randVfx() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var c = Seed.randVfx();
			var sp = KadoKadeoManager.S(3);

			p.x = x + ca * c * ray;
			p.y = y + sa * c * ray;
			p.vx = vx + ca * c * sp;
			p.vy = vy + sa * c * sp;
			p.vr = (Seed.randVfx() * 2 - 1) * 15;
			p.timer = 10 + Seed.randVfx() * 10;
			p.fadeType = 0;
			p.root._rotation = Seed.randVfx() * 360;
			if (flBreak)
				break;
		}

		// WAVE BONUS
		if (wave != null && wave.bList.length == 1) {
			var m = KadoKadeoManager.I(20);
			Cs.game.spawnScore(Num.mm(m, x, Cs.mcw - m), y, KKApi.val(wave.score));
			KadoKadeoManager.kkm.addScore(wave.score);
		}

		// SCORE
		KadoKadeoManager.kkm.addScore(score);
		//
		Cs.game.stats.k[gid]++;

		kill();
	}

	public function setSens(n:Float) {
		root._xscale = n * 100;
	}

	override public function kill() {
		flDeath = true;
		Cs.game.monsterLevel -= level;
		Cs.game.badsList.remove(this);
		if (wave != null)
			wave.bList.remove(this);
		super.kill();
	}

	public function bounceFamily() {
		var list = Cs.game.badsList;
		for (i in 0...list.length) {
			var b = list[i];
			if (b.level == level && b != this) {
				var dist = getDist(b);
				if (dist < ray * 2) {
					var a = getAng(b);
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var d = (ray * 2 - dist) * 0.5;
					x -= ca * d;
					y -= sa * d;
					b.x += ca * d;
					b.y += sa * d;
				}
			}
		}
	}

	public function checkGround() {
		if (y + ray > Cs.GL) {
			y = Cs.GL - ray;
			vy *= -0.8;
			genGroundSmoke();
			if (a != null) {
				a = Math.atan2(vy, vx);
			}
		}
	}

	// ON
	public function onTargetReach() {}
}
