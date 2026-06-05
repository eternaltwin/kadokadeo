package kanjisnightmare;

import mt.bumdum.Sprite;
import mt.bumdum.Lib;
import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;
import mt.Timer;

class Monster extends Phys {
	static var WEIGHT = Cs.S(1);

	public var flSpike:Bool;
	public var flCol:Bool;

	public var hp:Float;

	var waitTimer:Float;
	var flash:Float;
	var speed:Float;

	var step:Int;
	var sens:Int;
	var stLevel:Int;
	var score:Int;

	var stDrop:Array<{w:Int, id:Int}>;

	public var plat:Plat;

	public function new(mc) {
		super(mc);
		Cs.game.mList.push(this);

		ray = Cs.S(10);

		flSpike = false;
		hp = 10;
		score = Cs.C0;
		speed = Cs.S(3);
		stDrop = [{w: 100, id: 1}, {w: 20, id: 2}, {w: 1, id: 3}];

		flCol = true;

		initStep(0);
		setSens(-1);
	}

	public function initStep(n) {
		step = n;
		switch (step) {
			case 0: // GROUND
				root.gotoAndPlay(1);
				weight = 0;
				vx = 0;
				vy = 0;

			case 1: // FLY
				weight = WEIGHT;
				plat = null;

			case 2: // FALL
				weight = WEIGHT;
				plat = null;
				vy = -(Cs.S(4 + Seed.rand() * 5));
				vr = (Seed.randVfx() * 2 - 1) * 18;
		}
	}

	public function knockOut() {
		initStep(2);
	}

	//
	public override function update() {
		super.update();
		switch (step) {
			case 0: // GROUND

				if (plat.root._visible != true) {
					initStep(2);
				} else {
					if (plat.isPlatOut(x)) {
						x = Num.mm(plat.x, x, plat.x + plat.w);
						setSens(-sens);
					}
					vx = speed * sens;
				}

			case 1: // FLY
				checkPlatCol();
		}
		updateFlash();

		if ((y > Cs.S(600) && Cs.game.hero.y < Hero.DL)) {
			kill();
		}
	}

	//
	public function setSkin(n) {
		stLevel = n;
		var m = root.attachMovie("mcMonster" + (stLevel + 1));
		m.onFrame.set(19, function() {
			m.gotoAndPlay(5);
		});
		m.removeOnFrame = 39;
		m.gotoAndPlay(1);
		switch (stLevel) {
			case 0:
				hp = 10;
				score = Cs.C30;
				speed = Cs.S(2);
				stDrop.push({w: 70, id: 4});
				stDrop.push({w: 4, id: 6});
				stDrop.push({w: 1, id: 8});
			// stDrop.push({w:1000,id:25})
			// stDrop.push({w:1000,id:8})

			case 1:
				hp = 30;
				score = Cs.C100;
				speed = Cs.S(3);
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
				speed = Cs.S(4);
				flSpike = true;
				stDrop.push({w: 40, id: 5});
				stDrop.push({w: 20, id: 20});
				stDrop.push({w: 20, id: 21});
				stDrop.push({w: 20, id: 25});
				stDrop.push({w: 10, id: 7});
				stDrop.push({w: 5, id: 23});
		}
	}

	//
	public override function land(pl) {
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
			Col.setPercentColor(root, Std.int(prc), 0xFFFFFF);
		}
	}

	//
	public function hit(shot:Star) {
		KadoKadeoManager.kkm.addScore(Cs.C10);
		harm(shot.damage, false);
		throwMonster(Math.atan2(shot.vy, shot.vx), 2);
	}

	public function cut(n) {
		KadoKadeoManager.kkm.addScore(Cs.C50);
		harm(n, true);
		throwMonster(1.57 - (1.57 * Cs.game.hero.sens), 10);
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
		Cs.game.spawnBonus(x, y, getDrop());
		Col.setPercentColor(root, 0, 0xFFFFFF);
		if (flSlash) {
			var a = [Game.DP_MONS, Game.DP_PARTS];
			for (i in 0...2) {
				var p = new Part(Cs.game.mdm.attach("partMonster" + (stLevel + 1), a[i]));
				p.x = x;
				p.y = y;
				p.vx = vx - (i * 2 - 1) * Cs.S(2);
				p.vy = vy - Cs.S(2.5 + Seed.randVfx() * 2);
				p.vr = (Seed.randVfx() * 2 - 1) * 2;
				p.timer = 40 + Seed.randVfx() * 10;
				p.weight = Cs.S(0.3);
				p.root.gotoAndStop(2 - i);
				p.flPlatCol = true;
				p.ray = Cs.S(6);
				p.root._xscale = 100 * sens;
			}
		} else {
			var ns = Cs.game.mdm.attach("mcMonster" + (stLevel + 1), Game.DP_MONS);
			var m = new Sprite(ns);
			m.x = root._x;
			m.y = root._y;
			m.root.removeOnFrame = 39;
			m.root.gotoAndPlay(20);
		}

		Cs.game.stats.bads[stLevel]++;
		KadoKadeoManager.kkm.addScore(score);

		kill();
	}

	function throwMonster(a, p) {
		var vitx = Num.q(Math.cos(a) * Cs.S(p));
		var vity = Num.q(Math.sin(a) * Cs.S(p) - Cs.S(3));
		if (step == 0) {
			vity = Math.min(0, vity);
			if (Num.q(vity) < Cs.S(-2)) {
				initStep(1);
			} else {
				return;
			}
		}
		vx += vitx;
		vy += vity;
	}

	function setSens(n) {
		sens = n;
		root._xscale = n * 100;
	}

	//
	function getDrop() {
		var sum = 0;
		for (i in 0...stDrop.length)
			sum += stDrop[i].w;
		var rnd = Seed.random(sum);
		sum = 0;
		for (i in 0...stDrop.length) {
			sum += stDrop[i].w;
			if (sum > rnd)
				return stDrop[i].id;
		}
		return 0;
	}

	//
	public override function kill() {
		Cs.game.mList.remove(this);
		super.kill();
	}
}
