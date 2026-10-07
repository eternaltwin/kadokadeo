package oursouinvader;

// Sprite.mt of the original
class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:MC;
	public var scale:Float;

	// port: the clip is still where Sprite.new left it, off the screen (see MC.teleport)
	var placed:Bool = false;

	public function new(mc:MC) {
		root = mc;
		root.obj = this;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		root._x = -100;
		root._y = -100;
		scale = 100;
	}

	public function setScale(n:Float) {
		scale = n;
		root._xscale = n;
		root._yscale = n;
	}

	public function update() {
		root._x = x;
		root._y = y;
		firstPlace();
	}

	public function kill() {
		// (root is null once a monster explodes or the hero dies: its clip plays "die" and removes itself)
		if (root != null)
			root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
		firstPlace();
	}

	inline function firstPlace() {
		if (!placed) {
			placed = true;
			root.teleport();
		}
	}

	public function getDist(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.atan2(dy, dx);
	}

	// (var a = getAng(o): computed and unused, not ported)
	public function toward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		x += Cs.mm(-lim, dx * c, lim);
		y += Cs.mm(-lim, dy * c, lim);
	}

	// UTILS
	public function isOut(m:Float):Bool {
		return (x < -m || x > Cs.mcw + m || y < -m || y > Cs.mch + m);
	}
}
