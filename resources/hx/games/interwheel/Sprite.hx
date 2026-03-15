package interwheel;

class Sprite {
	public var x:Float;
	public var y:Float;

	var root:ASprite;

	public function new(mc) {
		root = mc;
		untyped cast(root).obj = this;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		root._x = -1000;
		root._y = -1000;
	}

	public function update() {
		root._x = x;
		root._y = y;
	}

	public function kill() {
		root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
	}

	public function getDist(o) {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}) {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.atan2(dy, dx);
	}

	public function toward(o, c, lim) {
		var a = getAng(o);
		var dx = o.x - x;
		var dy = o.y - y;
		x += Cs.mm(-lim, dx * c, lim);
		y += Cs.mm(-lim, dy * c, lim);
	}

	// UTILS
	public function isOut(m) {
		return (x < -m || x > Cs.mcw + m || y < -m || y > Cs.mch + m);
	}
}
