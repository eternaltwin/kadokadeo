package puzzlemanda;

import puzzlemanda.Anim;
import puzzlemanda.Data.Mask;
import puzzlemanda.Game;

// Cell.hx of the original: a fruit of the grid (a Flash button: onRelease starts the snake on it, onRollOver moves the
// snake to it when it is next to its head)
class Cell {
	public var symbol:Int;

	public var x(default, null):Int;
	public var y(default, null):Int;

	public var chained:Bool;

	public var mcSymbol(default, null):MC;

	public var removeCount:Int;

	public function new(x:Int, y:Int, s:Int) {
		this.x = x;
		this.y = y;
		this.symbol = s;
		this.chained = false;
	}

	public function display() {
		if (mcSymbol == null) {
			mcSymbol = Game.dm.attach("cell", Game.DP_CELL);
			// port: the button's shape, and its stars turned by the gameplay random (the mouse is tested on them)
			mcSymbol.hit = hit;
			mcSymbol.button = true;
		}

		mcSymbol.stop();
		mcSymbol._x = getX(x);
		mcSymbol._y = getY(y);
		mcSymbol.subGotoAndStop("symbol", symbol + 1);
		mcSymbol.onRelease = onClic;
		mcSymbol.onRollOver = onRollOver;

		mcSymbol.gotoAndStop(Const.ANIM_APPEAR.start);
		Game.addAnim(new AnimPlay(mcSymbol, Const.ANIM_APPEAR, x + y + Seed.random(2)));
	}

	public function kill() {
		if (!chained) {
			var time:Float = (x + y) * 4;
			var dx = x - KKApi.val(Game.width) * 0.5;
			var dy = y - KKApi.val(Game.height) * 0.5;
			switch (Game.cleanId) {
				case 1:
					time = x * 5 + y;
				case 2:
					time = y * 5 + x;
				case 3:
					time = Math.sqrt(dx * dx + dy * dy) * 5;
				case 4:
					// (atan2 rounded: the same in every browser, the end of the level waits for it)
					time = (Game.q(Math.atan2(dy, dx)) + 3.14) * 5;
				case _:
			}
			Game.addAnim(new BeurkAnim(Std.int(time), remove, Const.DESTROY_ANIM_LENGTH));
		} else {
			remove();
		}
	}

	function remove() {
		Game.inst.destroyAnim(mcSymbol, EndLevel);
		mcSymbol.removeMovieClip();
	}

	// (port: the actions go through Game.act, recorded in the replay: Suite.next(this) or Suite.reinit())
	function onClic() {
		if (!Game.locked() && !Game.suite.started() && Game.suite.check(this)) {
			Game.inst.act(Game.ACT_START + y * KKApi.val(Game.width) + x);
		} else if (!Game.locked() && Game.suite.started()) {
			// onRollOver();
			Game.inst.act(Game.ACT_REINIT);
		}
	}

	function onRollOver() {
		var l = Game.suite.last();
		if (!Game.locked() && isNeighbour(l) == true && Game.suite.check(this))
			Game.inst.act(Game.ACT_OVER + l.dirTo(this));
	}

	public function tryNeighbour() {
		if (Game.locked())
			return;
		// port: a replay has the move the mouse made (Game.ACT_FOLLOW)
		if (Game.inst.isReplay) {
			Game.inst.replayFollow();
			return;
		}

		// (mcSymbol._parent._xmouse: the mouse in the game's root)
		var difX = Game.inst.mouseX - mcSymbol._x;
		var difY = Game.inst.mouseY - mcSymbol._y;

		var d = -1;
		if (Math.abs(difX) > Math.abs(difY)) {
			if (difX > 20) {
				d = 0;
			} else if (difX < -20) {
				d = 2;
			}
		} else {
			if (difY > 20) {
				d = 1;
			} else if (difY < -20) {
				d = 3;
			}
		}

		var n = d < 0 ? null : neighbour(d);
		if (n != null && Game.suite.check(n))
			Game.inst.act(Game.ACT_FOLLOW + d);
	}

	// port: the 4 neighbours (right, down, left, up), null out of the grid
	static var DX = [1, 0, -1, 0];
	static var DY = [0, 1, 0, -1];

	public function neighbour(d:Int):Cell {
		return Game.cellAt(x + DX[d], y + DY[d]);
	}

	// the direction of a neighbour
	function dirTo(c:Cell):Int {
		for (d in 0...4)
			if (c.x == x + DX[d] && c.y == y + DY[d])
				return d;
		return -1;
	}

	// (null for no cell: Flash's falsy result)
	public function isNeighbour(c:Cell):Null<Bool> {
		if (c == null)
			return null;

		if (c == Game.cellAt(x - 1, y))
			return true;
		if (c == Game.cellAt(x + 1, y))
			return true;
		if (c == Game.cellAt(x, y - 1))
			return true;
		if (c == Game.cellAt(x, y + 1))
			return true;

		return false;
	}

