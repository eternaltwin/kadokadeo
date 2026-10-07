package aquasplash;

import aquasplash.Game.Pos;

class Drop extends Phys {
	public static var SPEED = /*2.7*/ 2.3;

	public var d:Int;
	public var from:Pos;
	public var done:Bool;
	public var f:Int;

	public function new(pos:Pos, dir:Int) {
		super(Game.me.dm.attach("drop", Game.DP_DROP));
		d = dir;
		from = pos;
		done = false;

		root._alpha = Cs.ALPHA_SLIME;
		root._rotation = dir * 90;
		// root._visible = false ;

		var coords = Cs.getPos(from, true);
		x = coords.x;
		y = coords.y;

		var v = Cs.dir[d];
		vx = v[0] * SPEED;
		vy = v[1] * SPEED;
		frict = 1.03;
		f = 0;

		Game.me.drops.push(this);
	}

	override public function update() {
		if (done)
			return;

		super.update();

		var s = onSlime();
		if (s != null) {
			onTouch(s);
			return;
		}

		if (outOfBounds())
			onTouch(null);
	}

	public function onTouch(s:Slime) {
		done = true;
		if (s != null)
			s.growing();
		else
			absorbed();
		kill();
	}

	function absorbed() { // animation for slime absorb / burp
		var mc = Game.me.dm.attach("splash", Game.DP_ANIM);
		mc.removeAt = 5;
		mc._x = root._x;
		mc._y = root._y;
		mc._rotation = d * 90;

		// ### TODO animation
	}

	public function onSlime():Slime { // return a slime or null
		for (s in Game.me.slimes) {
			if (!onWay(s.pos))
				continue;

			if (hitTest(s) && (s.grow > 0 || s.bonus))
				return s;
		}
		return null;
	}

	// root.hitTest(s.mc): Flash compares the bounding boxes of the two clips on the stage (Data: the bounds of the
	// drop picture and of the slime picture shown, measured in the SWF), the drop rotated by a multiple of 90 degrees
	function hitTest(s:Slime):Bool {
		var b = Data.DROP_BOUNDS;
		var x0, x1, y0, y1;
		switch (d) {
			case Cs.EAST:
				x0 = b[0]; x1 = b[1]; y0 = b[2]; y1 = b[3];
			case Cs.SOUTH:
				x0 = -b[3]; x1 = -b[2]; y0 = b[0]; y1 = b[1];
			case Cs.WEST:
				x0 = -b[1]; x1 = -b[0]; y0 = -b[3]; y1 = -b[2];
			default:
				x0 = b[2]; x1 = b[3]; y0 = -b[1]; y1 = -b[0];
		}
		var r = s.mc.stageBounds();
		return root._x + x0 <= r[1] && r[0] <= root._x + x1 && root._y + y0 <= r[3] && r[2] <= root._y + y1;
	}

	function onWay(p:Pos) {
		switch (d) {
			case Cs.EAST:
				return p.y == from.y && p.x > from.x;
			case Cs.SOUTH:
				return p.x == from.x && p.y > from.y;
			case Cs.WEST:
				return p.y == from.y && p.x < from.x;
			case Cs.NORTH:
				return p.x == from.x && p.y < from.y;
			default:
				return false;
		}
	}

	public function outOfBounds():Bool {
		if (root._x < Cs.BOARD_X_LIMIT)
			return true;
		else if (root._x > Cs.BOARD_X_LIMIT + Cs.BOARD_WIDTH * Cs.ZONE_SIZE)
			return true;
		else if (root._y < Cs.BOARD_Y_LIMIT)
			return true;
		else if (root._y > Cs.BOARD_Y_LIMIT + Cs.BOARD_HEIGHT * Cs.ZONE_SIZE)
			return true;
		return false;
	}

	override public function kill() {
		super.kill();
		Game.me.drops.remove(this);
	}

	public static function launch(pos:Pos) {
		for (i in 0...4) {
			var d = new Drop(pos, i);
		}
	}
}
