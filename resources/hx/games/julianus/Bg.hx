package julianus;

class Bg {
	var game:Game;

	var bg:MC;
	var bg1:MC;
	var bg2:MC;

	var pos_x:Float;
	var pos_y:Float;

	public function new(g:Game) {
		game = g;
		// (the symbols "bg2", "bg1", "bg0")
		bg = decor(Data.BG2_PARTS);
		bg1 = decor(Data.BG1_PARTS);
		bg2 = decor(Data.BG0_PARTS);
		// bg.onMouseMove = game.onMove, bg.onPress / onRelease / onReleaseOutside = game.press: the mouse is polled
		// by Game.pollMouse (bg covers the whole stage)
		pos_x = 0;
		pos_y = 0;
	}

	// a decor plane: its 600 px bitmaps at x and x + 600 (a 1200 px shape), at their native resolution
	function decor(parts:Array<Dynamic>):MC {
		var m = game.dmanager.add(new MC(), Const.PLAN_BG);
		for (p in parts)
			for (tx in [0, 600]) {
				var t = m.attach(new MC(p[0], 1));
				t._x = p[1] + tx;
				t._y = p[2];
			}
		return m;
	}

	public function update(dx:Float):Void {
		var maxy = Const.MAXY - 300;
		var py:Float;
		if (game.hero.py < 110)
			py = 0;
		else if (game.hero.py > 210)
			py = maxy;
		else
			py = maxy - (210 - game.hero.py) * maxy / 100;
		var p = Const.POW_095;
		pos_y = pos_y * p + py * (1 - p);
		pos_x -= dx * 2;
		// (removes the front plane when the game lags: never with tmod = 0.8)
		if (bg2._alpha != 100 || Game.TMOD > 1.3) {
			bg2._alpha -= 10 * Game.TMOD;
			if (bg2._alpha <= 0)
				bg2.removeMovieClip();
		}
		place(bg, -pos_x % (Data.BG2_WIDTH / 2), Data.BG2_WIDTH);
		place(bg1, -(pos_x * 1.5) % (Data.BG1_WIDTH / 2), Data.BG1_WIDTH);
		place(bg2, -(pos_x * 1.5 * 1.5) % (Data.BG0_WIDTH / 2), Data.BG0_WIDTH);
		game.mc._y = -pos_y;
		game.mc._y = -pos_y;
	}

	// plane._x = x; when it wraps by half its width (the bitmap repeats) the picture is the same: not interpolated
	// across the jump (MC.shiftShown)
	function place(m:MC, x:Float, width:Float):Void {
		var old = m._x;
		m._x = x;
		if (m._x - old > width / 4)
			m.shiftShown(width / 2, 0);
	}
}
