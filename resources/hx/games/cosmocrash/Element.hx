package cosmocrash;

import cosmocrash.Cs.Num;

// Element.hx of the original: everything that moves on the map (hero, colonists, vehicles, shuttles, shots,
// particles). Its position is set by the code that creates it (undefined until then: NaN in a calculation, like Flash).
class Element {
	public var x:Null<Float>;
	public var y:Null<Float>;

	public var vx:Float;
	public var vy:Float;
	public var frict:Null<Float>;
	public var weight:Null<Float>;

	public var root:MC;

	public function new(mc:MC) {
		root = mc;
		vx = 0;
		vy = 0;
		Game.me.elements.push(this);
	}

	public function update() {
		if (weight != null)
			vy += weight;

		if (frict != null) {
			vx *= frict;
			vy *= frict;
		}

		x += vx;
		y += vy;

		updatePos();
	}

	public function updatePos() {
		if (x == null)
			return;
		x = Num.sMod(x, Cs.lw);
		root._x = Std.int(x);
		root._y = Std.int(y);
	}

	public function kill() {
		root.removeMovieClip();
		Game.me.elements.remove(this);
	}
}
