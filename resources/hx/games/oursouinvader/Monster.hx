package oursouinvader;

// Monster.mt of the original: 1 HellCrabe (mcBadBoy), 2 Octopussy (mcOcto), 3 Bomber, 4 Oyster, 5 Mega Octopussy (mcBoss)
class Monster extends Phys {
	public var flKamikaze:Bool;

	public var tx:Float;
	public var ty:Float;

	public var ray:Float;
	public var flDeath:Bool = false;
	public var mType:Int;

	var diff:Float;
	var shield:Int;
	// (never set for the crab: undefined, never read for it)
	var nextShot:Int;

	var coolDownOcto:Int;
	var coolDownBomber:Int;
	var coolDownOyster:Int;

	public var step:Int;

	// Oyster param (undefined for the others: false where it is tested)
	public var isClosed:Bool = false;

	var nextOpeningTimer:Int;
	var openTimer:Int;
	var openingCoolDown:Int;
	var openCoolDown:Int;

	var introSpeedMax:Float;
	var introSpeedCoef:Float;

	var score:KKConst;

	public function new(mc:MC, type2Monstre:Int) {
		super(mc);
		// (pushed before super(mc) in the original: the other lists are not involved, the order is the same)
		Cs.game.monsterList.push(this);
		mType = type2Monstre;

		flKamikaze = false;
		frict = 0.92;

		var m = 20;
		introSpeedMax = 0.4 + Seed.rand() * 0.9;
		introSpeedCoef = 0.05 + Seed.rand() * 0.01;

		switch (Seed.random(3)) {
			case 0:
				x = Seed.rand() * Cs.mcw;
				y = -m;
			case 1:
				x = -m;
				y = Seed.rand() * Cs.mch * 0.5;
			case 2:
				x = Cs.mcw + m;
				y = Seed.rand() * Cs.mch * 0.5;
		}
		//
		initState();

		step = 0;
	}

	function initState() {
		// HellCrabe
		if (mType == 1) {
			ray = 13;
			diff = 1;
			shield = 0;
			score = Cs.SCORE_CRABE;
			root.setGlow(0xEC4F0A, 0.1, 10, 10, 2);
		}

		// Octopussy
		if (mType == 2) {
			ray = 12;
			diff = 2;
			shield = 1;
			score = Cs.SCORE_OCTO;
			coolDownOcto = 90;
			nextShot = coolDownOcto + 3 * Seed.random(coolDownOcto);
			root.setGlow(0xD230FD, 0.4, 5, 5, 2);
		}

		// Bomber
		if (mType == 3) {
			ray = 12;
			diff = 4;
			shield = 3;
			score = Cs.SCORE_BOMBER;
			coolDownBomber = 80;
			nextShot = coolDownBomber + 3 * Seed.random(coolDownBomber);
			root.setGlow(0x3BCF40, 0.4, 15, 15, 1);
		}

		// Oyster
		if (mType == 4) {
			ray = 12;
			diff = 8;
			shield = 1;
			score = Cs.SCORE_OYSTER;
			coolDownOyster = 40;
			nextShot = coolDownOyster + 3 * Seed.random(coolDownOyster);

			isClosed = true;
			openingCoolDown = 60;
			openCoolDown = 50;
			nextOpeningTimer = openingCoolDown + 3 * Seed.random(openingCoolDown);
			root.setGlow(0x246CD4, 0.4, 15, 15, 1);
		}

		// Mega Octopussy
		if (mType == 5) {
			ray = 30;
			diff = 2;
			shield = 80;
			score = Cs.SCORE_BOSS;
			coolDownOcto = 12;
			nextShot = coolDownOcto + 3 * Seed.random(coolDownOcto);
			root._xscale = 200;
			root._yscale = 200;
			root.setGlow(0xD230FD, 0.4, 20, 20, 2);
		}
	}

	override public function update() {
		super.update();

		switch (step) {
			case 0:
				var trg = {x: tx, y: ty};
				speedToward(trg, introSpeedCoef, introSpeedMax);

				if (getDist(trg) < 8) {
					vx = 0;
					vy = 0;
					Cs.game.nbIntro++;
					step = 10;
				}

			case 1:
				move();

				if (flKamikaze) {
					speedToward(Cs.game.hero, introSpeedCoef, introSpeedMax * 0.5);
				} else {
					if (y > Cs.game.mcLim._y) {
						vx = Cs.game.direction * Cs.game.mSpeed;
						flKamikaze = true;
						#if debug
						Cs.game.stats.kamikaze++;
						#end
					}
				}

			case 10:
				var trg = {x: tx, y: ty};
				toward(trg, 0.1, 1);
		}
	}

	// root.<eye>.<anim>._rotation = the angle towards the hero (only the picture: atan2 of the hero's clip, undefined
	// once it is dead: the rotation is not changed)
	function lookAtHero(eye:String, anim:String) {
		var e = root.sub(eye);
		if (e == null)
			return;
		var h = Cs.game.hero.root;
		e.setSub(anim, null, null, null, null, (Math.atan2((y - h._y), (x - h._x))) / (Math.PI / 180) + 90);
	}

