package interwheel;

class Element {
	public var flRemove:Bool;

	public var x:Float;
	public var y:Float;
	public var ray:Float;
	public var root:ASprite;

	public var skin:String;

	public function new() {
		flRemove = false;
	}

	public function update() {}

	public function attach() {
		root = Cs.game.dm.attach(skin, Game.DP_WHEEL);
		root._x = x;
		root._y = y;
	}

	public function detach() {
		if (root != null) {
			root.removeMovieClip();
			root = null;
		}
	}
}
