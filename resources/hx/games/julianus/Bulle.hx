package julianus;

class Bulle {
	static var gravity = 0.01;
	static var border_pow = 0.3;

	var game:Game;

	public var mc:MC;

	var ts:Float;

	public var px:Float;
	public var py:Float;
	public var vx:Float;
	public var vy:Float;
	public var size:Float;

	var t:Float;
	// picture of the bubble: index in Data.BULLE_LEVELS (-1: none yet)
	var level:Int = -1;

	public function new(g:Game, x:Float, y:Float) {
		game = g;
		// (dmanager.attach("bulle"): its picture at the resolution of its size, see showLevel)
		mc = game.dmanager.add(new MC(), Const.PLAN_BULLE);
		setSize(17);
		ts = 0;
		px = x;
		py = y;
		t = 0;
		vx = 0;
		vy = 0;
		ts = 0;
	}

	public function setSize(s:Float):Void {
		size = s;
		mc._xscale = s;
		mc._yscale = s;
		showLevel();
	}

	// the bubble is drawn from 17 % to 100 % and more: the picture of the resolution closest above its size (like
	// mipmaps; Flash drew the vector shape at any scale)
	function showLevel():Void {
		var lv = Data.BULLE_LEVELS;
		var i = Game.level(lv, size);
		if (i != level) {
			level = i;
			mc.setFrames("bulle" + Std.int(lv[i] * 100), Game.K * lv[i]);
		}
	}

	public function kill():Void {
		game.attachPop(px, py, size);
		mc.removeMovieClip();
	}

	public function separate():Void {
		game.attachPop(px, py, size);

		game.stats.k++;

		var s = Math.sqrt(size * size / 3);
		if (s < 17) {
			mc.removeMovieClip();
			game.bulles.remove(this);
			return;
		}

		var v = Math.sqrt(vx * vx + vy * vy);
		var tmp;
		tmp = vx;
		vx = -vy * (v + 2) / v;
		vy = tmp * (v + 2) / v;

		var a = Const.q(Math.atan2(vy, vx));
		var dx = Const.q(Math.cos(a)) * s / 2;
		var dy = Const.q(Math.sin(a)) * s / 2;

		var b = new Bulle(game, px - dx, py - dy);
		px += dx;
		py += dy;
		b.setSize(s);
		b.vx = -vx;
		b.vy = -vy;
		setSize(s);
		game.bulles.push(b);
		mc._x = px;
		mc._y = py;
		b.mc._x = b.px;
		b.mc._y = b.py;
	}

	public function update(dx:Float):Void {
		var friction = Const.POW_098;
		vx *= friction;
		vy *= friction;
		vy += gravity * Game.TMOD;
		px += dx + vx * Game.TMOD;
		py += vy * Game.TMOD;
		if (py < size / 2) {
			py = size / 2;
			vy = Math.abs(vy);
		}
		if (py > Const.MAXY - size / 2) {
			py = Const.MAXY - size / 2;
			vy = -Math.abs(vy);
		}
		if (px < size / 2) {
			px = size / 2;
			vx = Math.abs(vx);
		}
		if (px < size + size / 2)
			vx += Game.TMOD * border_pow;
		if (py > Const.MAXY - size)
			vy -= Game.TMOD * border_pow;
		else if (py < size)
			vy += Game.TMOD * border_pow;

		// (the bubble absorbed is removed during the loop: the next one waits for the next frame, like the original)
		var i = 0;
		while (i < game.bulles.length) {
			var b = game.bulles[i];
			if (b != this) {
				var ddx = b.px - px;
				var ddy = b.py - py;
				var d = Math.sqrt(ddx * ddx + ddy * ddy);
				var s = b.size + size;
				if (d < s / 2) {
					if (b.size > size) {
						vx = b.vx;
						vy = b.vy;
						px = b.px;
						py = b.py;
					}
					ts = 5;
					game.stats.f++;
					setSize(Math.sqrt(size * size + b.size * b.size));
					b.size = size;
					b.px = px;
					b.py = py;
					b.kill();
					game.bulles.splice(i--, 1);
				}
			}
			i++;
		}

		// (the wobble: only the picture)
		var a = Math.atan2(vy, vx);
		t += Game.TMOD * ts / 10;
		ts *= Const.POW_095;
		if (ts < 1)
			ts = 1;

		var spow = size * ts / 20;
		mc._xscale = size + Math.cos(a + t) * spow;
		mc._yscale = size + Math.sin(a + t) * spow;
		mc._x = px;
		mc._y = py;
	}
}
