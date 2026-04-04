package kaskade2;

import mt.bumdum.Phys;
import mt.Timer;

class Bille extends Phys {
	public static var COS = Math.cos(Math.PI / 4);
	public static var SIN = Math.sin(Math.PI / 4);

	public static var INV_COS = Math.cos(-Math.PI / 4);
	public static var INV_SIN = Math.sin(-Math.PI / 4);

	var game:Game;

	public var mc:ASprite;
	public var star:ASprite;
	public var id:Int;
	public var group:Array<Bille>;
	public var px:Float;
	public var py:Float;

	public var gx:Float;
	public var gy:Float;

	public function new(game:Game, px, py) {
		this.game = game;
		// star = downcast(mc).star;
		if (game.nlevels == Const.MAXCOLORS)
			id = Const.MAXCOLORS - 1;
		else
			id = game.random(game.nlevels);
		mc = game.dm.attach("bille/bille_" + (id + 1), Const.PLAN_BILLE);
		mc.gotoAndStop(id + 1);
		activate(false);
		mc.onRollOver = onPointerOver;
		mc.onRollOut = onPointerOut;
		mc.onRelease = onPointerRelease;
		super(mc);
		setPos(px, py);
		this.scale = 0;
	}

	function onPointerOver() {
		game.onBilleHover(this);
	}

	function onPointerOut() {
		game.onBilleOut(this);
	}

	function onPointerRelease() {
		game.onBilleClick(this);
	}

	public function onRollOver() {
		if (this.game.lock)
			return;
		if (this.game.curGroup == this.group)
			return;
		if (this.game.curGroup != null) {
			for (group in this.game.curGroup) {
				group.activate(false);
			}
		}
		this.game.curGroup = this.group;
		if (this.group != null) {
			for (group in this.game.curGroup) {
				group.activate(true);
			}
		}
	}

	public function onRollOut() {
		if (this.game.lock)
			return;
		if (this.game.curGroup == this.group && this.game.curGroup != null) {
			for (group in this.game.curGroup) {
				group.activate(false);
			}
			this.game.curGroup = null;
		}
	}

	public function setPos(x, y) {
		px = x * Const.BILLE_RAY - (Const.LVL_WIDTH * Const.BILLE_RAY) / 2;
		py = y * Const.BILLE_RAY - (Const.LVL_HEIGHT * Const.BILLE_RAY) / 2;
		move();
	}

	public function move() {
		this.x = px * COS - py * SIN + Const.DELTA_X;
		this.y = px * SIN + py * COS + Const.DELTA_Y;
	}

	public function activate(b) {
		mc.gotoAndStop(b ? 2 : 1);
	}

	public function gravityLeft() {
		gx = Const.BILLE_RAY;
		gy = 0;
	}

	public function gravityDown() {
		gx = 0;
		gy = Const.BILLE_RAY;
	}

	public function gravityMain() {
		var s:Float = 10 * Timer.tmod * Const.NEW_GEN_SCALE;
		if (gx > 0) {
			if (gx >= s)
				gx -= s;
			else {
				s = gx;
				gx = 0;
			}
			px += s;
		}
		if (gy > 0) {
			if (gy >= s)
				gy -= s;
			else {
				s = gy;
				gy = 0;
			}
			py += s;
		}
		move();
		return (gx != 0 || gy != 0);
	}
}
