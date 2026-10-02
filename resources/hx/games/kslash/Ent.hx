package kslash;

// a character of the grid: square (x, y), half of the square (cx, cy) and offset (dx, dy) from its middle
class Ent {
	public var root:Clip;

	public var flGround:Bool;
	public var flCol:Bool;
	public var flFreezeAnim:Bool;

	public var step:Int;
	public var sens:Int;

	public var x:Int;
	public var y:Int;
	public var cx:Int;
	public var cy:Int;
	public var dx:Float;
	public var dy:Float;

	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;

	public var weight:Float;
	public var friction:Null<Float>;

	public var nextAnim:String;

	// the clip is drawn where the code puts it (no interpolation from where it was): first placement, teleport
	var snap:Bool;

	public function new(mc:Clip) {
		root = mc;
		flGround = false;
		flFreezeAnim = false;
		flCol = true;
		x = 0;
		y = 0;
		dx = 0;
		dy = 0;
		cx = 0;
		cy = 0;
		vx = 0;
		vy = 0;
		weight = 1;
		friction = 0.95;
		// attached at the end of a frame, Flash showed it one picture at (0, 0) of the map before its first update:
		// hidden until then (its _x / _y stay 0 for the code, like in Flash)
		snap = true;
		root.visible = false;
	}

	public function update() {
		if (!flGround)
			vy += weight * Timer.tmod;

		if (friction != null) {
			var frict = Math.pow(friction, Timer.tmod);
			vx *= frict;
			vy *= frict;
		}
		dx += vx * Timer.tmod;
		dy += vy * Timer.tmod;

		if (vr != null) {
			vr *= 0.95;
			root._rotation += vr * Timer.tmod;
		}

		recal();

		root._x = (x + 0.25 + (cx * 0.5)) * Cs.SIZE + dx;
		root._y = (y + 0.25 + (cy * 0.5)) * Cs.SIZE + dy;
		if (snap) {
			snap = false;
			root.visible = true;
			root.updateState();
		}

		if (nextAnim != null && !flFreezeAnim) {
			root.gotoAndPlay(nextAnim);
			nextAnim = null;
		}
	}

	function recal() {
		var m = Cs.SIZE * 0.25;

		var adx = Math.abs(dx);
		var ady = Math.abs(dy);

		while (adx > m || ady > m) {
			if (adx > ady) { // HORIZONTAL
				if (dx > 0) { // RIGHT
					if (cx == 0) {
						if (x < Game.XMAX - 1) {
							cx++;
							dx -= 2 * m;
							crossSquare();
						} else {
							bang();
							dx = m;
						}
					} else {
						leaveSquare();
						cx = 0;
						dx -= 2 * m;
						x++;
						enterSquare();
					}
				} else { // LEFT
					if (cx == 1) {
						if (x > 0) {
							cx--;
							dx += 2 * m;
							crossSquare();
						} else {
							bang();
							dx = -m;
						}
					} else {
						leaveSquare();
						cx = 1;
						dx += 2 * m;
						x--;
						enterSquare();
					}
				}
			} else { // VERTICAL
				if (dy > 0) { // DOWN
					if (cy == 0) {
						if (!checkGround()) {
							cy++;
							dy -= 2 * m;
						} else {
							land();
							dy = m;
						}
					} else {
						leaveSquare();
						cy = 0;
						dy -= 2 * m;
						y++;
						enterSquare();
					}
				} else { // UP
					if (cy == 1) {
						cy--;
						dy += 2 * m;
					} else {
						leaveSquare();
						cy = 1;
						dy += 2 * m;
						y--;
						enterSquare();
					}
				}
			}

			adx = Math.abs(dx);
			ady = Math.abs(dy);
		}
	}

	public function crossSquare() {
		if (flGround) {
			checkFall();
		}
	}

	function checkFall() {
		if (!checkGround())
			fall();
	}

	public function fall() {
		flGround = false;
	}

	public function land() {
		flGround = true;
		vy = 0;
	}

	public function bang() {
		vx = 0;
	}

	public function checkGround():Bool {
		if (!flCol)
			return false;
		for (i in 0...2) {
			var sens = cx * 2 - 1;
			if (!Cs.game.checkFree(x + sens * i, y + 1)) {
				return true;
			}
		}
		return false;
	}

	public function enterSquare() {}

	public function leaveSquare() {}

	//
	public function setSens(n:Int) {
		sens = n;
		root._xscale = n * 100;
	}

	// angle and distance between the clips, like the original (no target: NaN, as in Flash)
	public function getAng(mc:ASprite):Float {
		if (mc == null)
			return Math.NaN;
		var dx = mc._x - root._x;
		var dy = mc._y - root._y;
		return Cs.q(Math.atan2(dy, dx));
	}

	public function getDist(mc:ASprite):Float {
		if (mc == null)
			return Math.NaN;
		var dx = mc._x - root._x;
		var dy = mc._y - root._y;
		return Math.sqrt(dx * dx + dy * dy);
	}
}
