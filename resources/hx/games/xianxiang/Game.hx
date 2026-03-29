package xianxiang;

@:expose('GameXianXiang')
class Game implements kado.GameInterface {
	var dmanager:DepthManager;
	var level:Level;
	var bg_mc:MovieClip;
	var mlist:Array<{mc:MatchSprite, t:float}>;

	var current:Card;
	var colorTime:float;
	var breaks:Array<Card>;

	var path:Array<ASprite>;
	var pathTimer:float;

	public function new(root:ASprite) {
		colorTime = 0;
		dmanager = new DepthManager(root);
		bg_mc = dmanager.attach("bg", Const.PLAN_BG);
		bg_mc.onMouseMove = callback(this, mouseMove);
		bg_mc.onRelease = callback(this, release);
		level = new Level(this);
		mlist = new Array();
		breaks = new Array();
		pathTimer = 0;
	}

	function spawn(c, v) {
		var m = dmanager.attach("matchNumber" + v, Const.PLAN_MATCH);
		m._x = c.mc._x + 17;
		m._y = c.mc._y + 10;
		m.play();
		mlist.push({mc: m, t: 1});
	}

	function update(delta:Float) {
		var i = 0;
		while (i < mlist.length) {
			var m = mlist[i];
			m.t -= Timer.deltaT;
			if (m.t < 0) {
				m.mc._alpha -= Timer.tmod * 8;
				if (m.mc._alpha <= 0) {
					mlist.splice(i--, 1);
					m.mc.removeMovieClip();
				}
			}
			i++;
		}

		for (var p
		in path
	)
		{
			//			p._alpha = 30+50*Math.abs(Math.sin(pathTimer)) ;
		}
		pathTimer += 0.3

		colorTime += Timer.tmod / 5;
		var c = int((Math.sin(colorTime) + 1) * 25);
		current.color.setTransform({
			ra: 100,
			rb: c,
			ba: 100,
			bb: c,
			ga: 100,
			gb: c,
			aa: 100,
			ab: 0
		});

		var i = 0;
		while (i < breaks.length) {
			var b = breaks[i];
			b.mc._alpha -= 30 * Timer.tmod;
			if (b.mc._alpha <= 0) {
				breaks.splice(i--, 1);
				b.destroy();
			}
			i++
		}
	}

	function explosion(x, y) {
		var fx = dmanager.attach("explosion", Const.PLAN_FX);
		fx._x = x + Const.CARD_WIDTH / 2;
		fx._y = y + Const.CARD_HEIGHT / 2;
		var scale = Std.random(40) + 80;
		fx._xscale = scale * (Std.random(2) * 2 - 1);
		fx._yscale = scale;
	}

	function cardSelect(c) {
		if (current == null) {
			current = c;
			colorTime = 0;
		} else {
			if (level.breakCards(c, current)) {
				explosion(c.mc._x, c.mc._y);
				explosion(current.mc._x, current.mc._y);
				c.desactivate();
				current.desactivate();
				breaks.push(c);
				breaks.push(current);
				if (!level.canBreak())
					KKApi.gameOver(level.combis);
			}
			current.color.reset();
			current = null;
		}
		mouseMove();
	}

	function release() {
		if (current != null) {
			current.color.reset();
			current = null;
			clearPath();
			mouseMove();
		}
	}

	function mouseMove() {
		var xm = Std.xmouse() - Const.BASE_X;
		var ym = Std.ymouse() - Const.BASE_Y;
		if (xm < 0 || ym < 0) {
			activePath(null);
			return;
		}
		var x = int(xm / Const.CARD_WIDTH);
		var y = int(ym / Const.CARD_HEIGHT);
		if (x >= Const.LVL_WIDTH || y >= Const.LVL_HEIGHT) {
			activePath(null);
			return;
		}
		activePath({x: x, y: y});
	}

	function activePath(target) {
		clearPath();
		if (current == null || target == null || (target.x == current.x && target.y == current.y))
			return;
		var dx = current.x - target.x;
		var dy = current.y - target.y;

		var x, y;

		var npath1 = level.pathLength(current, target);
		var npath2 = level.pathLength(target, current);
		if (npath1 < npath2)
			tracePath(current, target);
		else
			tracePath(target, current);
	}

	function attachPath(x, y, t) {
		var s = (level.tbl[x][y] == null) || t >= 3;
		var p = dmanager.attach("link", Const.PLAN_PATH);
		p.gotoAndStop(string(t + 1));
		p._x = Const.BASE_X + (x + 0.5) * Const.CARD_WIDTH;
		p._y = Const.BASE_Y + (y + 0.5) * Const.CARD_HEIGHT;
		var c = new Color(p);
		if (!s)
			c.setRGB(0xFF0000);
		path.push(p);
		return p;
	}

	function tracePath(c1, c2) {
		var x, y;
		var p;
		y = c1.y;

		if (c1.x == c2.x) {
			p = attachPath(c1.x, c1.y, 3);
			if (c1.y > c2.y)
				p._yscale = -100;
		} else {
			p = attachPath(c1.x, c1.y, 4);
			if (c1.x > c2.x)
				p._xscale = -100;
		}

		if (c1.x < c2.x) {
			x = c1.x + 1;
			while (x < c2.x) {
				attachPath(x, y, 0);
				x++;
			}
		} else if (c1.x == c2.x)
			x = c1.x;
		else {
			x = c1.x - 1;
			while (x > c2.x) {
				attachPath(x, y, 0);
				x--;
			}
		}

		if (c1.x != c2.x && c1.y != c2.y) {
			p = attachPath(x, y, 2);
			if (c1.y > c2.y)
				p._yscale = -100;
			if (c1.x < c2.x)
				p._xscale = -100;
		}

		if (c1.y < c2.y) {
			y = c1.y + 1;
			while (y < c2.y) {
				attachPath(x, y, 1);
				y++;
			}
		} else {
			y = c1.y - 1;
			while (y > c2.y) {
				attachPath(x, y, 1);
				y--;
			}
		}

		if (c1.y == c2.y) {
			p = attachPath(c2.x, c2.y, 4);
			if (c1.x < c2.x)
				p._xscale = -100;
		} else {
			p = attachPath(c2.x, c2.y, 3);
			if (c1.y < c2.y)
				p._yscale = -100;
		}
	}

	function clearPath() {
		var i;
		for (i in 0...path.length) {
			path[i].removeMovieClip();
		}
		path = new Array();
	}

	public function destroy():Void {
		dmanager.destroy();
	}
}
