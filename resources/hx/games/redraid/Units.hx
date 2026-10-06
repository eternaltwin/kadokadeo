package redraid;

import redraid.Game;

// ---------------------------------------------------------------- Arrow: a unit that walks and turns
class Arrow extends Phys {
	public var angle:Float;
	public var va:Float;
	public var ca:Float;

	// waypoint: a point {x, y, ray} or a unit (the target of an alien)
	public var wp:Dynamic;

	public var flWalk:Bool;
	public var flDeath:Bool;

	public var speed:Float;
	public var accel:Float;
	public var speedMax:Float;
	public var tol:Float;
	public var frame:Null<Float>;
	public var hp:Float;
	public var hpMax:Float;
	public var armor:Float;

	public var lifePanelTimer:Null<Float>;

	public var type:Int;

	public var skin:Clip;

	var shadow:Clip;
	var lifePanel:Clip;
	var shadowPlaced:Bool;

	public function new(mc:Clip) {
		super(mc);
		flWalk = true;
		flDeath = false;
		va = 1;
		ca = 0.1;
		angle = 0;
		speed = 0;
		accel = 0;
		speedMax = 0;
		tol = 10;
		armor = 0;
		hp = 0;
		hpMax = 1;
		shadowPlaced = false;
		initSkin();
	}

	public var clip(get, never):Clip;

	inline function get_clip():Clip {
		return cast root;
	}

	function initSkin() {
		clip.gotoAndStop(type + 1);
		skin = clip.getClip("sub");
		if (skin != null)
			skin.stop();
	}

	override public function update() {
		super.update();
		if (wp != null && wp.flDeath == true)
			wp = null;
		if (frame != null)
			run();

		if (shadow != null) {
			shadow._x = x;
			shadow._y = y;
			if (!shadowPlaced) {
				shadowPlaced = true;
				shadow.updateState();
			}
		}

		if (lifePanelTimer != null) {
			lifePanelTimer -= Timer.tmod;
			var limit = 5;
			if (lifePanelTimer < limit) {
				if (lifePanel != null)
					lifePanel._alpha = lifePanelTimer / limit * 100;
				if (lifePanelTimer < 0)
					hideLife();
			}
		}
		if (lifePanel != null) {
			lifePanel._x = x;
			lifePanel._y = y - ray;
		}
	}

	function setVit(speed:Float) {
		vx = Cs.cos(angle) * speed;
		vy = Cs.sin(angle) * speed;
	}

	function towardVit(c:Float, speed:Float) {
		var dvx = Cs.cos(angle) * speed - vx;
		var dvy = Cs.sin(angle) * speed - vy;
		vx += dvx * c;
		vy += dvy * c;
	}

	public function towardAngle(ta:Float) {
		var da = Cs.hMod(ta - angle, 3.14);
		angle += Cs.mm(-Math.abs(da), Cs.mm(-va, da * ca, va) * Timer.tmod, Math.abs(da));
		updateRotation();
	}

	function updateRotation() {
		root._rotation = angle / 0.0174;
	}

	function follow() {
		var dist = getDist(wp);
		var dSpeed = Cs.mm(0, (dist - tol) * 0.1, 1) * speedMax - speed;
		speed += dSpeed * accel * Timer.tmod;
		towardAngle(getAng(wp));
		setVit(speed);
		if (dSpeed < 0.1 && dist < tol) {
			reachWp();
		}
	}

	function reachWp() {
		wp = null;
		vx = 0;
		vy = 0;
	}

	public function hit(damage:Float, a:Null<Float>) {
		damage = Math.max(0, damage - armor);
		hp -= damage;
		showLife();
		lifePanelTimer = 30;
		if (hp <= 0) {
			die(a);
		}
	}

	function die(a:Null<Float>) {
		kill();
	}

	override public function kill() {
		flDeath = true;
		if (shadow != null)
			shadow.removeMovieClip();
		if (lifePanel != null)
			lifePanel.removeMovieClip();
		super.kill();
	}

	function run() {
		var dist = Math.sqrt(vx * vx + vy * vy);
		frame = (frame + dist * 2 * Timer.tmod) % 40;
		if (skin != null)
			skin.gotoAndStop(1 + Std.int(frame));
	}

