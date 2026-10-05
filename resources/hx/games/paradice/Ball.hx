package paradice;

// Ball.mt of the original: a ball of the grid (or carried by the penguins), x / y its square (y = 0 just above the
// line, the stack grows upwards)
class Ball {
	// (8 neighbours, but [-1, -0] repeats [-1, 0] and [-1, -1] is missing: the ice below on the left is never freed)
	static var BDIR = [[1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -0], [0, -1]];

	// (null until the ball enters the grid: a carried ball has no square, Flash's undefined)
	public var x:Null<Int>;
	public var y:Null<Int>;

	public var gid:Null<Int>;
	public var type:Int;
	public var col:Null<Int>;

	public var dy:Float;
	public var root:MC;
	public var cl:MC;

	public var flIce:Bool;

	public function new() {
		flIce = false;
		dy = 0;
		root = Cs.game.dm.attach("ball", Game.DP_BALL);
		Cs.game.bList.push(this);
		// (Math.random(): only the picture changes, the visual random)
		root._alpha = 45 + Seed.randVfx() * 45;
	}

	public function updatePos() {
		root._x = Cs.ML + (x + 0.5) * Cs.SQ;
		root._y = (Cs.MD - (y + 0.5) * Cs.SQ) + dy;
	}

	public function setPos(nx:Int, ny:Int) {
		Cs.game.setCell(x, y, null);
		x = nx;
		y = ny;
		Cs.game.setCell(x, y, this);
	}

	//
	public function checkBlast() {
		for (i in 0...BDIR.length) {
			var nx = x + BDIR[i][0];
			var ny = y + BDIR[i][1];
			var b = Cs.game.cell(nx, ny);
			if (b != null && b.flIce) {
				b.unIce();
			}
		}
	}

	//

	public function genClone() {
		cl = Cs.game.dm.attach("ball", Game.DP_BALL);
		cl._x = root._x;
		cl._y = root._y;
		setSkin(cl);
	}

	public function removeClone() {
		if (cl != null)
			cl.removeMovieClip();
		cl = null;
	}

	public function unIce() {
		flIce = false;
		setSkin(root);
		var max = 6;
		for (i in 0...max) {
			var p = new Part(Cs.game.dm.attach("partIceBlast", Game.DP_PART));
			var a = (i / max) * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = 2;
			var ray = 6;
			p.x = Cs.ML + (x + 0.5) * Cs.SQ + ca * ray;
			p.y = Cs.MD - (y + 0.5) * Cs.SQ + sa * ray;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.timer = 20 + Seed.randVfx() * 5;
			p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._rotation = a / 0.0157;
			p.fadeType = 0;
		}
	}

	public function setSkin(mc:MC) {}

	public function explode() {
		kill();
	}

	public function kill() {
		removeClone();
		Cs.game.bList.remove(this);
		Cs.game.setCell(x, y, null);
		root.removeMovieClip();
	}
}
