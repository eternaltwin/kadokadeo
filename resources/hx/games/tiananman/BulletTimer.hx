package tiananman;

import mt.bumdum.Lib;

class BulletTimer {
	static public var MIN_MOVE = Cs.s(1.0);
	static public var MIN_ROT = Cs.s(2.0);

	public var lastX:Float;
	public var lastY:Float;
	public var x:Float;
	public var y:Float;
	public var delta:{x:Float, y:Float};

	var mcRef:ASprite;

	public function new() {
		mcRef = Game.me.root;
		lastX = Num.q(mcRef._xmouse);
		lastY = Num.q(mcRef._ymouse);
		x = lastX;
		y = lastY;
		delta = {x: 0.0, y: 0.0};
	}

	public function isMoving() {
		var d = getDist();
		return d != null && d >= MIN_MOVE;
	}

	public function isRotating() {
		var d = getDist();
		return d != null && d >= MIN_ROT;
	}

	public function update() {
		var sx = x;
		var sy = y;

		lastX = Num.q(x);
		lastY = Num.q(y);

		// trace(lastX + ", " + lastY + " ==> " + mcRef._xmouse + ", " + mcRef._ymouse) ;

		x = Num.q(mcRef._xmouse + delta.x);
		y = Num.q(mcRef._ymouse + delta.y);

		if (!isMoving()) {
			x = sx;
			y = sy;
		}

		if (outOfGround())
			Game.me.setPause();
	}

	public function outOfGround() {
		var qx = Num.q(x);
		var qy = Num.q(y);
		return qx < Cs.mcw[0] || qx > Cs.mcw[1] || qy < Cs.mch[0] || qy > Cs.mch[1];
	}

	public function getDist():Float {
		return Num.q(Cs.getDist(x, y, lastX, lastY));
	}
}
