package phagocytoz;

// typedef Star = {> flash.display.MovieClip, sc:Float, bx:Float, by:Float}
class Star extends MovieClip {
	public var sc:Float;
	public var bx:Float;
	public var by:Float;

	public function new() {
		super(-1);
	}
}

class Level extends Sprite {
	public static var WIDTH = 1600;
	public static var HEIGHT = 1600;

	public static var DP_BG = 0;
	public static var DP_CELLS = 1;

	public var tracer:MovieClip;
	public var focus:Cell;
	public var scale:Float;

	var tsc:Float;

	public var dm:DepthManager;

	public function new() {
		super();

		dm = new DepthManager(this);
		scale = 2;
		tsc = 1;

		tracer = dm.empty(4);

		initStarfield();
	}

	public function setScale(n:Float) {
		for (sp in starfield) {
			var dx = 150 - sp.x;
			var dy = 150 - sp.y;
			var nx = 150 - (dx * n) / scale;
			var ny = 150 - (dy * n) / scale;

			var c = sp.sc;
			sp.x = nx * c + sp.x * (1 - c);
			sp.y = ny * c + sp.y * (1 - c);
		}

		scale = n;
		scaleX = n;
		scaleY = n;
	}

	// the focus at the last scroll (the display: its jumps across a border of the level)
	var lastFx = Math.NaN;
	var lastFy = Math.NaN;

	public function scroll() {
		// (the scale shown at the frame before)
		var sc0 = scale;
		var min = Game.mcw / (WIDTH - 300);
		var max = 6;

		// ZOOM
		var sc = 16 / Game.me.hero.ray;
		var dif = WIDTH * (sc - scale);

		if (Math.abs(dif) > 400 * scale) {
			tsc = Num.mm(min, sc, max);
		}
		if (tsc != scale) {
			var dif = (tsc - scale) * 0.1;
			setScale(scale + dif);
		}

		Game.me.bgScroller.scaleX = 1 + (scaleX - min) * 1.5;
		Game.me.bgScroller.scaleY = 1 + (scaleY - min) * 1.5;

		// SCROLL
		if (focus != null) {
			// (the focus across a border of the level: the level jumps by a whole level, its cells as much the other way
			// (moveWrapped), not a move)
			if (!Math.isNaN(lastFx))
				shiftPrev(-Math.round((focus.x - lastFx) / WIDTH) * WIDTH * sc0, -Math.round((focus.y - lastFy) / HEIGHT) * HEIGHT * sc0);
			lastFx = focus.x;
			lastFy = focus.y;
			x = Game.mcw * 0.5 - focus.x * scale;
			y = Game.mch * 0.5 - focus.y * scale;
		}

		// STARS
		updateStarField();
	}

	public function kill() {
		parent.removeChild(this);
		while (starfield.length > 0) {
			var sp = starfield.pop();
			sp.parent.removeChild(sp);
		}
	}

	// STARFIELD (a picture only: its random is the visual one)
	public var starfield:Array<Star>;

	public function initStarfield() {
		starfield = [];
		var max = 100;
		for (i in 0...max) {
			var c = i / max;
			var sp = new Star();

			var bsc = Game.me.bgScroller.scaleX;

			sp.sc = c;
			var gfx = new Gfx.McMicroCell();
			sp.addChild(gfx);
			sp.scaleX = sp.scaleY = 0.2 + c * 0.8;
			gfx.gotoAndStop(Seed.randomVfx(gfx.totalFrames) + 1);
			gfx.rotation = Seed.randVfx() * 360;

			sp.alpha = 0.4;

			sp.x = Seed.randVfx() * Game.mcw * 4;
			sp.y = Seed.randVfx() * Game.mch * 4;
			starfield.push(sp);

			Game.me.dm.add(sp, 1);
		}
	}

	public function updateStarField() {
		var h = Game.me.hero;

		if (h == null || h.dead) {
			for (sp in starfield)
				if (sp.alpha > 0)
					sp.alpha -= 0.1;
			return;
		}

		var ray = 150;
		for (sp in starfield) {
			var bsc = Game.me.bgScroller.scaleX * 0.2;

			var c = bsc * (1 - sp.sc) + sp.sc * scale;

			sp.x -= h.vx * c;
			sp.y -= h.vy * c;

			var c = 1 + sp.sc * 0.25;

			var nx = Num.hMod(sp.x - ray, ray * c);
			var ny = Num.hMod(sp.y - ray, ray * c);
			// (a star leaving the screen comes back on the other side: not a slide across it)
			sp.moveWrapped(nx + ray, ny + ray, ray * c * 2, ray * c * 2);

			sp.alpha = Num.mm(0, scale - 0.25, 1) * 0.4;
		}
	}
}
