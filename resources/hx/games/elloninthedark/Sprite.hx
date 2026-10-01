package elloninthedark;

class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:ASprite;

	var placed:Bool;

	public function new(mc:ASprite) {
		root = mc;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		placed = false;
		root._x = KadoKadeoManager.I(-100);
		root._y = KadoKadeoManager.I(-100);
	}

	public function update() {
		updatePos();
	}

	public function kill() {
		root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
		if (!placed) {
			// first placement: no interpolation from the off-screen position
			placed = true;
			root.updateState();
		}
	}

	public function getDist(o:{x:Float, y:Float}) {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}) {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.atan2(dy, dx);
	}

	// UTILS
	public function isOut(m:Float) {
		return (x < -m || x > Cs.mcw + m || y < -m || y > Cs.GL + m);
	}
}