	public function showLife() {
		if (lifePanel == null) {
			lifePanel = Cs.game.dm.add(new Clip("mcHpBar"), Game.DP_DRAW);
			lifePanel._x = x;
			lifePanel._y = y - ray;
			lifePanel.updateState();
		}
		// lifePanel.bar._xscale (a graphic of the clip: kept over the frames of its timeline)
		lifePanel.setOverride("bar", null, hp / hpMax * 100, null);
		lifePanel._alpha = 100;
	}

	public function hideLife() {
		if (lifePanel != null)
			lifePanel.removeMovieClip();
		lifePanel = null;
		lifePanelTimer = null;
	}

	public function setWaypoint(pos:Dynamic) {
		wp = pos;
		if (flWalk && frame == null)
			frame = 0;
	}
}

// ---------------------------------------------------------------- Ally: the soldiers
class Ally extends Arrow {
	public static var sel:Array<Ally>;

	public var flSelectable:Bool;

	var cd:Float;
	var range:Float;
	var view:Float;
	var damage:Float;
	var rate:Float;
	var swivel:Float;

	var ox:Float;
	var oy:Float;
	var giveup:Float;

	public var light:Null<Float>;

	var selector:Clip;

	public function new() {
		flSelectable = true;
		Cs.game.aList.push(this);
		Cs.game.bounceList.push(this);
		super(Cs.game.dm.add(new Clip("mcAlly"), Game.DP_UNITS));
		cd = 0;
		range = 0;
		view = 0;
		damage = 0;
		rate = 0;
		swivel = 0;
		giveup = 0;
		ox = 0;
		oy = 0;
	}

	override function initSkin() {
		super.initSkin();
		shadow = Cs.game.dm.add(new Clip("mcAllyShadow"), Game.DP_SHADOW);
		shadow.gotoAndStop(type + 1);
	}

	override public function update() {
		super.update();
		cd -= Timer.tmod;
		if (wp != null) {
			follow();
			giveup += 1.5 * Timer.tmod;
			giveup -= Math.abs(ox - x) + Math.abs(oy - y);
			ox = x;
			oy = y;
			if (giveup > 4) {
				wp = null;
			}
		}
		var trg = findTrg();
		if (trg != null) {
			faceTrg(trg);
			if (cd <= 0) {
				attack(trg);
			}
		}

		checkBound();

		if (light != null) {
			Cs.setPercentColor(root, light, 0xFFFFFF);
			light = (light - 1) * 0.9;
			if (light < 1) {
				light = null;
				Cs.setPercentColor(root, 0, 0xFFFFFF);
			}
		}
		if (selector != null) {
			selector._x = x;
			selector._y = y;
		}
	}

	override public function setWaypoint(pos:Dynamic) {
		super.setWaypoint(pos);
		giveup = 0;
		ox = x;
		oy = y;
	}

	function checkBound() {
		if (x < ray || x > Cs.mcw - ray) {
			x = Cs.mm(ray, x, Cs.mcw - ray);
			vx = 0;
		}
		if (y < ray || y > Cs.mch - ray) {
			y = Cs.mm(ray, y, Cs.mch - ray);
			vy = 0;
		}
	}

	function faceTrg(trg:Alien) {
		towardAngle(getAng(trg));
	}

	function findTrg():Alien {
		var max = Math.POSITIVE_INFINITY;
		var trg:Alien = null;
		for (bad in Cs.game.bList) {
			var dist = getDist(bad);
			var flValide = (dist < bad.ray + ray + range) && dist < max;
			if (flValide && wp != null) {
				var da = Cs.hMod(getAng(bad) - angle, 3.14);
				if (Math.abs(da) > swivel) {
					flValide = false;
				}
			}
			if (flValide) {
				trg = bad;
				max = dist;
			}
		}
		return trg;
	}

	function attack(trg:Alien) {
		cd = rate;
		var a = getAng(trg);

		// IMPACT
		var mc = Cs.game.dm.add(new Clip("partImpact"), Game.DP_PART);
		mc._rotation = a / 0.0174;
		mc._x = trg.x + (Seed.randVfx() * 2 - 1) * trg.ray * 0.8;
		mc._y = trg.y + (Seed.randVfx() * 2 - 1) * trg.ray * 0.8;
		mc._xscale = 100;
		mc._yscale = mc._xscale;
		mc.updateState();

		// RECUL
		var rec = 5 * trg.mass / Timer.tmod;
		trg.vx += Cs.cos(a) * rec;
		trg.vy += Cs.sin(a) * rec;

		trg.hit(damage, a);
	}

