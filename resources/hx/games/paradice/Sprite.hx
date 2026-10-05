package paradice;

// Sprite.mt of the original
class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:MC;

	public function new(mc:MC) {
		root = mc;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		root._x = -100;
		root._y = -100;
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

	public function getDist(o:Sprite):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:Sprite):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.atan2(dy, dx);
	}

	// UTILS
	public function isOut(m:Float):Bool {
		return (x < -m || x > Cs.mcw + m || y < -m || y > Cs.mch + m);
	}
}
