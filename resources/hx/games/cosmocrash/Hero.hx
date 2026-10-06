package cosmocrash;

import cosmocrash.Cs.Num;

// Hero.hx of the original: the rescue ship. Left / right turn it, up thrusts (fuel); it lands on the platforms (slowly,
// not tilted), picks up the colonists that jump on it and drops them on a platform.
class Hero extends Element {
	static var BASE_WEIGHT = 0.05; // 0.07;

	var flReady:Bool;
	var flBoost:Bool;
	var flCrash:Bool;

	// (never set before the first flight: undefined, see Game.updateInter)
	public var danger:Null<Int>;

	var step:Int;
	var landTimer:Int;
	var angle:Float;
	var ray:Float;
	var nitro:Null<Float>;
	var flh:Null<Float>;

	var loopBonus:Int;

	var plat:Plat;

	var folks:Array<Folk>;

	// Filt.glow(root, ...) of the arrival
	var glow:FlashGlow;

	public function new(?fr:Int) {
		super(Game.me.dm.attach("mcHero", Game.DP_HERO));
		root.stepRot = true;
		if (fr == null)
			fr = 1;
		root.gotoAndStop(fr);

		x = -1; // Cs.mcw*0.5;
		y = Cs.mcw * 0.5;

		ray = 10;
		angle = -1.57;

		folks = [];

		Game.me.focus = this;
		takeOff();

		var pl = Game.me.plats[1];
		var px = pl.rampeX - 30;
		if (px < -(pl.ray - 8))
			px += 80;
		x = pl.x + px;
		y = pl.y;
		land(pl);

		loopBonus = 0;
		flh = 100;
	}

	public function init() {
		var pl = Game.me.plats[1];
		x = pl.x;
		y = pl.y;
		land(pl);
	}

	override function update() {
		flBoost = false;

		if (flh != null) {
			var prc = flh;
			flh *= 0.93;
			if (flh < 0.1) {
				flh = null;
				prc = 0;
			}
			Cs.setPercentColor(root, prc, 0xFFFFFF);
			root.clip.filters = null;
			if (flh != null && !root.removed) {
				if (glow == null)
					glow = new FlashGlow(0, 0, 0, 0xFFFFFF);
				glow.set(14 * flh * 0.01, 14 * flh * 0.01, 3 * flh * 0.01);
				root.clip.filters = [glow];
			}
		}

		switch (step) {
			case 0:
				updateFly();
			case 1:
				updateLand();
		}

		super.update();
		checkShots();

		if (flBoost)
			fxBoost();
		else
			nitro = null;
		for (i in 0...2) {
			root.setSubVisible("_reac" + i, flBoost);
		}
	}

	// FLY
	public function takeOff() {
		vy = -2;
		weight = BASE_WEIGHT;
		step = 0;
	}

	public function updateFly() {
		if (Math.abs(Num.hMod(angle - 3.14, 3.14)) < 0.1) {
			loopBonus = 100;
		}
		if (loopBonus > 0)
			loopBonus--;

		if (KeyboardManager.isDown(KeyboardManager.LEFT))
			turn(-1);
		if (KeyboardManager.isDown(KeyboardManager.RIGHT))
			turn(1);
		if (KeyboardManager.isDown(KeyboardManager.UP) && Game.me.fuel > 0)
			boost();
		checkLanding();
		checkLandCrash();

		//
		if (Cs.CONTROL_TYPE == 1) {
			var da = Num.hMod(angle + 1.57, 3.14);
			da *= 0.95;
			angle = da - 1.57;
			turn(0);
		}

		// BOUND PLAFOND
		if (y < -30) {
			vy = 0;
			y = -20;
		}
	}

	public function turn(n:Float) {
		var spa = 0.08;
		angle += n * spa;
		var n = 10;
		root._rotation = Std.int((angle / 0.0174) / n) * n + 90;
	}