	override public function kill() {
		sel.remove(this);
		if (selector != null)
			selector.removeMovieClip();
		Cs.game.aList.remove(this);
		Cs.game.bounceList.remove(this);
		super.kill();
	}

	override public function hit(damage:Float, a:Null<Float>) {
		showLife();
		lifePanelTimer = 30;
		super.hit(damage, a);
	}

	override function die(ba:Null<Float>) {
		if (type < 3) {
			var sp = new Part(Cs.game.dm.add(new Clip("mcCadaver"), Game.DP_BONUS));
			sp.x = x;
			sp.y = y;
			sp.root._rotation = root._rotation;
			(cast sp.root : Clip).gotoAndStop(type + 1);
			sp.timer = 50 + Seed.randVfx() * 10;
		}
		super.die(ba);
	}

	// SELECTION

	public static function flushSelect() {
		while (sel.length > 0) {
			var al = sel.pop();
			if (al.selector != null)
				al.selector.removeMovieClip();
			al.selector = null;
		}
	}

	public function addToSel() {
		sel.push(this);
		selector = Cs.game.dm.add(new Clip("mcSelectRound"), Game.DP_SELECTOR);
		selector._x = x;
		selector._y = y;
		selector.gotoAndStop(type + 1);
		selector.updateState();
	}

	public function selectOne() {
		flushSelect();
		addToSel();
	}
}

class Marine extends Ally {
	public function new() {
		type = 0;
		super();
		va = 1;
		ca = 0.3;
		ray = 10;
		tol = 10;
		hpMax = 10;
		frame = 0;
		accel = 0.2;
		speedMax = 3;
		range = 60;
		damage = 2;
		rate = 4;
		swivel = 0.8;
	}

	override function attack(trg:Alien) {
		var b = skin != null ? skin.getClip("b") : null;
		if (b != null)
			b.gotoAndPlay(2);
		var mc = Cs.game.dm.add(new Clip("partFlashLight"), Game.DP_SHADOW);
		mc._x = x;
		mc._y = y;
		mc._rotation = root._rotation;
		mc.updateState();
		super.attack(trg);
	}
}

class Grenadier extends Ally {
	public function new() {
		type = 1;
		super();
		va = 1;
		ca = 0.3;
		ray = 10;
		tol = 10;
		hpMax = 10;
		frame = 0;
		accel = 0.2;
		speedMax = 3;
		range = 180;
		damage = 1000;
		rate = 100;
		swivel = 0.2;
	}

	override function attack(trg:Alien) {
		skin.gotoAndPlay("launch");
		frame = null;

		if (Math.abs(Cs.hMod(getAng(trg) - angle, 3.14)) > 0.1)
			return;
		var sp = new Grenade();
		sp.setPos(x, y);
		var dec = 10;
		sp.setTrg(trg.x + (Seed.rand() * 2 - 1) * dec, trg.y + (Seed.rand() * 2 - 1) * dec);

		cd = rate;
	}
}

class Medic extends Ally {
	static inline var HEAL_RANGE = 6;
	static inline var SEEK_RANGE = 60;
	static inline var HEAL_RATE = 0.15;

	public function new() {
		type = 2;
		super();
		va = 1;
		ca = 0.3;
		ray = 8;
		tol = 6;
		hpMax = 10;
		frame = 0;
		accel = 0.2;
		speedMax = 3;
		damage = 6;
		rate = 4;
	}

	override public function update() {
		super.update();
		if (wp == null) {
			updateHeal();
		}
	}

