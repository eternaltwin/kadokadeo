package razor;

import razor.Cs.Geom;

// Ball.hx of the original: a fruit of the board (col 0-2, Pioupiou: Cs.COL_MAX)
class Ball {
	public var col:Int;
	public var x:Int;
	public var y:Int;

	public var tx:Int;
	public var ty:Int;

	// (null for the fruits of a spawn until the next fall: `null > 0` is false)
	public var fall:Null<Float> = null;

	public var root:MC;

	public function new(px:Int, py:Int) {
		x = px;
		y = py;
		insertInGrid();
		Game.me.balls.push(this);

		root = Game.me.bdm.attach("mcBall", Game.DP_BALL);

		col = Seed.random(Cs.COL_MAX);
		if (Seed.random(Game.me.probaSpecial) == 0)
			col = Cs.COL_MAX;
		root.gotoAndStop(col + 1);

		updatePos();
	}

	public function updatePos() {
		root._x = Cs.getX(x);
		root._y = Cs.getY(y);
	}

	public function updateRot() {
		root._rotation = -Game.me.board._rotation;
	}

	public function sliced() {
		var coord = Geom.getParentCoord(root);

		// SPLASH (only pictures: visual random)
		for (i in 0...4) {
			var mcSplash = Game.me.dm.attach("mcSplash", Game.DP_FX);
			mcSplash._x = coord.x + (Seed.randVfx() * 2 - 1) * 3;
			mcSplash._y = coord.y + (Seed.randVfx() * 2 - 1) * 3;
			mcSplash._xscale = mcSplash._yscale = 50 + Seed.randVfx() * 50;
			// Col.setColor(mcSplash, 0xFF0000)
			mcSplash.setTint(0xFF0000);
			mcSplash._rotation = Seed.randVfx() * 360;
		}

		// 3 PARTS
		var max = 3;
		for (i in 0...max) {
			var dp = Game.DP_UNDER_FX;
			if (i > 0)
				dp = Game.DP_FX;
			var p = new Phys(Game.me.dm.attach("partSlice", dp));

			p.x = coord.x;
			p.y = coord.y;
			p.weight = 0.5 + Seed.randVfx() * 0.2;
			p.vx = (Seed.randVfx() * 2 - 1) * 1.5;
			p.vy = -(2 + Seed.randVfx() * 4) * 1.5;
			p.vr = (Seed.randVfx() * 2 - 1) * 4;
			p.fr = 0.95;
			p.timer = 60;
			p.root.gotoAndStop((col + 1) * max - i);

			p.updatePos();
		}

		// SCORE
		var sc = KKApi.cadd(Cs.SCORE_FRUIT_BASE, KKApi.cmult(Cs.SCORE_FRUIT_INC, KKApi.const(Game.me.bonus)));
		if (col == Cs.COL_MAX)
			sc = Cs.SCORE_PIOUPIOU;

		Game.me.addScore(sc);
		Game.me.comboScore += KKApi.val(sc);

		// (mcScore, the symbol of these scores, is not exported by the port: FL_VISEW_SCORE is false)
		if (Game.FL_VISEW_SCORE) {
			for (i in 0...3) {
				var p = new Shaker(Game.me.dm.attach("mcScore", Game.DP_FX));
				p.x = coord.x;
				p.y = coord.y;
				p.fadeType = 0;
				p.timer = 20;
				p.updatePos();
			}
		}

		kill();
	}

	public function kill() {
		Game.me.grid[x][y] = null;
		Game.me.balls.remove(this);
		root.removeMovieClip();
	}

	public function insertInGrid() {
		Game.me.grid[x][y] = this;
	}

	public function removeFromGrid() {
		Game.me.grid[x][y] = null;
	}
}
