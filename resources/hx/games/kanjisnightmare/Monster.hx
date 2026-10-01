package kanjisnightmare;

typedef Drop = {w:Int, id:Int};

class Monster extends Phys {
	static var WEIGHT = 1;

	public var flSpike:Bool;
	public var flCol:Bool;

	public var hp:Float;
	public var flash:Null<Float>;
	public var speed:Float;

	public var step:Int;
	public var sens:Int;
	public var stLevel:Int;
	public var score:Int;

	var stDrop:Array<Drop>;

	public var plat:Plat;

	public function new(mc:ASprite) {
		super(mc);
		Cs.game.mList.push(this);
		ray = 10;
		flSpike = false;
		hp = 10;
		score = Cs.C0;
		speed = 3;
		stDrop = [{w: 100, id: 1}, {w: 20, id: 2}, {w: 1, id: 3}];
		flCol = true;
		stLevel = 0;
		initStep(0);
		setSens(-1);
	}

	public function initStep(n:Int) {
		step = n;
		switch (step) {
			case 0: // GROUND
				root.gotoAndPlay("walk");
				weight = 0;
				vx = 0;
				vy = 0;
			case 1: // FLY
				weight = WEIGHT;
				plat = null;
			case 2: // FALL
				weight = WEIGHT;
				plat = null;
				vy = -(4 + Seed.rand() * 5);
				vr = (Seed.rand() * 2 - 1) * 18;
		}
	}

	public function knockOut() {
		initStep(2);
	}

	override public function update() {
		super.update();
		switch (step) {
			case 0: // GROUND
				if (plat.dead) {
					initStep(2);
				} else {
					if (plat.isOutX(x)) {
						x = Cs.mm(plat.x, x, plat.x + plat.w);
						setSens(-sens);
					}
					vx = speed * sens;
				}
			case 1: // FLY
				checkPlatCol();
			default:
		}
		updateFlash();
		if (y > 600 && Cs.game.hero.y < Hero.DL)
			kill();
	}

	// skin (shell colour, spikes): one clip per skin
	public function setSkin(n:Int) {
		stLevel = n;
		switch (stLevel) {
			case 0:
				hp = 10;
				score = Cs.C30;
				speed = 2;
				stDrop.push({w: 70, id: 4});
				stDrop.push({w: 4, id: 6});
				stDrop.push({w: 1, id: 8});
			case 1:
				hp = 30;
				score = Cs.C100;
				speed = 3;
				stDrop.push({w: 40, id: 4});
				stDrop.push({w: 30, id: 5});
				stDrop.push({w: 15, id: 6});
				stDrop.push({w: 15, id: 8});
				stDrop.push({w: 10, id: 24});
				stDrop.push({w: 10, id: 25});
				stDrop.push({w: 3, id: 20});
				stDrop.push({w: 3, id: 21});
				stDrop.push({w: 1, id: 23});
			case 2:
				hp = 60;
				score = Cs.C200;
				speed = 4;
				flSpike = true;
				stDrop.push({w: 40, id: 5});
				stDrop.push({w: 20, id: 20});
				stDrop.push({w: 20, id: 21});
				stDrop.push({w: 20, id: 25});
				stDrop.push({w: 10, id: 7});
				stDrop.push({w: 5, id: 23});
		}
		if (stLevel > 0) {
			var old:Clip = cast root;
			var mc = Clip.attach(Cs.game.mdm, "mcMonster" + (stLevel + 1), Game.DP_MONS);
			mc.gotoAndPlay(old.frame);
			if (!old.playing())
				mc.stop();
			old.removeMovieClip();
			root = mc;
			setSens(sens);
			updatePos();
			root.updateState();
		}
	}

	override public function land(pl:Plat) {
		plat = pl;
		initStep(0);
	}

	function updateFlash() {
		if (flash != null) {
			var prc = flash;
			flash *= 0.7;
			if (flash < 1) {
				flash = null;
				prc = 0;
			}
			Cs.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	public function hit(shot:Star) {
		KadoKadeoManager.kkm.addScore(Cs.C10);
		harm(shot.damage, false);
		throwBy(Math.atan2(shot.vy, shot.vx), 2);
	}

	public function cut(n:Float) {
		KadoKadeoManager.kkm.addScore(Cs.C50);
		harm(n, true);
		throwBy(1.57 - (1.57 * Cs.game.hero.sens), 10);
	}

	public function harm(n:Float, flSlash:Bool) {
		hp -= n;
		if (hp < 0) {
			death(flSlash);
		} else {
			flash = 100;
		}
	}

	function death(flSlash:Bool) {
		Cs.game.spawnBonus(root._x, root._y, getDrop());
		Cs.setPercentColor(root, 0, 0xFFFFFF);
		if (flSlash) {
			var a = [Game.DP_MONS, Game.DP_PARTS];
			for (i in 0...2) {
				var p = new Part(Clip.attach(Cs.game.mdm, "partMonster", a[i]));
				p.x = x;
				p.y = y;
				p.vx = vx - (i * 2 - 1) * 2;
				p.vy = vy - (2.5 + Seed.randVfx() * 2);
				p.vr = (Seed.randVfx() * 2 - 1) * 2;
				p.timer = 40 + Seed.randVfx() * 10;
				p.weight = 0.3;
				var c:Clip = cast p.root;
				c.gotoAndStop(2 - i);
				var smc = c.getClip("smc");
				if (smc != null)
					smc.gotoAndStop(stLevel + 1);
				p.flPlatCol = true;
				p.ray = 6;
				p.root._xscale = 100 * sens;
			}
		} else {
			// the clip plays its death and removes itself
			var c:Clip = cast root;
			var sp = Cs.game.registerMc(c);
			c.onRemoved = sp.kill;
			c.gotoAndPlay("death");
			root = null;
		}
		Cs.game.stats.bads[stLevel]++;
		KadoKadeoManager.kkm.addScore(score);
		kill();
	}

	function throwBy(a:Float, p:Float) {
		var vitx = Cs.q(Math.cos(a) * p);
		var vity = Cs.q(Math.sin(a) * p) - 3;
		if (step == 0) {
			vity = Math.min(0, vity);
			if (vity < -2) {
				initStep(1);
			} else {
				return;
			}
		}
		vx += vitx;
		vy += vity;
	}

	public function setSens(n:Int) {
		sens = n;
		root._xscale = n * 100;
	}

	function getDrop():Int {
		var sum = 0;
		for (d in stDrop)
			sum += d.w;
		var rnd = Seed.random(sum);
		sum = 0;
		for (d in stDrop) {
			sum += d.w;
			if (sum > rnd)
				return d.id;
		}
		return 0;
	}

	override public function kill() {
		Cs.game.mList.remove(this);
		super.kill();
	}
}