	function updateHeal() {
		var list = [];
		for (sp in Cs.game.aList) {
			if (sp != this && sp.type != 3 && sp.hp < sp.hpMax) {
				var dist = getDist(sp);
				if (dist < sp.ray + ray + SEEK_RANGE)
					list.push({sp: sp, dist: dist});
			}
		}
		// (equal distances keep their order: the same sort in every browser)
		list.sort(function(a, b) return a.dist > b.dist ? 1 : (a.dist < b.dist ? -1 : 0));

		for (o in list) {
			var sp = o.sp;
			if (cd < 0) {
				if (o.dist < sp.ray + ray + HEAL_RANGE) {
					for (n in 0...3)
						towardAngle(getAng(sp));
					cd = rate;
					sp.hp = Math.min(sp.hp + HEAL_RATE, sp.hpMax);
					sp.showLife();
					sp.lifePanelTimer = 30;
					skin.gotoAndPlay("heal");
					frame = null;
					var p = new Part(Cs.game.dm.add(new Clip("partLuciole"), Game.DP_PART));
					p.x = sp.x + (Seed.randVfx() * 2 - 1) * sp.ray;
					p.y = sp.y + (Seed.randVfx() * 2 - 1) * sp.ray;
					p.setScale(50 + Seed.randVfx() * 100);
					p.fadeType = 0;
					p.timer = 10 + Seed.randVfx() * 10;
					return;
				} else {
					var d = o.dist - (sp.ray + ray);
					var a = getAng(sp);
					setWaypoint({
						x: x + Cs.cos(a) * d,
						y: y + Cs.sin(a) * d,
						ray: null
					});
					return;
				}
			}
		}
	}

	override function findTrg():Alien {
		return null;
	}

	override function attack(trg:Alien) {}
}

class Jeep extends Ally {
	public function new() {
		type = 3;
		super();
		va = 0.13;
		ca = 0.15;
		ray = 20;
		tol = 36;
		accel = 0.1;
		speedMax = 6;
		mass = 0.1;
		hpMax = 70;
		armor = 1;
		range = 80;
		damage = 12;
		rate = 14;
		swivel = 3.14;
		flWalk = false;
		var t = turret();
		if (t != null)
			t.scripted = true;
	}

	function turret():Clip {
		var tur = skin != null ? skin.getClip("tur") : null;
		return tur != null ? tur.getClip("t") : null;
	}

	override function faceTrg(trg:Alien) {
		var tur = turret();
		if (tur == null)
			return;
		tur.scripted = true;
		var pos = getTurretPos();
		var a = 3.14 + trg.getAng(pos);
		var tr = Cs.hMod(a - angle, 3.14) / 0.0174;

		var dr = Cs.hMod(tr - tur._rotation, 180);
		tur._rotation += Cs.mm(-Math.abs(dr), dr * 0.3 * Timer.tmod, Math.abs(dr));
	}

	override function attack(trg:Alien) {
		super.attack(trg);

		var pos = getTurretPos();
		var tur = turret();
		var a = ((tur != null ? tur._rotation : 0) + root._rotation) * 0.0174;
		if (tur != null)
			tur.play();

		for (i in 0...2) {
			var mc = Cs.game.dm.add(new Clip("partExploGun"), Game.DP_PART);
			mc._x = pos.x;
			mc._y = pos.y;
			mc._rotation = a / 0.0174;
			mc.updateState();
		}
	}

	function getTurretPos():{x:Float, y:Float} {
		return {
			x: x - Cs.cos(angle) * 14,
			y: y - Cs.sin(angle) * 14
		};
	}

	override public function setWaypoint(pos:Dynamic) {
		skin.gotoAndPlay("run");
		super.setWaypoint(pos);
	}

	override function reachWp() {
		skin.gotoAndPlay("stop");
		super.reachWp();
	}

	override function die(ba:Null<Float>) {
		super.die(ba);

		var r = 25;
		var mc = Cs.game.dm.add(new Clip("partOnde"), Game.DP_PART);
		mc._x = x;
		mc._y = y;
		mc._xscale = r * 2;
		mc._yscale = mc._xscale;
		mc.updateState();

		mc = Cs.game.dm.add(new Clip("partExplosion"), Game.DP_PART);
		mc._x = x;
		mc._y = y;
		mc._xscale = r * 1.7;
		mc._yscale = mc._xscale;
		mc.updateState();

		var frame = 1;
		while (true) {
			var a = Seed.randVfx() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var dist = Seed.randVfx() * ray;
			var speed = (dist / ray) * 8;
			var sp = new Gibs(Cs.game.dm.add(new Clip("partJeep"), Game.DP_PART));
			sp.x = x + ca * dist;
			sp.y = y + sa * dist;
			sp.z = 8 - (dist / ray) * 6;
			sp.vx = ca * speed;
			sp.vy = sa * speed;
			sp.vz = sp.z * 0.8;
			sp.timer = 40 + Seed.randVfx() * 30;
			sp.wz = 0.2 + Seed.randVfx() * 0.4;
			sp.vr = (Seed.randVfx() * 2 - 1) * 16;
			sp.frict = 0.94;
			sp.root._rotation = Seed.randVfx() * 360;
			(cast sp.root : Clip).gotoAndStop(frame);

			frame++;
			if (frame > sp.root._totalframes)
				break;
		}
	}
}

