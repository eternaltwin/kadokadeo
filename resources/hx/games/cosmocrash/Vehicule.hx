package cosmocrash;

import cosmocrash.Cs.Num;
import cosmocrash.MC.Plans;

// Vehicule.hx of the original: an army vehicle (jeep, then tank once the difficulty passes 3600) driving on the
// ground and shooting at the hero when it is near
class Vehicule extends Element {
	public var flShoot:Bool;
	public var type:Int;
	public var sens:Int;
	public var tx:Null<Float>;
	public var cana:Float;

	public var canonSpeed:Float;
	public var canonDist:Float;
	public var cadence:Float;
	public var shotSpeed:Float;
	public var canonAngleLim:Float;

	public var cooldown:Float;
	public var width:Float;
	public var wray:Float;
	public var acc:Float;

	var wheels:Array<MC>;

	public var dm:Plans;
	public var car:MC;
	public var car2:MC;
	public var canon:MC;

	// Filt.glow(root, 2, 4, 0)
	var glow:FlashGlow;

	public function new() {
		super(Game.me.dm.empty(Game.DP_VEHICULE));
		dm = new Plans(root.clip, root);

		car = dm.attach("mcJeep", 2);
		car2 = dm.attach("mcJeep", 0);
		setType(Game.me.dif < 3600 ? 0 : 1);

		cooldown = 0;
		cana = -1.57;

		canon = dm.attach("mcCanon", 1);
		canon._x = width * 0.5;
		canon._y = -10;
		canon._rotation = cana / 0.0174;

		x = Game.me.getFarAwayX();
		tx = Seed.rand() * Cs.lw;
		vx = 0.5;

		frict = 0.95;
		Game.me.vehicules.push(this);
		glow = new FlashGlow(2, 2, 4, 0x000000);
		root.clip.filters = [glow];
	}

	public function setType(t:Int) {
		type = t;
		switch (type) {
			case 0:
				wray = 5;
				width = 20;
				acc = 0.05;
				canonSpeed = 0.05;
				cadence = 50;
				canonDist = 10;
				shotSpeed = 2.5;
				canonAngleLim = 1.2;
				initWheels(3);

			case 1:
				wray = 5;
				width = 18;
				acc = 0.1;
				canonSpeed = 0.1;
				cadence = 10;
				canonDist = 16;
				shotSpeed = 4;
				canonAngleLim = 1.8;
				initWheels(2);
		}

		car.gotoAndStop(type * 2 + 1);
		car2.gotoAndStop(type * 2 + 2);
	}

	public function initWheels(max:Int) {
		// WHEELS
		wheels = [];
		for (i in 0...max) {
			var mc = dm.attach("mcWheel", 1);
			mc._x = i / (max - 1) * width;
			wheels.push(mc);
		}
	}

	override function update() {
		flShoot = false;
		sens = vx > 0 ? 1 : -1;

		updateSkin();
		checkBehaviour();

		super.update();
	}

	// BEHAVIOUR
	public function checkBehaviour() {
		if (Game.me.hero == null) {
			move();
			return;
		}
		var hdx = Game.me.getHeroDX(x + width * 0.5);
		if (Math.abs(hdx) < 100) {
			var v = getNearestVehicule();
			if (v == null || (Math.abs(v.x - x) > 36 || !v.flShoot)) {
				shoot();
				return;
			}
		}
		move();
	}

	function shoot() {
		flShoot = true;

		var ty = y + canon._y;
		var dx = Game.me.getHeroDX(x + canon._x);
		var dy = Game.me.hero.y - ty;

		var ta = Cs.q(Math.atan2(dy, dx));
		var da = Num.hMod(ta - cana, 3.14);
		var lim = canonSpeed;
		cana += Num.mm(-lim, da * 0.2, lim);

		recalCanon();

		if (cooldown-- > 0)
			return;

		cooldown = cadence;

		var smc = canon.sub("smc");
		if (smc != null)
			smc.play();
		var p = canonSmcCoord();

		var ca = Cs.q(Math.cos(cana));
		var sa = Cs.q(Math.sin(cana));
		var shot = new Shot();
		#if debug
		Game.me.stats.shots++;
		#end
		shot.x = p.x;
		shot.y = p.y;
		shot.vx = ca * shotSpeed;
		shot.vy = sa * shotSpeed;
		shot.root.gotoAndStop(type + 1);

		shot.updatePos();
	}

	// Geom.getParentCoord(canon.smc, root): canon.smc (Data.CANON_SMC) turned by canon._rotation, then moved by canon and
	// by the vehicle (root._x / _y: its position of the last frame)
	function canonSmcCoord():{x:Float, y:Float} {
		var x = Data.CANON_SMC[0];
		var y = Data.CANON_SMC[1];
		var r = canon._rotation;
		if (r != 0) {
			var dist = Math.sqrt(x * x + y * y);
			var a = Cs.q(Math.atan2(y, x));
			a += r * 0.0174;
			x = Cs.q(Math.cos(a)) * dist;
			y = Cs.q(Math.sin(a)) * dist;
		}
		x *= canon._xscale * 0.01;
		y *= canon._yscale * 0.01;
		x += canon._x;
		y += canon._y;
		x *= root._xscale * 0.01;
		y *= root._yscale * 0.01;
		x += root._x;
		y += root._y;
		return {x: x, y: y};
	}

	function recalCanon() {
		var csta = car._rotation * 0.0174 - 1.57;
		var lim = canonAngleLim;
		cana = Num.mm(csta - lim, cana, csta + lim);
		canon._rotation = cana / 0.0174;
	}

	function move() {
		if (tx == null || x == null) {
			return;
		}
		var dx = Num.hMod(tx - x, Cs.lw * 0.5);
		if (Math.abs(dx) < 100) {
			tx = Seed.rand() * Cs.lw;
		} else {
			vx += Math.abs(dx) / dx * acc;
		}
	}

	public function updateSkin() {
		var wx = x;
		y = Game.me.getGY(x) - wray;
		var ys = 0.0;

		var id = 0;

		var an:Null<Float> = null;

		for (mc in wheels) {
			wx = x + mc._x;
			var wy = Game.me.getGY(wx);
			mc._y = (wy - wray) - y;
			ys += mc._y;
			id++;
			if (id == wheels.length)
				an = Cs.q(Math.atan2(mc._y, mc._x));
		}

		car._rotation = an / 0.0174;
		recalCanon();

		an -= 1.57;
		car._x = width * 0.5;
		car._y = ys / wheels.length;
		canon._x = car._x + Cs.q(Math.cos(an)) * canonDist;
		canon._y = car._y + Cs.q(Math.sin(an)) * canonDist;

		car2._x = car._x;
		car2._y = car._y;
		car2._rotation = car._rotation;
	}

	public function getNearestVehicule():Vehicule {
		var trg = null;
		var dist = 9999.0;
		for (v in Game.me.vehicules) {
			var d = Math.abs(x - v.x);
			if (d < dist && v != this) {
				dist = d;
				trg = v;
			}
		}
		return trg;
	}
}
