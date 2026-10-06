package cyclopean;

class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:MC;

	public function new(mc:MC) {
		root = mc;
		root.obj = this;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		root._x = -1000;
		root._y = -1000;
	}

	public function update():Void {
		root._x = x;
		root._y = y;
	}

	public function kill():Void {
		root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos():Void {
		root._x = x;
		root._y = y;
	}

	public function getDist(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Cs.atan2(dy, dx);
	}
}