// ---------------------------------------------------------------- Alien: the monsters
class Alien extends Arrow {
	var range:Float;
	var view:Float;
	var damage:Float;
	var rate:Float;
	var cd:Float;

	var score:Int;

	public var value:Float;

	var ma:Null<Float>;

	public function new() {
		Cs.game.bList.push(this);
		Cs.game.bounceList.push(this);
		super(Cs.game.dm.add(new Clip("mcAlien"), Game.DP_UNITS));

		range = 5;
		damage = 0;
		rate = 1;
		view = 50;

		va = 1;
		ca = 0.3;
		ray = 10;
		tol = 10;

		score = Cs.C1;
		value = 0;

		cd = 0;
		frame = 0;
	}

	override function initSkin() {
		super.initSkin();
		shadow = Cs.game.dm.add(new Clip("mcAlienShadow"), Game.DP_SHADOW);
		shadow.gotoAndStop(type + 1);
	}

	override public function update() {
		super.update();
		if (cd >= 0)
			cd -= Timer.tmod;

		if (wp != null) {
			if (cd < 0) {
				var dist = getDist(wp);
				var wray:Float = wp.ray != null ? wp.ray : 0;
				if (dist > ray + wray + range * Timer.tmod) {
					if (Seed.rand() / Timer.tmod < 0.02)
						chooseTarget();
					follow();
				} else {
					var ta = getAng(wp);
					towardAngle(ta);
					if (ma == null || Cs.hMod(angle - ta, 3.14) < ma * Timer.tmod)
						attack();
				}
			}
		} else {
			if (cd < 0)
				chooseTarget();
		}
	}

	function attack() {
		frame = null;
		cd = rate;
		skin.gotoAndPlay("attack");
		(cast wp : Arrow).hit(damage, null);
	}

	function chooseTarget() {
		var first = Math.POSITIVE_INFINITY;
		for (al in Cs.game.aList) {
			var dist = getDist(al);
			if (dist < first) {
				first = dist;
				setWaypoint(al);
			}
		}
	}

	override public function kill() {
		Cs.game.bList.remove(this);
		Cs.game.bounceList.remove(this);
		Cs.game.danger -= value;
		super.kill();
	}

	override function die(ba:Null<Float>) {
		var cc = 0.8;
		KadoKadeoManager.kkm.addScore(score);
		var max = ray;

		var i = 0;
		while (i < max) {
			var p = new Part(Cs.game.dm.add(new Clip("partBlood"), Game.DP_GROUND));
			var a = Seed.randVfx() * 6.28;
			if (ba != null) {
				a = ba + (Seed.randVfx() * 2 - 1);
			}
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			p.x = x + ca * ray * cc;
			p.y = y + sa * ray * cc;
			if (i < max * 0.4) {
				p.vx = ca * 3;
				p.vy = sa * 3;
				p.frict = 0.5;
				p.timer = 40 + Seed.randVfx() * 10;
				p.setScale((100 + Seed.randVfx() * 100) * ray * 0.08);
			} else {
				var sp = 1 + Seed.randVfx() * 5;
				p.vx = ca * sp;
				p.vy = sa * sp;
				p.timer = 6 + Seed.randVfx() * 10;
				p.setScale(20 + Seed.randVfx() * 60);
				p.fadeType = 0;
			}
			(cast p.root : Clip).gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._rotation = Seed.randVfx() * 360;
			i++;
		}

		Cs.game.stats.k[type]++;

		super.die(ba);
	}