	public function boost() {
		Game.me.incFuel(-0.12);
		flBoost = true;
		var pow = 0.2;
		var ca = Cs.q(Math.cos(angle));
		var sa = Cs.q(Math.sin(angle));
		vx += ca * pow;
		vy += sa * pow;
	}

	public function checkLanding() {
		// UPDATE DANGER
		var rot = Math.abs(root._rotation);
		danger = 0;
		if (rot > 10)
			danger++;
		if (rot > 30)
			danger++;

		var speed = Math.sqrt(vy * vy + vx * vx);
		if (speed > Cs.LAND_SPEED_LIMIT)
			danger++;
		if (speed > Cs.LAND_SPEED_LIMIT * 2)
			danger++;

		if (danger > 2)
			danger = 2;

		// CHECK PLATS
		for (pl in Game.me.plats) {
			var flUp = y + 9 < pl.y;
			if (flUp != pl.flUp) {
				var dx = Math.abs(pl.x - x);
				if (pl.flUp && dx < pl.ray + ray) {
					if (danger < 2 && dx < pl.ray) {
						land(pl);
					} else {
						crash();
					}
				}
				pl.flUp = flUp;
			}
		}
	}

	public function getSpeed() {
		return Math.sqrt(vx * vx + vy * vy);
	}

	// (both sides can touch the ground in the same frame: crash twice, like the original)
	public function checkLandCrash() {
		for (i in 0...2) {
			var sens = i * 2 - 1;
			var x = (x + 10 * sens);
			var gy = Game.me.getGY(x);

			if (gy < y + 8) {
				crash();
			}
		}
	}

	public function checkShots() {
		var px = Cs.getPX(x);
		var py = Cs.getPY(y);
		// (a cell out of the grid is undefined: no shot)
		var col = Game.me.sgrid[px];
		var a = col == null ? null : col[py];
		if (a == null)
			return;
		// (the loop of Haxe 2 reads the length at each turn: a shot killed here leaves the cell, the next one is skipped)
		var i = 0;
		while (i < a.length) {
			var shot = a[i];
			i++;
			var dx = Game.me.getHeroDX(shot.x);
			var dy = y - shot.y;
			if (Math.sqrt(dx * dx + dy * dy) < ray) {
				shot.kill();
				crash();
				return;
			}
		}
	}

