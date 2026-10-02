package minirace;

import minirace.Cs.CheckPoint;

// follows the checkpoints of the track (cars, light streaks)
class Tracker extends Phys {
	public static inline var REACH = 20;

	var flControl:Bool;
	// random offsets of the waypoints: visual only (light streaks), gameplay otherwise
	var vfx:Bool;

	public var cpi:Int;
	public var wp:CheckPoint;

	public var angle:Float;
	public var decalMax:Float;
	public var speed:Float;
	public var da:Float;
	public var groundFrict:Float;

	public var turnCoef:Float;
	public var turnLimit:Float;

	// root._rotation as the Flash player gives it back (the collision box of the cars is built from it)
	public var rot:Float;

	function new(mc:ASprite) {
		super(mc);
		flControl = false;
		vfx = false;
		angle = 0;
		speed = 0;
		da = 0;
		decalMax = 14;
		groundFrict = 0.95;
		rot = 0;

		cpi = 0;

		turnCoef = 0.1;
		turnLimit = 0.8;
	}

	function move() {
		speed *= Math.pow(groundFrict, Timer.tmod);

		var wpx = wp.x;
		var wpy = wp.y;

		// (chronoTimer is NaN before the first lap: no control)
		if (flControl && Cs.game.chronoTimer > 14) {
			var dist = 12;

			var cx = Cs.mm(0, Cs.game.mouseX() / Cs.mcw, 1);
			var cy = Cs.mm(0, Cs.game.mouseY() / Cs.mch, 1);

			wpx += (cx * 2 - 1) * dist;
			wpy += (cy * 2 - 1) * dist;
		}

		var dx = wpx - x;
		var dy = wpy - y;
		var ta = Cs.qt(Math.atan2(dy, dx));
		da = Cs.hMod(ta - angle, 3.14);

		var lim = turnLimit;
		angle += Cs.mm(-lim, da * turnCoef, lim) * Timer.tmod;
		vx = Cs.qt(Math.cos(angle)) * speed;
		vy = Cs.qt(Math.sin(angle)) * speed;

		setRotation(angle / 0.0174);

		angle = Cs.hMod(angle, 3.14);

		// (Phys.update, not the update of the subclass)
		super.update();

		if (Math.sqrt(dx * dx + dy * dy) < REACH) {
			nextWayPoint();
		}
	}

	function setRotation(r:Float) {
		rot = Cs.normRot(r);
		root._rotation = rot;
	}

	// WAYPOINT
	function nextWayPoint() {
		setWayPoint((cpi + 1) % Cs.game.checkpoints.length);
	}

	public function setWayPoint(n:Int) {
		cpi = n;
		var c = Cs.game.checkpoints[cpi];
		var ray = ((vfx ? Seed.randVfx() : Seed.rand()) * 2 - 1) * decalMax;

		wp = {
			x: c.x + Cs.qt(Math.cos(c.a)) * ray,
			y: c.y + Cs.qt(Math.sin(c.a)) * ray,
			a: c.a
		}
	}

	public function goto(n:Int) {
		setWayPoint(n);
		x = wp.x;
		y = wp.y;
		angle = wp.a - 1.57;
	}
}