	function throwGibs(size:Float, ba:Null<Float>) {
		var a = (ba != null ? ba : 0) + (Seed.randVfx() * 2 - 1) * 0.8;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		var dist = Seed.randVfx() * ray;
		var speed = (dist / ray) * 8;
		var sp = new Gibs(null);
		sp.x = x + ca * dist;
		sp.y = y + sa * dist;
		sp.z = 8 - (dist / ray) * 6;
		sp.vx = ca * speed;
		sp.vy = sa * speed;
		sp.vz = sp.z;
		sp.setScale(size * 0.5 + Seed.randVfx() * size);
		sp.timer = 30 + Seed.randVfx() * 20;
		sp.wz = 0.2 + Seed.randVfx() * 0.4;
		sp.vr = (Seed.randVfx() * 2 - 1) * 16;
		sp.frict = 0.94;
		sp.root._rotation = Seed.randVfx() * 360;
		(cast sp.root : Clip).gotoAndStop(Seed.randomVfx(sp.root._totalframes) + 1);
	}

	function spawnBonus() {
		var type = 0;
		var rnd = Seed.rand();
		switch (Cs.GAME_MODE) {
			case 0:
				if (rnd < 0.01) {
					type = 4;
				} else if (rnd < 0.05) {
					type = 2;
				} else if (rnd < 0.15) {
					type = 3;
				} else if (rnd < 0.35) {
					type = 1;
				}
			case 1:
				if (rnd < 0.05) {
					type = 2;
				} else if (rnd < 0.25) {
					type = 1;
				}
		}
		var sp = new Sprite(bonusClip(type));
		sp.x = x;
		sp.y = y;
		Cs.game.bonusList.push({sp: sp, timer: 300, type: type});
	}

	function spawnTroup() {
		var type = 10;
		var rnd = Seed.rand();
		if (rnd < 0.08) {
			type = 13;
		} else if (rnd < 0.25) {
			type = 12;
		} else if (rnd < 0.5) {
			type = 11;
		}
		var sp = new Sprite(bonusClip(type));
		sp.x = x;
		sp.y = y;
		Cs.game.bonusList.push({sp: sp, timer: 300, type: type});
	}

	// mcBonus on frame type+1 (the score bonuses have their own clip: their colour says their value)
	static function bonusClip(type:Int):Clip {
		if (type < 3)
			return Cs.game.dm.add(new Clip("mcBonus" + (type + 1)), Game.DP_BONUS);
		var c = Cs.game.dm.add(new Clip("mcBonus"), Game.DP_BONUS);
		c.gotoAndStop(type + 1);
		return c;
	}
}

class Runner extends Alien {
	public function new() {
		type = 0;
		super();
		range = 5;
		damage = 0.4;
		rate = 5;
		view = 50;
		va = 1;
		ca = 0.3;
		ray = 10;
		tol = 10;
		hpMax = 7;
		accel = 0.2;
		speedMax = 3.5;
		score = Cs.C15;
		value = 1;
	}
}

class Tanker extends Alien {
	public function new() {
		type = 1;
		super();
		range = 11;
		damage = 3;
		rate = 12;
		view = 50;
		va = 0.2;
		ca = 0.2;
		ray = 20;
		tol = 10;
		hpMax = 61;
		accel = 0.1;
		speedMax = 1.5;
		mass = 0.2;
		score = Cs.C250;
		value = 5;
	}

	override function die(ba:Null<Float>) {
		throwGibs(200, ba);
		for (i in 0...3)
			throwGibs(100, ba);

		if (Seed.rand() < 0.1 + Cs.GAME_MODE * 0.3) {
			spawnBonus();
		} else {
			if (Cs.GAME_MODE == 1 && Seed.rand() < Cs.RENFORT_STATS[0]) {
				spawnTroup();
				if (Cs.RENFORT_STATS.length > 1)
					Cs.RENFORT_STATS.shift();
			}
		}
		super.die(ba);
	}
}

class Octopus extends Alien {
	public function new() {
		type = 2;
		super();
		range = 4;
		damage = 6;
		rate = 20;
		view = 50;
		va = 0.1;
		ca = 0.1;
		ray = 29;
		tol = 10;
		hpMax = 360;
		accel = 0.1;
		speedMax = 0.7;
		mass = 0;
		score = Cs.C1500;
		value = 18;
		armor = 1;
		ma = 0.2;
	}