	public function crash() {
		flCrash = true;
		#if debug
		Game.me.stats.crashes++;
		#end

		while (folks.length > 0) {
			var f = drop();
			f.x = x + (Seed.rand() * 2 - 1) * 10;
			f.y = y + (Seed.rand() * 2 - 1) * 10;
		}

		// EXPLO
		var mc = Game.me.dm.attach("mcExplosion", Game.DP_UNDER_FX);
		mc._x = x;
		mc._y = y;
		mc.blendAdd();

		// DUST (pictures: visual random)
		var max = 80;
		if (Math.abs(Game.me.getGY(x) - y) > 20)
			max = 0;
		for (i in 0...max) {
			var sp = 2 + Seed.randVfx() * 5;
			var a = i / max * 6.28;
			var cr = 2;
			var ca = Math.cos(a) * sp;
			var sa = Math.sin(a) * sp;
			var p = Game.me.getDust();
			p.x = x + ca * cr;
			p.y = y + sa * cr;
			p.vx = ca + vx * 0.3;
			p.vy = sa + vy * 0.3;
			p.updatePos();
		}

		// PARTS
		for (i in 0...12) {
			var mc = Game.me.dm.attach("partHero", Game.DP_FX);
			mc._x = x;
			mc._y = y;
			mc._rotation = root._rotation;
			mc.gotoAndStop(i + 1);
			var pos = partHeroSmc(mc, i);
			mc.setSub("smc", 0, 0);
			var p = new Part(mc);
			var a = Math.atan2(pos.y - mc._y, pos.x - mc._x);
			var sp = Seed.randVfx() * 4;
			p.x = pos.x;
			p.y = pos.y;
			p.vx = Math.cos(a) * sp + vx * 0.5;
			p.vy = Math.sin(a) * sp + vy * 0.5;
			p.vr = (Seed.randVfx() * 2 - 1) * 12;
			p.timer = 40 + Seed.randVfx() * 60;
			p.weight = 0.05 + Seed.randVfx() * 0.05;
			p.ray = 6;
			p.updatePos();
		}

		// SPARKS
		var max = 80;
		for (i in 0...max) {
			var sp = Seed.randVfx() * 8;
			var a = i / max * 6.28;
			var cr = 5;
			var ca = Math.cos(a) * sp;
			var sa = Math.sin(a) * sp;
			var p = getSpark(0);
			p.x += ca * cr;
			p.y += sa * cr;
			p.vx = ca + vx * 0.2;
			p.vy = sa + vy * 0.2;
			p.updatePos();
		}

		// ONDE
		var mc = Game.me.dm.attach("mcOnde", Game.DP_UNDER_FX);
		mc._x = x;
		mc._y = y;

		// PROJETT FOLKS (every colonist of the map; the loop of Haxe 2 reads the length at each turn: a colonist killed here
		// leaves the list and the next one is skipped)
		var fl = Game.me.folks;
		var i = 0;
		while (i < fl.length) {
			var f = fl[i];
			i++;
			f.fly();
			f.flBounce = true;
			f.root.gotoAndPlay("_jump2");
			f.root.gotoAndPlay(f.root._currentframe + Seed.randomVfx(10));
			f.vx += 100 / (f.x - x);
			f.vy = -Math.abs(300 / (f.x - x));
			var lim = 3 + Seed.rand() * 5;
			// (a colonist exactly on the hero: infinite speeds, the original loops forever; the port stops the loop)
			var guard = 0;
			while ((Math.abs(f.vx) > lim || Math.abs(f.vy) > lim) && guard++ < 100000) {
				f.vx *= 0.9;
				f.vy *= 0.9;
			}
			if (f.x - x == 0)
				f.kill();
		}

		if (Game.me.flRescue)
			Game.me.spawn();
		else
			Game.me.endTimer = 20;

		Game.me.hero = null;
		kill();
	}

	// Geom.getParentCoord(mc.smc, mc) of a piece of the hero: its smc (Data.PART_HERO_SMC) turned by mc._rotation
	function partHeroSmc(mc:MC, i:Int):{x:Float, y:Float} {
		var s = Data.PART_HERO_SMC[i];
		var x = s[0];
		var y = s[1];
		var r = mc._rotation;
		if (r != 0) {
			var dist = Math.sqrt(x * x + y * y);
			var a = Math.atan2(y, x);
			a += r * 0.0174;
			x = Math.cos(a) * dist;
			y = Math.sin(a) * dist;
		}
		x *= mc._xscale * 0.01;
		y *= mc._yscale * 0.01;
		return {x: x + mc._x, y: y + mc._y};
	}

	// FOLKS
	public function isFree() {
		return step == 0 && folks.length < 10;
	}

	public function board(f:Folk) {
		vy += 0.5;
		folks.push(f);
		updateFolks();

		var sc = Cs.SCORE_BOARD;
		var bonus = KKApi.cmult(Cs.SCORE_BOARD_BONUS, KKApi.const(folks.length - 1));
		sc = KKApi.cadd(sc, bonus);
		Game.me.addScore(sc);
		Game.me.fxScore(x, y - 10, KKApi.val(sc));
	}

	function drop():Folk {
		var f = folks.pop();

		var c = 2;

		f.unride();
		f.x = x + (Seed.rand() * 12 - 6) * c;
		f.y = y + (Seed.rand() * 12 - 6) * c;
		updateFolks();
		return f;
	}

	function updateFolks() {
		if (step == 0) {
			weight = BASE_WEIGHT + folks.length * 0.02; // + Game.me.dif*0.0001;
		}

		Game.me.mdm.clear(8);
		var id = 0;
		for (f in folks) {
			// (mcCosmo with _colorMe = f.colorMe: its colour copy)
			var mc = Game.me.mdm.attach(f.type == 0 ? "mcCosmo" : "mcCosmo" + f.type, 8);
			mc._x = 2 + id * 14;
			mc._y = 2;
			mc._xscale = mc._yscale = 200;
			id++;
		}
	}