	function move() {
		checkMonster();

		// Crabe
		if (mType == 1) {
			lookAtHero("cEyeI", "mcEyeAnim");
		}
		// Octopussy
		if (mType == 2) {
			lookAtHero("mcOctoEye", "mcOctoEyeAnim");
			if (nextShot == 0) {
				newShot(mType);
				nextShot = coolDownOcto + 3 * Seed.random(coolDownOcto);
			} else {
				nextShot--;
			}
		}

		// Bombers
		if (mType == 3) {
			if (nextShot == 0) {
				newShot(mType);
				nextShot = coolDownBomber + 3 * Seed.random(coolDownBomber);
			} else {
				nextShot--;
			}
		}

		// Oyster
		if (mType == 4) {
			if (nextOpeningTimer == 0) {
				if (isClosed) {
					openTimer = openCoolDown + Seed.random(openCoolDown);
					isClosed = false;
					root.gotoAndPlay("opening");
				} else {
					if (openTimer == 0) {
						root.gotoAndPlay("close");
						nextOpeningTimer = openingCoolDown + Seed.random(openingCoolDown);
						isClosed = true;
					} else {
						if (nextShot == 0) {
							newShot(mType);
							nextShot = coolDownOyster + 3 * Seed.random(coolDownOyster);
							isClosed = true;
						} else {
							nextShot--;
							openTimer--;
						}
					}
				}
			} else {
				nextOpeningTimer--;
			}
		}

		// MEGA Octopussy
		if (mType == 5) {
			lookAtHero("mcOctoEye", "mcOctoEyeAnim");
			if (nextShot == 0) {
				newShot(mType);
				nextShot = coolDownOcto + 3 * Seed.random(coolDownOcto);
			} else {
				nextShot--;
			}
		}
	}

	/************************************************************************ SHOOT  */
	function newShot(type:Int) {
		// Octopussy, bomber, oyster, boss: the same code for each in the original
		if (type == 2 || type == 3 || type == 4 || type == 5) {
			var shot = new Shot(null, type);
			shot.vy = shot.sShot;
			shot.x = x;
			shot.y = y - (ray / 2);
			root.gotoAndPlay("shoot");
		}
	}

	function checkMonster() {
		if (y > (260 - (ray + 10))) {
			isKilling();
		}
	}

	function isKilling() {
		var hero = Cs.game.hero;
		var xminHero = hero.x - hero.hWidth;
		var xmaxHero = hero.x + hero.hWidth;
		var yminHero = hero.y - hero.hHeight;
		var ymaxHero = hero.y + hero.hHeight;

		var xminMonster = x - ray;
		var xmaxMonster = x + ray;
		var yminMonster = y - ray;
		var ymaxMonster = y + ray;

		if ((ymaxMonster >= yminHero) && (ymaxMonster <= ymaxHero)) {
			// (never true: a left edge both left of the hero's left edge and right of its right edge)
			if ((xminMonster <= xminHero) && (xminMonster >= xmaxHero)) {
				Cs.game.hero.shooted(this);
			}
			if ((xmaxMonster >= xminHero) && (xmaxMonster <= xmaxHero)) {
				Cs.game.hero.shooted(this);
			}
		}
	}

	public function shooted() {
		if (shield == 0) {
			explode();
		} else {
			// (the monster turns around at random: only the picture, the visual random)
			// Crabe: nothing
			// Octopussy
			if (mType == 2) {
				shield--;
				root.gotoAndPlay("ouch");
				if (Seed.randomVfx(2) == 0) {
					root._xscale = -100;
				}
			}

			// Bombers
			if (mType == 3) {
				shield--;
				root.gotoAndPlay("ouch");
				if (Seed.randomVfx(2) == 0) {
					root._xscale = -100;
				}
			}

			// Oyster
			if ((mType == 4) && !isClosed) {
				shield--;
				root.gotoAndPlay("ouch");
				if (Seed.randomVfx(2) == 0) {
					root._xscale = -100;
				}
				isClosed = true;
			}
			// Octopussy
			if (mType == 5) {
				shield--;
				root.gotoAndPlay("ouch");
				if (Seed.randomVfx(2) == 0) {
					root._xscale = -200;
				}
			}
		}
	}

	public function explode() {
		vx = Cs.game.direction * Cs.game.mSpeed;
		#if debug
		Cs.game.stats.kills[mType - 1]++;
		#end

		if (Seed.random(10) == 0) {
			var b = new Bonus(null);
			b.x = x;
			b.y = y;
			b.updatePos();
		}
		Cs.game.addScore(score);
		Cs.game.dispScore(score, x, y);
		eAnim();
		root.gotoAndPlay("die");
		// root = null: the clip plays "die" and removes itself
		root = MC.NONE;
		kill();
	}

	function eAnim() {
		flDeath = true;
		if (mType != 5) {
			if (Seed.randomVfx(2) == 0) {
				root._xscale = -100;
			}
		} else {
			if (Seed.randomVfx(2) == 0) {
				root._xscale = -200;
			}
		}
	}

	override public function kill() {
		Cs.game.monsterList.remove(this);
		super.kill();
	}
}
