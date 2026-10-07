package phagocytoz;

// (only the score popups: their timer is never set, they stay in Game.elements, even after their level)
class Element {
	var root:DisplayObject;

	public var x:Float;
	public var y:Float;
	public var timer:Null<Float>;

	var ray:Float;

	public function new(mc:DisplayObject, x = 0.0, y = 0.0) {
		Game.me.elements.push(this);
		root = mc;
		this.x = x;
		this.y = y;
		ray = 10;
		updatePos();
	}

	public function update() {
		if (timer != null) {
			timer--;
			if (timer < 0)
				kill();
		}
		updatePos();
	}

	public function updatePos() {
		var fc = Game.me.lvl.focus;
		var dx = Cell.ddx(x - fc.x);
		var dy = Cell.ddy(y - fc.y);

		root.moveWrapped(fc.x + dx, fc.y + dy, Level.WIDTH, Level.HEIGHT);
		root.visible = true;

		var ww = (Game.mcw * 0.5) / Game.me.lvl.scale;
		var hh = (Game.mch * 0.5) / Game.me.lvl.scale;
		root.visible = Math.abs(dx) - ray < ww && Math.abs(dy) - ray < hh;
	}

	public function kill() {
		Game.me.elements.remove(this);
		if (root.parent != null)
			root.parent.removeChild(root);
	}
}