	// FX
	public function getSpark(distMax:Float):Part {
		var p = new Part(Game.me.dm.attach("partSpark", Game.DP_UNDER_FX));
		p.x = x;
		p.y = y;
		p.weight = 0.025 + Seed.randVfx() * 0.04;
		p.timer = 10 + Seed.randVfx() * 50;
		p.bounceFrict = 0;

		var a = Seed.randVfx() * 6.28;
		var dist = Seed.randVfx() * distMax;
		p.root._rotation = a / 0.0174;

		p.root.setSub("smc", p.root.subX("smc") + dist);
		p.vr = (Seed.randVfx() * 2 - 1) * 20;
		p.fr = 0.95;
		p.x -= Math.cos(a) * dist;
		p.y -= Math.sin(a) * dist;

		return p;
	}

	function fxBoost() {
		if (nitro == null)
			nitro = 1;

		var ec = 8;

		var dx = Math.cos(angle + 1.57) * ec;
		var dy = Math.sin(angle + 1.57) * ec;

		for (i in 0...2) {
			if (Seed.randVfx() < nitro && Seed.randomVfx(Game.me.lag) == 0) {
				var sens = i * 2 - 1;
				var a = angle + (Seed.randVfx() * 2 - 1) * 0.1;
				var sp = 0.5 + Seed.randVfx() * 3;
				var ca = Math.cos(a);
				var sa = Math.sin(a);
				var p = getSpark(10);
				p.x += dx * sens - ca * ec;
				p.y += dy * sens - sa * ec;
				p.vx = vx * 0.5 - ca * sp;
				p.vy = vy * 0.5 - sa * sp;
				p.updatePos();
			}
		}

		// DUST GROUND
		if (Seed.randomVfx(Game.me.lag) == 0) {
			var sx = x;
			var sy = y;
			var max = 10;
			var ec = 10;
			var ca = Math.cos(angle);
			var sa = Math.sin(angle);
			var coef:Null<Float> = null;
			for (i in 0...max) {
				sx -= ca * ec;
				sy -= sa * ec;
				if (Game.me.getGY(sx) < sy) {
					coef = 1 - i / max;
					break;
				}
			}
			if (coef != null) {
				var max = Std.int(coef * 4);
				var pw = coef * 4;
				for (i in 0...max) {
					var p = Game.me.getDust(sx);
					p.vx = (Seed.randVfx() * 2 - 1) * pw;
					p.vy = -Seed.randVfx() * pw * 0.75;
					p.root._xscale = p.root._yscale = 150;
				}
			}
		}

		if (nitro > 0.1)
			nitro *= 0.8;
	}

	// LANDING
	public function land(pl:Plat) {
		flReady = false;
		step = 1;
		vx = 0;
		vy = 0;
		plat = pl;
		angle = -1.57;
		root._rotation = 0;
		weight = 0;
		landTimer = 3;
		y = plat.y + 1 - ray;

		updatePos();
		// PERFECT BONUS

		// LOOP BONUS
		if (folks.length > 0) {
			if (loopBonus > 0) {
				#if debug
				Game.me.stats.loops++;
				#end
				loopBonus = 0;
				var sc = KKApi.cmult(Cs.SCORE_LOOP, KKApi.const(folks.length));
				Game.me.addScore(sc);
				Game.me.fxScore(x, y - 15, KKApi.val(sc));
			}
		}
	}

	public function updateLand() {
		Game.me.incFuel(1);
		if (landTimer++ > 3 && folks.length > 0) {
			Game.me.stopRescue();
			landTimer = 0;
			var f = drop();
			f.jumpTo(plat);
		}

		if (folks.length == 0 && KeyboardManager.isDown(KeyboardManager.UP)) {
			if (flReady)
				takeOff();
		} else {
			flReady = true;
		}
	}
}
