package ktrain;

// Gem.hx of the original: the gems beside the track (5000, 8000, 12000 points), rarely a piouz on the track (24000
// points if the driver catches it, feathers if the train hits it), placed every 1500 to 2250 pixels times a factor
// drawn at each station
class Gem {
	static var lastX = 0.0;
	static var game:Game;
	static var addObject:Float;
	static var factor = 1.0;

	public static var lock = false;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		lastX = 0.0;
		game = null;
		addObject = 0;
		factor = 1.0;
		lock = false;
	}

	public static function init(g:Game) {
		game = g;
		addObject = KKApi.val(Const.ADD_GEM);
	}

	public static function update(scroll:Float) {
		if (lock)
			return;
		if (scroll < 0)
			return;
		if (Const.SPEED <= 0)
			return;
		add(scroll);
	}

	public static function newFactor() {
		switch (Const.random(3)) {
			case 0:
				factor = KKApi.val(Const.ADD_GEM_F1);
			case 1:
				factor = KKApi.val(Const.ADD_GEM_F2);
			case 2:
				factor = KKApi.val(Const.ADD_GEM_F3);
		}
	}

	static function add(scroll:Float) {
		addObject -= scroll;

		if (addObject < 0) {
			var g = KKApi.val(Const.ADD_GEM);
			addObject = (g + Const.random(Std.int(g / 2))) * factor;

			var r = Const.random(KKApi.val(Const.PIOUZ_RANDOM));
			#if debug
			if (game.testPiouz)
				r = 1;
			#end
			if (r == 1) {
				addPiouz();
				return;
			}
			addGem();
		}
	}

	static function addPiouz() {
		var mc = game.dm.attach("mcTresors", Const.DP_PIOUZ);
		mc.gotoAndStop(4);
		mc.piouz = true;
		mc.gem = true;
		lastX = mc._x = Const.CENTER_X;
		// (at the distance left before the next object: Scroller.cycles)
		Scroller.addGem(mc, Scroller.cycles);
		Scroller.next(mc);
	}

	static function addGem() {
		var mc = game.dm.attach("mcTresors", Const.DP_GEM);
		mc.gotoAndStop(Const.Gems[Const.random(Const.Gems.length)]);
		mc.gem = true;
		lastX = mc._x = Scroller.getX(mc);
		mc.y = mc._y = Const.OBJECTS;
		if (Scroller.hitRoot(mc) || Station.hitTest(mc)) {
			mc.removeMovieClip();
			mc = null;
			return;
		}
		Scroller.addGem(mc);
		Scroller.next(mc);
	}

	// the train hits the piouz: it shrinks and fades (still a gem the driver can catch until it is gone), 50 feathers
	public static function piouzCrash(mc:MC) {
		if (!mc.piouz)
			return;

		mc.piouz = false;
		#if debug
		game.stats.piouzCrash++;
		#end
		var p = new Phys(mc);
		p.timer = 20;
		p.fadeType = 4;
		p.vsc = 0.8;

		for (i in 0...50) {
			var m = game.dm.attach("mcPlume", Const.DP_GEM);
			m._x = mc._x;
			m._y = mc._y;
			m._rotation = Const.randomVfx(360);
			var p = new Phys(m);
			p.timer = 20;
			p.fadeType = 4;
			var s = Const.SPEED;
			p.vx = if (Const.randomVfx(2) != 1) Const.randomVfx(Math.ceil(Const.SPEED)) + 2 else -(Const.randomVfx(Math.ceil(Const.SPEED)) + 2);
			p.vy = if (Const.randomVfx(2) != 1) Const.randomVfx(Math.ceil(Const.SPEED)) + 2 else -(Const.randomVfx(Math.ceil(Const.SPEED)) + 2);
		}
	}

	// the driver catches a gem: its price rises and fades, the gem fades
	public static function bonus(mc:MC) {
		if (!mc.gem)
			return;

		mc.gem = false;
		var price = switch (mc._currentframe) {
			case 1: Const.GEM1;
			case 2: Const.GEM2;
			case 3: Const.GEM3;
			case _: Const.PIOUZ;
		}
		// mcBonus with b.smc.text = price: the picture of that price
		var b = game.dm.attach("mcBonus" + KKApi.val(price), Const.DP_INTER);
		#if debug
		if (price == Const.PIOUZ)
			game.stats.piouz++;
		else
			game.stats.gems++;
		#end
		b._x = mc._x;
		b._y = mc._y;
		game.addScore(price);
		var p = new Phys(b);
		p.timer = 15;
		p.fadeType = 4;
		p.vsc = 1.1;

		var p = new Phys(mc);
		p.timer = 10;
		p.fadeType = 4;
	}
}
