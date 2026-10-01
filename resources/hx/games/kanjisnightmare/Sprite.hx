package kanjisnightmare;

class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:ASprite;
	public var dead:Bool;

	var placed:Bool;

	public function new(mc:ASprite) {
		root = mc;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		placed = false;
		dead = false;
		if (root != null) {
			root._x = -1000;
			root._y = -1000;
		}
	}

	public function update() {
		updatePos();
	}

	public function kill() {
		dead = true;
		if (root != null)
			root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos() {
		if (root == null)
			return;
		root._x = x;
		root._y = y;
		if (!placed) {
			// first placement: no interpolation from the hidden position
			placed = true;
			root.updateState();
		}
	}

	// the display changed (new clip): placed again without interpolation
	public function setRoot(mc:ASprite) {
		root = mc;
		placed = false;
		updatePos();
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

	public function toward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		x += Cs.mm(-lim, dx * c, lim);
		y += Cs.mm(-lim, dy * c, lim);
	}

	// UTILS
	public function isOut(m:Float):Bool {
		var px = x + Cs.game.map._x;
		var py = y + Cs.game.map._y;
		return (px < -m || px > Cs.mcw + m || py < -m || py > Cs.mch + m);
	}
}
