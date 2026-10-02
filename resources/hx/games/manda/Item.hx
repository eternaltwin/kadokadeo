package manda;

class Item extends Movable {
	public var id:Int;
	public var time:Float;

	static var rect = [0.0, 0, 0, 0];

	public function new(id:Int, mc:ItemMc, time:Float) {
		super(mc);
		this.id = id;
		this.time = time;
		rndPos();
	}

	public function update():Bool {
		move();
		if (!isMoving())
			time -= Timer.deltaT;
		if (time > 0)
			return true;
		mc.goPlay(ItemMc.DISPARAIT);
		return false;
	}

	function rndPos() {
		var x, y;
		var ntrys = 200;
		do {
			x = Seed.random(Cs.WIDTH);
			y = Seed.random(Cs.HEIGHT);
		} while (!inBounds(x, y) && --ntrys > 0);
		mc._x = x;
		mc._y = y;
	}

	// the picture (bounds of f without its scale) inside the walls
	override function inBounds(x:Float, y:Float):Bool {
		mc.fRect(rect);
		var lv = Cs.LEVEL_BOUNDS;
		return (x + rect[0] > lv.left && y + rect[1] > lv.top && x + rect[2] < lv.right && y + rect[3] < lv.bottom);
	}

	public function destroy() {
		mc.remove();
	}
}
