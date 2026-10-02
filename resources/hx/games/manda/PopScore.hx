package manda;

// points won: the digits of scoreDigit grow (x then y), stay a second, shrink and go away
class PopScore {
	var halign:Bool;
	var valign:Bool;

	var max_size:Float;
	var xspeed:Float;
	var yspeed:Float;
	var xphase:Bool;
	var yphase:Bool;
	var pphase:Bool;
	var xtime:Float;
	var ytime:Float;
	var ptime:Float;

	var game:Game;
	var mc:ASprite;
	var digits:Array<Pic>;
	var fupdate:Void->Void;

	public function new(game:Game, x:Float, y:Float, n:Int, mc:ASprite) {
		this.game = game;
		mc._x = x;
		mc._y = y;
		mc._xscale = 0;
		mc._yscale = 0;

		xtime = 0;
		ytime = 0;
		ptime = 1;
		max_size = 25 + Math.abs(n) / 100;
		max_size = Math.min(Math.max(40, max_size), 70);

		xspeed = 4;
		yspeed = 4;
		xphase = true;
		yphase = true;
		pphase = false;

		fupdate = update;
		game.updates.push(fupdate);

		this.mc = mc;
		halign = true;
		valign = true;
		digits = [];
		init(n);
	}

	inline function width(d:Pic):Float {
		var b = Data.DIGIT;
		return b[(d.cur - 1) * 4 + 2] - b[(d.cur - 1) * 4];
	}

	inline function height(d:Pic):Float {
		var b = Data.DIGIT;
		return b[(d.cur - 1) * 4 + 3] - b[(d.cur - 1) * 4 + 1];
	}

	function attachDigit(v:Int):Pic {
		var d = new Pic("digit");
		d.show(v + 1);
		mc.addChild(d);
		digits.push(d);
		return d;
	}

	function init(v:Int) {
		var x = 0.0;
		if (v == 0) {
			var d = attachDigit(0);
			x -= -width(d);
			d._x = -x;
		} else {
			while (v > 0) {
				var d = attachDigit(v % 10);
				x -= width(d);
				d._x = x;
				v = Std.int(v / 10);
			}
		}
		if (halign) {
			x = Math.abs(x / 2);
			for (d in digits)
				d._x += x;
			x *= max_size / 100;
			if (mc._x - x < 10)
				mc._x = 10 + x;
			if (mc._x + x > 290)
				mc._x = 290 - x;
		}
		if (valign) {
			var y = height(digits[0]) / 2;
			for (d in digits)
				d._y -= y;
		}
	}

	function update() {
		if (pphase) {
			ptime -= Timer.deltaT;
			if (ptime < 0) {
				xphase = true;
				yphase = true;
				pphase = false;
			} else
				return;
		}

		if (xphase)
			xtime += Timer.deltaT * xspeed;
		if (yphase)
			ytime += Timer.deltaT * yspeed;

		mc._xscale = xtime * max_size;
		mc._yscale = ytime * max_size;

		if (ptime > 0) {
			if (xphase && xtime > 1) {
				xphase = false;
				if (!yphase)
					pphase = true;
				xspeed *= -1;
			}
			if (yphase && ytime > 1) {
				yphase = false;
				if (!xphase)
					pphase = true;
				yspeed *= -1;
			}
		}

		if ((xspeed < 0 && xtime <= 0.3) || (yspeed < 0 && ytime <= 0.3)) {
			game.updates.remove(fupdate);
			mc.removeMovieClip();
		}
	}
}
