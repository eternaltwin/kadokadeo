package toymaniak;

import toymaniak.Gfx.RailBackMC;
import toymaniak.Gfx.RailFrontMC;

class Rail {
	var game:Game;

	public var pos:Int;

	var front:RailFrontMC;
	var back:RailBackMC;
	var speed:Float;
	var delta:Float;
	var broken:Bool;
	var last:Null<Int>;

	public var ncombos:Int;

	var next:Null<Int> = null;
	var toys:Array<Toy>;

	public var cruncher:MC;

	public function new(g:Game, p:Int) {
		game = g;
		pos = p;
		last = null;
		delta = 0;
		ncombos = 0;
		broken = false;

		back = game.dmanager.add(new RailBackMC(), 0);
		back._x = 300;
		back._y = Const.RAIL_Y_BASE + p * Const.RAIL_Y_DELTA;

		front = game.dmanager.add(new RailFrontMC(), 2);
		front._x = back._x;
		front._y = back._y;
		// (front.t0.gotoAndStop("1"), front.t1.gotoAndStop("2"): the two pictures of the treads, RailFrontMC)
		cruncher = front.cruncher;

		updateCounter();
		toys = new Array();
		speed = 50;
		mt.Timer.tmod = 1;
		for (i in 0...5) {
			toys.push(new Toy(game, -1, this, false));
			update();
		}
		speed = (5 + p) * 0.1;
	}

	function updateCounter() {
		var s = Std.string(ncombos);
		while (s.length < 3)
			s = "0" + s;
		back.field.text = s;
		if (last != null)
			back.field.textColor = Const.COLORS[last];
	}

	public function active(t:Toy) {
		if (t.t == -1)
			return;
		switch (t.t) {
			case -1:
				return;
			case Const.BONUS_X2:
				// (game.stats.$b[pos].push(ncombos): stats is null, nothing in Flash)
				#if debug
				game.cov.x2++;
				#end
				ncombos *= 2;
				back.green.play();
				back.red.play();
			case Const.BONUS_PLUS20:
				#if debug
				game.cov.plus20++;
				#end
				ncombos += 20;
				back.green.play();
				back.red.play();
			case Const.BONUS_SPEED:
				#if debug
				game.cov.speed++;
				#end
				speed *= Const.SPEED_DELTA;
				if (speed > Const.MAXSPEED)
					speed = Const.MAXSPEED;
			default:
				if (t.t == last || last == null) {
					back.green.play();
					ncombos++;
				} else {
					#if debug
					game.cov.breaks++;
					#end
					back.red.play();
					ncombos = 1;
				}
				game.addScore(Const.C10 * ncombos);
				last = t.t;
		}
		if (ncombos > 199) {
			#if debug
			game.cov.cap++;
			#end
			ncombos = 199;
		}
		updateCounter();
	}

	function genType():Int {
		if (game.time >= Const.GAMETIME)
			return -1;
		if (next != null) {
			var o = next;
			game.nbonuses++;
			next = null;
			return o;
		}
		return Tools.randomProbas(Const.PROBAS) - 1;
	}

	public function update():Bool {
		var dx = game.speed * speed * mt.Timer.tmod;

		if (Seed.random(Std.int((1000 + game.nbonuses * 200) / mt.Timer.tmod)) == 0)
			next = 4 + Tools.randomProbas(Const.PROBAS_OPTIONS);

		if (broken) {
			speed *= Math.pow(0.97, mt.Timer.tmod);
			if (speed < 0.1)
				speed = 0;
		}

		if (toys[toys.length - 1].x <= 300)
			toys.push(new Toy(game, genType(), this, false));
		var ok = false;
		cruncher._y = -50;
		var i = 0;
		while (i < toys.length) {
			var t = toys[i];
			if (!t.update(dx))
				toys.splice(i--, 1);
			else if (t.t != -1)
				ok = true;
			i++;
		}

		delta -= dx;
		front.t0._x = Std.int(-300 + delta % 8);
		front.t1._x = Std.int(-308 - delta % 8);
		return ok;
	}
}
