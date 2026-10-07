package digestomax;

import digestomax.MC.Plans;

// Ball.hx of the original: a fruit of the grid (Pioupiou is one too, colour 20: Piou). Its clip `root` is an empty clip
// of the map holding the mcBall skin on the frame of its colour + 1.
class Ball {
	// (never set by the code: undefined, false in the tests)
	public var flIce:Bool = false;
	public var flFruit:Bool;

	public var gid:Null<Int>;
	public var color:Null<Int>;
	public var fallAmount:Int;

	public var px:Int;
	public var py:Int;

	public var fc:Float;

	public var coef:Float;
	public var spc:Float;

	public var root:MC;
	public var skin:MC;
	public var dm:Plans;

	public var mcArrow:MC;

	// port: Col.setPercentColor + Filt.glow of Game.updateExplode, one shader
	var explodeGlow:FlashGlow;

	public function new(x:Int, y:Int, ?col:Int) {
		root = Game.me.dm.empty(Game.DP_BALLS);
		// (undefined while Pioupiou himself is created: nothing)
		Game.me.dm.over(Game.me.hero != null ? Game.me.hero.root : null);

		dm = new Plans(root.clip, root);
		skin = dm.attach("mcBall", 0);

		Game.me.balls.push(this);
		setPos(x, y);
		setColor(col);
	}

	public function setPos(x:Int, y:Int) {
		px = x;
		py = y;
		insertInGrid();
		display(px, py);
	}

	public function display(x:Float, y:Float) {
		root._x = Cs.getX(x);
		root._y = Cs.getY(y);
	}

	public function setColor(?col:Int) {
		if (col == null) {
			col = Seed.random(Cs.COLOR_MAX);

			if (Game.me.lvl > 1) {
				// FLASH
				if (Seed.random(40 * Game.me.lvl) == 0)
					col += 10;

				// GULP
				if (Seed.random(100) == 0)
					col = 5;

				// STOMACH
				var lim = Game.me.hero.stomachSize + Game.me.bonusStomach;
				// Math.pow((lim - 2) * 1.5, 3): a multiple of 0.5 cubed, exact (not left to the pow of the browser)
				var b = (lim - 2) * 1.5;
				var sc = Std.int(b * b * b);
				if (lim < 12 && Seed.random(sc) == 0) {
					Game.me.bonusStomach++;
					col = 4;
				}
			}
		}
		flFruit = col < 20;
		color = col;
		var fr = color + 1;
		skin.gotoAndStop(fr);
	}

	// GRID
	public function move(dx:Int, dy:Int) {
		removeFromGrid();
		px += dx;
		py += dy;
		insertInGrid();
	}

	public function insertInGrid() {
		Game.me.setCell(px, py, this);
	}

	public function removeFromGrid() {
		Game.me.setCell(px, py, null);
	}

	// KILL
	public function explode() {
		// PART (only pictures: visual random)
		var cr = 3;
		var max = 6;
		for (i in 0...max) {
			var p = new Phys(Game.me.dm.attach("partFruit", Game.DP_FX));
			var a = (i + Seed.randVfx()) / max * 6.28;
			var sp = 0.5 + Seed.randVfx() * 3;
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.x = root._x + p.vx * cr;
			p.y = root._y + p.vy * cr;
			p.vr = (Seed.randVfx() * 2 - 1) * 15;
			p.fr = 0.97;
			p.weight = 0.1 + Seed.randVfx() * 0.1;
			p.timer = 10 + Seed.randVfx() * 20;
			p.frict = 0.99;
			p.fadeType = 0;
			p.root._rotation = a / 0.0174 + 180;
			// (colours 4, 5 and 10..13: past the 4 frames of partFruit, its last frame)
			p.root.gotoAndStop(color + 1);
			var smc = p.root.sub("smc");
			if (smc != null)
				smc.gotoAndStop(Seed.randomVfx(smc._totalframes) + 1);
			p.updatePos();
		}

		// LIGHT
		var cr = 3;
		for (i in 0...3) {
			var p = new Phys(Game.me.dm.attach("partLight", Game.DP_FX));
			var a = Seed.randVfx() * 6.28;
			var sp = Seed.randVfx() * 4;
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.x = root._x + p.vx * cr;
			p.y = root._y + p.vy * cr;
			p.timer = 10 + Seed.randVfx() * 10;
			p.frict = 0.9;
			p.fadeType = 0;
			p.updatePos();
			p.root._alpha = 50;
			p.root.blendAdd();
		}

		kill();
	}

	function kill() {
		removeFromGrid();
		Game.me.balls.remove(this);
		root.removeMovieClip();
	}

	// port: Game.updateExplode, Col.setPercentColor(root, coef * 100, 0xFFFFFF); root.filters = [];
	// Filt.glow(root, coef * 8, coef * 2, 0xFFFFFF)
	public function setExplodeFx(coef:Float) {
		if (root.removed)
			return;
		if (explodeGlow == null) {
			explodeGlow = new FlashGlow(0, 0, 0, 0xFFFFFF);
			root.clip.filters = [explodeGlow];
		}
		explodeGlow.set(coef * 8, coef * 8, coef * 2);
		explodeGlow.setWhite(coef * 100);
	}
}
