package kslash;

import mt.DepthManager;
import mt.Timer;

class Ent {
	public var dm:DepthManager;
	public var root:ASprite;

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
	public var vr:Float;

	public var weight:Float;
	public var friction:Float;

	public var nextAnim:String;
	public var animFrame:Map<String, Int> = new Map();

	public function new(mc) {
		dm = new DepthManager(mc);
		root = mc;
		root.obj = cast this; // TODO: remove cast
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
		vr = null;
		weight = 1 * Cs.NEW_GEN_SCALE;
		friction = 0.95;
	}

	public function update() {
		if (!flGround) {
			vy += weight * Timer.tmod;
		}

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

		if (nextAnim != null && !flFreezeAnim) {
			if (animFrame.exists(nextAnim)) {
				var anim = animFrame.get(nextAnim);
				root.gotoAndPlay(anim);
			} else {
				root.gotoAndPlay(nextAnim);
			}
			nextAnim = null;
		}
	}

	public function recal() {
		var m = Cs.SIZE * 0.25;

		var adx = Math.abs(dx);
		var ady = Math.abs(dy);

		while (adx > m || ady > m) {
			if (adx > ady) { // HORIZONTAL
				if (dx > 0) { // DROITE
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
				} else { // GAUCHE
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
				if (dy > 0) { // BAS
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
				} else { // HAUT
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

	public function checkFall() {
		if (!checkGround())
			fall();
	}

	public function fall() {
		flGround = false;
	}

	public function land() {
		// Log.trace("land!")
		flGround = true;

		vy = 0;
	}

	public function bang() {
		vx = 0;
	};

	public function checkGround() {
		if (!flCol)
			return false;
		for (i in 0...2) {
			var sens = cx * 2 - 1;
			if (!Cs.game.checkFree(x + sens * i, y + 1)) {
				// Log.trace((x+sens*i)+","+(y+1))
				return true;
			}
		}
		return false;
	}

	public function enterSquare() {}

	public function leaveSquare() {}

	//
	public function setSens(n) {
		sens = n;
		root._xscale = n * 100;
	}

	//
	public function getAng(o:Ent) {
		var dx = o.root._x - root._x;
		var dy = o.root._y - root._y;
		return Math.atan2(dy, dx);
	}

	public function getDist(o:Ent) {
		var dx = o.root._x - root._x;
		var dy = o.root._y - root._y;
		return Math.sqrt(dx * dx + dy * dy);
	}
}