	public function randomNeighbour():Cell {
		var a = new Array();
		var c = Game.cellAt(x - 1, y);
		if (c != null && !c.chained)
			a.push(c);

		c = Game.cellAt(x + 1, y);
		if (c != null && !c.chained)
			a.push(c);

		c = Game.cellAt(x, y - 1);
		if (c != null && !c.chained)
			a.push(c);

		c = Game.cellAt(x, y + 1);
		if (c != null && !c.chained)
			a.push(c);

		// (random(0) is 0, a[0] undefined when there is none)
		return a[Seed.random(a.length)];
	}

	public function hide() {
		Game.inst.destroyAnim(mcSymbol, SnakeEat);
	}

	// (prev is null for the first piece: Flash reads undefined fields of it, every test on them is false)
	public function displaySnake(prev:Cell, next:Cell) {
		mcSymbol._visible = true;
		if ((prev == null || prev.x == x) && next.x == x)
			mcSymbol.gotoAndStop(Const.FRAME_VERT);
		if ((prev == null || prev.y == y) && next.y == y)
			mcSymbol.gotoAndStop(Const.FRAME_HORI);

		if (prev == null)
			return;

		if (prev.x == x && prev.y > y && next.x > x)
			mcSymbol.gotoAndStop(Const.FRAME_BOTTOM_RIGHT);
		if (next.x == x && next.y > y && prev.x > x)
			mcSymbol.gotoAndStop(Const.FRAME_BOTTOM_RIGHT);

		if (prev.x == x && prev.y > y && next.x < x)
			mcSymbol.gotoAndStop(Const.FRAME_BOTTOM_LEFT);
		if (next.x == x && next.y > y && prev.x < x)
			mcSymbol.gotoAndStop(Const.FRAME_BOTTOM_LEFT);

		if (prev.x == x && prev.y < y && next.x < x)
			mcSymbol.gotoAndStop(Const.FRAME_TOP_LEFT);
		if (next.x == x && next.y < y && prev.x < x)
			mcSymbol.gotoAndStop(Const.FRAME_TOP_LEFT);

		if (prev.x == x && prev.y < y && next.x > x)
			mcSymbol.gotoAndStop(Const.FRAME_TOP_RIGHT);
		if (next.x == x && next.y < y && prev.x > x)
			mcSymbol.gotoAndStop(Const.FRAME_TOP_RIGHT);
	}

	public function hideSnake() {
		mcSymbol._visible = true;
		mcSymbol.gotoAndStop(1);
		mcSymbol.subGotoAndStop("symbol", symbol + 1);
	}

	public static function getX(x:Float):Float {
		var s = 30;
		return x * s + (300 - KKApi.val(Game.width) * s) / 2 + s / 2;
	}

	public static function getY(y:Float):Float {
		var s = 30;
		return y * s + 60 + (240 - KKApi.val(Game.height) * s) / 2 + s / 2;
	}

	// ---------------------------------------------------------------- port: the shape of the button
	// Flash gives the mouse to a button clip where one of its shapes is under it: the fruit (scaled while it appears),
	// a bonus (its disc and its three stars, which turn), or the piece of snake. x, y in the cell
	function hit(lx:Float, ly:Float):Bool {
		var f = mcSymbol._currentframe;
		var H = Data.hit();
		if (f >= 60)
			return maskHit(H.body[f - 60], lx, ly);
		var m = Data.SYM_MAT[f - 1];
		var sym = mcSymbol.sub("symbol");
		if (m == null || sym == null)
			return false;
		var p = inverse(m, lx, ly, 0);
		var s = sym.frame;
		if (s <= 5)
			return maskHit(H.sym[s - 1], p.x, p.y);
		var b = inverse(Data.BONUS_MAT, p.x, p.y, 0);
		if (maskHit(H.disc, b.x, b.y))
			return true;
		var bonus = sym.layerClip(1);
		if (bonus == null)
			return false;
		for (i in 0...3) {
			var star = bonus.layerClip(i + 1);
			if (star == null)
				continue;
			var q = inverse(Data.STAR_MATS[i], b.x, b.y, star.starAngle);
			if (maskHit(H.star, q.x, q.y))
				return true;
		}
		return false;
	}

	// the point in the clip placed by the matrix m ([a, b, c, d, tx, ty] without skew), its _rotation set to rot
	static function inverse(m:Array<Float>, x:Float, y:Float, rot:Float):{x:Float, y:Float} {
		var sx = Math.sqrt(m[0] * m[0] + m[1] * m[1]);
		var sy = Math.sqrt(m[2] * m[2] + m[3] * m[3]);
		var r = rot != 0 ? rot * Math.PI / 180 : Math.atan2(m[1], m[0]);
		var dx = x - m[4];
		var dy = y - m[5];
		// (rounded: the same in every browser)
		var c = Game.q(Math.cos(r));
		var s = Game.q(Math.sin(r));
		return {x: (dx * c + dy * s) / sx, y: (-dx * s + dy * c) / sy};
	}

	static function maskHit(k:Mask, x:Float, y:Float):Bool {
		var row = Math.floor((y - k.oy) * Data.HIT_Z);
		if (row < 0 || row >= k.rows.length)
			return false;
		var col = (x - k.ox) * Data.HIT_Z;
		for (r in k.rows[row])
			if (col >= r[0] && col < r[1])
				return true;
		return false;
	}
}
