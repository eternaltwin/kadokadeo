package flushee;

import mt.Timer;

class Gem {
	static var MOVE = 0;
	static var EXPLODE = 1;
	static var GRAVITY = 2;
	static var FALL = 3;

	public var group:Array<Gem>;

	var game:Game;
	var t:Int;

	public var id:Int;
	public var x:Int;
	public var y:Int;

	public var mc:ASprite;

	var tx:Int;
	var ty:Int;

	public var px:Float;
	public var py:Float;

	var time:Float;
	var frame:Float;

	public function new(g:Game, id:Int, x:Int, y:Int) {
		this.game = g;
		setId(id);
		setPos(x, y);
	}

	public function setPos(x:Null<Int>, y:Null<Int>):Void {
		if (x != null) {
			this.x = x;
			mc._x = Cs.POSX + x * Cs.CELL_SIZE;
		}
		if (y != null) {
			this.y = y;
			game.dmanager.swap(mc, Cs.PLAN_GEM + y);
			mc._y = Cs.POSY + y * Cs.CELL_SIZE;
		}
	}

	public function setId(n:Int):Void {
		this.id = n;
		var oldX = mc != null ? mc._x : 0;
		var oldY = mc != null ? mc._y : 0;
		if (mc != null) {
			mc.removeMovieClip();
		}
		mc = game.dmanager.attach("gem" + (id + 1), Cs.PLAN_GEM + y);
		mc.removeOnFrame = 6;
		mc._x = oldX;
		mc._y = oldY;
	}

	public function move(tx:Int, ty:Int):Void {
		t = MOVE;
		x = tx;
		y = ty;
		game.dmanager.swap(mc, Cs.PLAN_GEM + ty);
		mc.gotoAndStop(2);
		this.tx = Cs.POSX + tx * Cs.CELL_SIZE;
		this.ty = Cs.POSY + ty * Cs.CELL_SIZE;
		px = mc._x;
		py = mc._y;
		game.moves.push(this);
	}

	public function explode():Void {
		t = EXPLODE;
		px = mc._x + 18 * Cs.NEW_GEN_SCALE;
		py = mc._y + 18 * Cs.NEW_GEN_SCALE;
		time = 0;
		mc.gotoAndPlay(1);
		game.moves.push(this);
	}

	public function gravity():Void {
		t = GRAVITY;
		y++;
		game.dmanager.swap(mc, Cs.PLAN_GEM + y);
		px = mc._y;
		py = 0;
		game.moves.push(this);
	}

	public function fall(y:Int):Void {
		t = FALL;
		py = (y - this.y) * Cs.CELL_SIZE;
		setPos(x, y);
		px = mc._y;
		game.moves.push(this);
	}

	public function update():Bool {
		if (t == MOVE) {
			return updateMove();
		} else if (t == EXPLODE) {
			return updateExplode();
		} else if (t == GRAVITY) {
			return updateGravity();
		} else if (t == FALL) {
			return updateFall();
		}
		return false;
	}

	function updateMove():Bool {
		var r = true;
		var p = Math.pow(0.7, Timer.tmod);
		px = px * p + tx * (1 - p);
		py = py * p + ty * (1 - p);
		if (Math.abs(px - tx) + Math.abs(py - ty) < 2 * Cs.NEW_GEN_SCALE) {
			px = tx;
			py = ty;
			mc.gotoAndStop(1);
			r = false;
		}
		mc._x = px;
		mc._y = py;
		return r;
	}

	function updateExplode():Bool {
		if (time >= 0) {
			time -= Timer.deltaT;
			if (time < 0)
				mc.gotoAndPlay(1);
		}
		var flg = (mc._name != null);
		if (!flg) {
			var nparts = Std.int(Math.max(1, 5 / Timer.tmod));
			for (i in 0...nparts) {
				var p = new Particule(game, id, px, py);
				game.parts.push(p);
			}
			mc.removeMovieClip();
		}
		return flg;
	}

	function updateGravity():Bool {
		var fl = true;
		py += Timer.tmod * 10 * Cs.NEW_GEN_SCALE;
		if (py >= Cs.CELL_SIZE) {
			py = Cs.CELL_SIZE;
			fl = false;
		}
		mc._y = px + py;
		return fl;
	}

	function updateFall():Bool {
		var fl = true;
		py -= Timer.tmod * 10 * Cs.NEW_GEN_SCALE;
		if (py <= 0) {
			py = 0;
			fl = false;
		}
		mc._y = px - py;
		return fl;
	}
}
