package quadrikolor;

typedef Bounds = {
	xmin:Float,
	ymin:Float,
	xmax:Float,
	ymax:Float,
	coef:Float
};

// Physics.mt: continuous time collisions under a friction (the speed is multiplied by `friction` per time unit): the
// next collision is computed, every object moves along its exact path until then, and the collision is solved.
// Resources: gamasutra.com/features/20000208/lander_01.htm, gamasutra.com/features/20020118/vandenhuevel_01.htm
//
// Port: Flash compares null / NaN as false (`c < o.col` with c = null), JS takes null for 0: tested explicitly. The
// results of pow / log are rounded (Const.q): the same on every browser.
class Physics {
	public var friction:Float;
	public var objs:Array<PhysicObj>;
	public var bounds:Bounds;

	var next_col:Float;
	var elapsed:Float;
	var next_obj:PhysicObj;

	public function new(o:Array<PhysicObj>, f:Float, b:Bounds) {
		objs = o;
		friction = f;
		bounds = b;
		elapsed = 0;
	}

	public function stop() {
		updateSpeeds(elapsed);
	}

	public function start() {
		compute();
	}

	public function speed(o:PhysicObj):Float {
		var f = Const.q(Math.pow(friction, elapsed));
		var dx = o.dx * f;
		var dy = o.dy * f;
		return Math.sqrt(dx * dx + dy * dy);
	}

	function updateSpeeds(t:Float) {
		var f = Const.q(Math.pow(friction, t));
		for (i in 0...objs.length) {
			var o = objs[i];
			o.dx *= f;
			o.dy *= f;
		}
	}

	function timeToDist(d:Float):Null<Float> {
		var t = Const.q(Math.log(d * (friction - 1) + 1) / Math.log(friction));
		if (t < 0 || Math.isNaN(t)) // NaN = not reachable
			return null;
		return t;
	}

	function test(o1:PhysicObj, o2:PhysicObj):Null<Float> {
		var dx = o2.x - o1.x;
		var dy = o2.y - o1.y;
		var dist = Math.sqrt(dx * dx + dy * dy);
		var r = o1.r + o2.r;

		// relative movement
		var mx = o1.dx - o2.dx;
		var my = o1.dy - o2.dy;
		var md = Math.sqrt(mx * mx + my * my);

		mx /= md;
		my /= md;

		// if negative dot product, they are moving different way ((d <= 0) in Flash: true with NaN, both still)
		var d = mx * dx + my * dy;
		if (!(d > 0))
			return null;

		var f = dist * dist - d * d;
		var rr = r * r;
		// minimal distance will still not collide
		if (!(f < rr))
			return null;

		var col_dist = d - Math.sqrt(rr - f);

		// translate into time units
		return timeToDist(col_dist / md);
	}

	function testBounds(o:PhysicObj) {
		if (o.dx < 0) {
			var c = timeToDist((bounds.xmin - o.x + o.r) / o.dx);
			if (c != null && c < o.col) {
				o.col = c;
				o.target = null;
			}
		} else if (o.dx > 0) {
			var c = timeToDist((bounds.xmax - o.x - o.r) / o.dx);
			if (c != null && c < o.col) {
				o.col = c;
				o.target = null;
			}
		}
		if (o.dy < 0) {
			var c = timeToDist((bounds.ymin - o.y + o.r) / o.dy);
			if (c != null && c < o.col) {
				o.col = c;
				o.target = null;
			}
		} else if (o.dy > 0) {
			var c = timeToDist((bounds.ymax - o.y - o.r) / o.dy);
			if (c != null && c < o.col) {
				o.col = c;
				o.target = null;
			}
		}
	}

	function compute() {
		for (i in 0...objs.length)
			objs[i].col = Math.POSITIVE_INFINITY;
		for (i in 0...objs.length) {
			var o1 = objs[i];
			for (j in i + 1...objs.length) {
				var o2 = objs[j];
				var c = test(o1, o2);
				if (c != null) {
					if (c < o1.col) {
						o1.col = c;
						o1.target = o2;
					}
					// (o2 takes the collision even when it already had an earlier one: kept)
					o2.col = c;
					o2.target = o1;
				}
			}
			if (bounds != null)
				testBounds(o1);
		}

		elapsed = 0;
		next_col = Math.POSITIVE_INFINITY;
		next_obj = null;
		for (i in 0...objs.length) {
			var o = objs[i];
			if (o.col < next_col) {
				next_col = o.col;
				next_obj = o;
			}
			o.sx = o.x;
			o.sy = o.y;
		}
	}

	function collideBounds(o:PhysicObj) {
		var e = 1 / 100000;
		var x = 0;
		var y = 0;

		if (Math.abs(o.x - bounds.xmin - o.r) < e)
			x = 1;
		else if (Math.abs(o.x - bounds.xmax + o.r) < e)
			x = -1;
		else if (Math.abs(o.y - bounds.ymin - o.r) < e)
			y = 1;
		else if (Math.abs(o.y - bounds.ymax + o.r) < e)
			y = -1;
		else {
			// (Log.trace("NO COLLIDE FOUND ! "...))
			return;
		}

		var d = (1 + bounds.coef) * (x * o.dx + y * o.dy);
		o.dx -= d * x;
		o.dy -= d * y;
	}

	function collide(o1:PhysicObj, o2:PhysicObj) {
		var dx = o1.x - o2.x;
		var dy = o1.y - o2.y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		dx /= dist;
		dy /= dist;

		var a1 = o1.dx * dx + o1.dy * dy;
		var a2 = o2.dx * dx + o2.dy * dy;

		var p = (2 * (a1 - a2)) / (o1.mass + o2.mass);

		o1.dx -= p * o2.mass * dx;
		o1.dy -= p * o2.mass * dy;

		o2.dx += p * o1.mass * dx;
		o2.dy += p * o1.mass * dy;
	}

	public function update(t:Float) {
		var t_sim = Math.min(t, next_col);
		var iscol = (next_col <= t);
		elapsed += t_sim;
		next_col -= t_sim;
		var coef = Const.q((Math.pow(friction, elapsed) - 1) / (friction - 1));
		for (i in 0...objs.length) {
			var o = objs[i];
			o.x = o.sx + o.dx * coef;
			o.y = o.sy + o.dy * coef;
			// (Log.trace("OUT-BOUNDS ! ") when an object is out of the bounds without a collision)
		}
		if (iscol) {
			t -= t_sim;
			stop();
			if (next_obj.target == null)
				collideBounds(next_obj);
			else
				collide(next_obj, next_obj.target);
			next_obj.onCollide(next_obj.target);
			// (null.onCollide(): nothing in Flash)
			if (next_obj.target != null)
				next_obj.target.onCollide(next_obj);
			start();
			update(t);
		}
	}
}
