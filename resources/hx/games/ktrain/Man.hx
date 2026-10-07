package ktrain;

// Man.hx of the original: the driver, who leaves the locomotive (left / right) to pick up the gems and walks back in
class Man {
	static var lDIR:Dir;
	static var DIR:Dir;
	static var man:MC;
	static var shadow:MC;
	static var game:Game;
	static var initDone = false;
	static var MIN_POS = 4;
	static var FEET_CYCLE = 1;
	static var feetCycle:Float = FEET_CYCLE;
	static var leftFoot:Null<Bool>;
	static var leftArm:Int;
	static var ARMS_CYCLE = 5;
	static var armCycles:Float = ARMS_CYCLE;
	static var moveCounter:Int = 0;
	static var lockCycles = 0.0;

	static var lastX:Float = 0.0;
	static var lastY:Float = 0.0;

	static var swap:Bool = false;

	public static var lock = false;

	public static var outside = false;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		lDIR = null;
		DIR = null;
		man = null;
		shadow = null;
		initDone = false;
		feetCycle = FEET_CYCLE;
		leftFoot = null;
		leftArm = 0;
		armCycles = ARMS_CYCLE;
		moveCounter = 0;
		lockCycles = 0.0;
		lastX = 0.0;
		lastY = 0.0;
		swap = false;
		lock = false;
		outside = false;
	}

	public static function init(g:Game) {
		leftArm = 1;
		lockCycles = 20;
		game = g;

		if (!initDone) {
			shadow = game.dm.attach("ombre_pilote", Const.DP_OBJECTS);
			shadow.setBlend("multiply");
			man = game.dm.attach("mcPilote", Const.DP_OBJECTS);
			initDone = true;
		}

		man.gotoAndStop(1);
		man.rotation = 0;

		outside = false;

		shadow._x = man._x = Const.CENTER_X;
		shadow._y = man._y = Const.LOCO_STARTPOS - 60;
		man._visible = false;
		shadow._visible = false;
	}

	// (`shadow._y = man._y = v`: both get the value written, each kept in twips)
	static inline function setX(v:Float) {
		man._x = v;
		shadow._x = v;
	}

	static inline function setY(v:Float) {
		man._y = v;
		shadow._y = v;
	}

	public static function initLeft():Bool {
		if (lockCycles > 0)
			return false;
		if (lock)
			return false;

		setY(Loco.mc._y - 60);
		setX(Const.CENTER_X);
		setX(man._x - Const.MAN_OUT);
		if (hit()) {
			setX(man._x + Const.MAN_OUT);
			return false;
		}

		game.stopScroll();
		#if debug
		game.stats.exits++;
		#end
		man.gotoAndStop(3);
		outside = true;
		return true;
	}

	public static function fly() {
		if (!man._visible)
			return;
		man._yscale = man._xscale += 1;
		setY(man._y + 20);
		if (man._y > Const.HEIGHT) {
			man.removeMovieClip();
			shadow.removeMovieClip();
		}
	}

	public static function left():Bool {
		if (!outside) {
			if (!initLeft())
				return false;
			return true;
		}

		man.rotation -= Const.MAN_SPEED * Timer.tmod;
		return true;
	}

	public static function show() {
		shadow._visible = true;
		man._visible = true;
		// port: placed next to the train while hidden (not interpolated from where it was)
		shadow.teleport();
		man.teleport();
	}

	public static function initRight():Bool {
		if (lockCycles > 0)
			return false;
		if (lock)
			return false;

		setY(Loco.mc._y - 60);
		setX(Const.CENTER_X);
		setX(man._x + Const.MAN_OUT);
		if (hit()) {
			setX(man._x - Const.MAN_OUT);
			return false;
		}

		game.stopScroll();
		#if debug
		game.stats.exits++;
		#end
		man.gotoAndStop(4);
		outside = true;
		return true;
	}

	public static function right():Bool {
		if (!outside) {
			if (!initRight())
				return false;
			return true;
		}
		man.rotation += Const.MAN_SPEED * Timer.tmod;
		return true;
	}

	public static function go() {
		if (!outside)
			return;

		if (KeyboardManager.isDown(KeyboardManager.UP)) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT))
				DIR = UpLeft;
			else if (KeyboardManager.isDown(KeyboardManager.RIGHT))
				DIR = UpRight;
			else
				DIR = Up;
		} else if (KeyboardManager.isDown(KeyboardManager.DOWN)) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT))
				DIR = DownLeft;
			else if (KeyboardManager.isDown(KeyboardManager.RIGHT))
				DIR = DownRight;
			else
				DIR = Down;
		} else if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
			DIR = Left;
		} else if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
			DIR = Right;
		}

		if (man._x <= 0 + MIN_POS) {
			switch (DIR) {
				case Left:
					DIR = Up;
				case UpLeft:
					DIR = Up;
				case DownLeft:
					DIR = Down;
				default:
			}
			move();
			return;
		}

		if (man._x >= Const.HEIGHT - MIN_POS) {
			switch (DIR) {
				case Right:
					DIR = Up;
				case UpRight:
					DIR = Up;
				case DownRight:
					DIR = Down;
				default:
			}
			move();
			return;
		}

		if (man._y <= 0 + MIN_POS) {
			switch (DIR) {
				case UpLeft:
					DIR = Left;
				case UpRight:
					DIR = Right;
				case Up:
					DIR = Left;
				default:
			}
			move();
			return;
		}

		if (man._y >= Const.HEIGHT - MIN_POS) {
			switch (DIR) {
				case DownLeft:
					DIR = Left;
				case DownRight:
					DIR = Right;
				case Down:
					DIR = Left;
				default:
			}
			move();
			return;
		}

		move();
	}

	static function move() {
		switch (DIR) {
			case Up:
				setY(man._y - Const.MAN_SPEED);
			case Down:
				setY(man._y + Const.MAN_SPEED);
			case Left:
				setX(man._x - Const.MAN_SPEED);
			case Right:
				setX(man._x + Const.MAN_SPEED);
			case UpRight:
				setX(man._x + Const.MAN_SPEED);
				setY(man._y - Const.MAN_SPEED);
			case UpLeft:
				setX(man._x - Const.MAN_SPEED);
				setY(man._y - Const.MAN_SPEED);
			case DownRight:
				setX(man._x + Const.MAN_SPEED);
				setY(man._y + Const.MAN_SPEED);
			case DownLeft:
				setX(man._x - Const.MAN_SPEED);
				setY(man._y + Const.MAN_SPEED);
			case null:
		}

		printShoe();
		moveArms();
		moveCounter = 10;

		if (hit()) {
			return;
		}
	}

	static function hit():Bool {
		Scroller.hitGem(man, Gem.bonus);

		if (Station.hit(man)) {
			return true;
		}

		if (Scroller.hitRoot(man)) {
			Scroller.changeDepth(man);
			Scroller.changeDepth(shadow);
		}

		if (Scroller.hit(man.getSubBounds("smc"))) {
			switch (DIR) {
				case Up:
					setY(lastY);
				case Down:
					setY(lastY);
				case Left:
					setX(lastX);
				case Right:
					setX(lastX);
				case UpRight:
					setX(lastX);
					setY(lastY);
				case UpLeft:
					setX(lastX);
					setY(lastY);
				case DownRight:
					setX(lastX);
					setY(lastY);
				case DownLeft:
					setX(lastX);
					setY(lastY);
				case null:
			}

			lastX = man._x;
			lastY = man._y;

			return true;
		}

		lastX = man._x;
		lastY = man._y;

		return false;
	}

	public static function update() {
		lockCycles -= Timer.tmod;

		if (moveCounter-- <= 0) {
			switch (DIR) {
				case Up:
					man.gotoAndStop(8);
				case Down:
					man.gotoAndStop(2);
				case Left:
					man.gotoAndStop(11);
				case UpLeft:
					man.gotoAndStop(11);
				case DownLeft:
					man.gotoAndStop(11);
				case Right:
					man.gotoAndStop(5);
				case UpRight:
					man.gotoAndStop(5);
				case DownRight:
					man.gotoAndStop(5);
				case null:
			}
		}
	}

	static function moveArms() {
		if (armCycles-- <= 0) {
			switch (DIR) {
				case Up:
					man.gotoAndStop(7 + leftArm);
				case Right:
					man.gotoAndStop(4 + leftArm);
				case UpRight:
					man.gotoAndStop(4 + leftArm);
				case DownRight:
					man.gotoAndStop(4 + leftArm);
				case Left:
					man.gotoAndStop(10 + leftArm);
				case UpLeft:
					man.gotoAndStop(10 + leftArm);
				case DownLeft:
					man.gotoAndStop(10 + leftArm);
				case Down:
					man.gotoAndStop(1 + leftArm);
				case null:
			}
			if (++leftArm > 2) {
				leftArm = 0;
			}
			armCycles = ARMS_CYCLE;
		}
	}

	// a footprint drawn into the ground (the clip is attached on the plane of the obstacles, drawn, removed)
	static function printShoe() {
		feetCycle -= Timer.tmod;

		if (feetCycle <= 0) {
			var s = game.dm.attach("mcFoot", Const.DP_OBJECTS);
			s._rotation = man.rotation;
			// (compiled form: `if (!leftFoot) +3 else -3`, leftFoot undefined at first)
			if (!leftFoot) {
				s._x = man._x + 3;
			} else {
				s._x = man._x - 3;
			}

			leftFoot = !leftFoot;
			s._y = man._y;
			SceneManager.drawOnScene(s);
			s.removeMovieClip();
			s = null;
			feetCycle = FEET_CYCLE;
		}
	}

	public static function inLoco():Bool {
		return man.hitTest(Loco.mc) && outside;
	}

	// port: test harness
	public static function debugMan():MC {
		return man;
	}
}