	override function die(ba:Null<Float>) {
		for (i in 0...4)
			throwGibs(300, ba);
		for (i in 0...12)
			throwGibs(180, ba);
		spawnBonus();
		super.die(ba);
	}

	// a soldier is swallowed: the instance `ally` of the attack shows him (frame 2, 3, 4: his colour); a jeep is bitten
	override function attack() {
		var sp:Arrow = cast wp;
		if (sp.type < 3) {
			frame = null;
			cd = 30;
			skin.gotoAndPlay("attack");
			var ally = skin.getClip("ally");
			if (ally != null)
				ally.gotoAndStop(sp.type + 2);
			sp.kill();
		} else {
			super.attack();
			var ally = skin.getClip("ally");
			if (ally != null)
				ally.stop();
		}
	}
}

class Executor extends Alien {
	var baseRay:Float;

	public function new() {
		type = 5;
		super();
		range = 2;
		damage = 40;
		rate = 120;
		view = 50;
		va = 0.4;
		ca = 0.2;
		ray = 12;
		tol = 10;
		hpMax = 200;
		accel = 1;
		speedMax = 3;
		mass = 0.3;
		score = Cs.C2000;
		value = 8;
		armor = -1;
		baseRay = ray;
	}

	override public function update() {
		super.update();
		if (cd > 0) {
			vx *= 0.1;
			vy *= 0.1;
		} else {
			if (Seed.randVfx() / Timer.tmod < 0.1) {
				var p = new Part(Cs.game.dm.add(new Clip("partSmallTache"), Game.DP_GROUND));
				p.x = x + (Seed.randVfx() * 2 - 1) * 10;
				p.y = y + (Seed.randVfx() * 2 - 1) * 10;
				p.setScale(50 + Seed.randVfx() * 150);
				p.timer = 30 + Seed.randVfx() * 20;
				p.fadeType = 0;
			}
		}
	}

	override function die(ba:Null<Float>) {
		var max = 10;
		for (i in 0...max) {
			var p = new Part(Cs.game.dm.add(new Clip("partGel"), Game.DP_PART));
			var a = Seed.randVfx() * 6.28;
			if (ba != null) {
				a = ba + (Seed.randVfx() * 2 - 1);
			}
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var cc = 0.8 + Seed.randVfx() * 0.8;
			p.x = x + ca * ray * cc;
			p.y = y + sa * ray * cc;
			var sp = 1 + Seed.randVfx() * 6;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.timer = 10 + Seed.randVfx() * 10;
			p.setScale(80 + Seed.randVfx() * 40);
			p.fadeType = 0;
			(cast p.root : Clip).gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._rotation = Seed.randVfx() * 360;
		}
		var sp = new Part(Cs.game.dm.add(new Clip("partTache"), Game.DP_GROUND));
		sp.x = x;
		sp.y = y;
		sp.root._rotation = 180 + (ba != null ? ba : 0) / 0.0174;
		sp.timer = 80 + Seed.randVfx() * 60;

		ray = 0;
		super.die(ba);
	}

	override function attack() {
		frame = null;
		cd = rate;
		var al:Arrow = cast wp;
		skin.gotoAndStop(al.type + 51);
		x = al.x;
		y = al.y;
		root._rotation = al.root._rotation;
		ray = al.ray;
		al.kill();
		// (moved onto its prey: no slide)
		root._x = x;
		root._y = y;
		root.updateState();
	}

	override public function hit(damage:Float, ba:Null<Float>) {
		var p = new Part(Cs.game.dm.add(new Clip("partGel"), Game.DP_PART));
		var a = Seed.randVfx() * 6.28;
		if (ba != null) {
			a = ba + (Seed.randVfx() * 2 - 1);
		}
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		var cc = 0.8 + Seed.randVfx() * 0.6;
		p.x = x + ca * ray * cc;
		p.y = y + sa * ray * cc;
		var sp = 1 + Seed.randVfx() * 6;
		p.vx = ca * sp;
		p.vy = sa * sp;
		p.timer = 10 + Seed.randVfx() * 10;
		p.setScale(80 + Seed.randVfx() * 40);
		p.fadeType = 0;
		(cast p.root : Clip).gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
		p.root._rotation = Seed.randVfx() * 360;

		super.hit(damage, a);
	}
}
