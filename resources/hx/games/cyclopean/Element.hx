package cyclopean;

// mcElement as the game shows it: frames 1-3 (gems) hold a mcLightFlip and 4 smoke blobs that play on their own,
// frame 4 (time) is still, frame 5 (egg) is sprite 168 playing with the colour of its mcBille set by the code
class ElementMC extends MC {
	public function new(id:Int, sid:Int) {
		super();
		switch (id) {
			case 0 | 1 | 2:
				var l = attach(new MC("lightflip"));
				place(l, Data.ELEM_LIGHT);
				l.playing = true;
				attach(new MC("elem")).gotoAndStop(id + 1);
				var smoke = attach(new MC());
				place(smoke, Data.ELEM_SMOKE);
				for (k in 0...4)
					smoke.attach(new BlobMC(k));
			case 3:
				attach(new MC("elem")).gotoAndStop(4);
			default:
				var egg = attach(new MC("egg" + (sid + 1)));
				egg.playing = true;
		}
	}

	// a child placed by the timeline (matrices of pure scale here)
	public static function place(mc:MC, m:Array<Float>):Void {
		mc._xscale = m[0] * 100;
		mc._yscale = m[3] * 100;
		mc._x = m[4];
		mc._y = m[5];
	}
}

// sprite 165 in sprite 166: its frame 1 does gotoAndPlay(random(_totalframes - 1) + 2) (the unseeded random() of
// Flash: visual), so frame 1 is never shown and each blob loops from a random frame; placed with the blend mode
// "screen"
class BlobMC extends MC {
	public function new(k:Int) {
		super("blob" + k);
		gotoAndPlay(Seed.randomVfx(_totalframes - 1) + 2);
		spr.blendMode = pixi.core.Pixi.BlendModes.SCREEN;
	}

	override function advance():Void {
		if (removed)
			return;
		var f = _currentframe + 1;
		_currentframe = f > _totalframes ? Seed.randomVfx(_totalframes - 1) + 2 : f;
	}
}

class Element {
	public static inline var RAY = 12;
	public static inline var BUMP = 8;

	public var flActive:Bool;

	public var x:Float;
	public var y:Float;
	public var id:Int;
	public var sid:Int;
	public var root:MC;

	public function new(px:Float, py:Float, pid:Int) {
		x = px;
		y = py;
		id = pid;
		Cs.game.eList.push(this);
		if (id == 4)
			sid = Seed.random(7);

		flActive = false;
	}

	public function collide(ball:Ball):Void {
		#if debug
		Cs.game.stats.elements[id]++;
		#end
		switch (id) {
			case 0 | 1 | 2: // EXTRA POINTS
				Cs.game.addScore(KKApi.val(Cs.SCORE_BONUS[id]));
				gerb(16);
				kill();

			case 3: // EXTRA TIME
				Cs.game.gameTimer = Math.min(Cs.game.gameTimer + Cs.BONUS_TIME, Cs.TIME_MAX);
				explode(16);
				kill();

			case 4: // EXTRA BALL
				var b = Cs.game.genBille(x, y);
				b.setColor(sid + 1);
				kill();

				// (5: EXTRA ZOOM, 6: BUMPER: not in Cs.SPAWN)
		}
	}

	// the particles: visual random
	function explode(max:Int):Void {
		for (i in 0...max) {
			var p = Cs.game.newPart("mcLightFlip");
			var a = (i / max) * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = 1 + Seed.randVfx() * 4;
			var ray = 10;

			p.x = x + ca * ray;
			p.y = y + sa * ray;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.timer = 10 + Seed.randVfx() * 120;
			p.fadeType = 0;
			p.weight = 0.1 + Seed.randVfx() * 0.3;
			p.bouncer = new Bouncer(p);
		}
	}

	function gerb(max:Int):Void {
		for (i in 0...max) {
			var p = Cs.game.newPart("partFlamb");
			var a = (i / max) * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = 0.5 + Seed.randVfx() * 3;
			var ray = 4;

			p.x = x + ca * ray;
			p.y = y + sa * ray;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.timer = 10 + Seed.randVfx() * 15;
			p.fadeType = 0;
			p.setScale(30 + Seed.randVfx() * 50);
			p.root.gotoAndStop(id + 1);
			p.bouncer = new Bouncer(p);
		}

		var p = Cs.game.newPart("partSpark");
		p.x = x;
		p.y = y;
		p.setScale(150);
		p.updatePos();
	}

	public function kill():Void {
		if (root != null)
			root.removeMovieClip();
		Cs.game.eList.remove(this);
	}

	public function attach():Void {
		root = Cs.game.dm.add(new ElementMC(id, sid), Game.DP_ELEMENT);
		root._x = x;
		root._y = y;
		flActive = true;
	}

	public function detach():Void {
		flActive = false;
		root.removeMovieClip();
	}
}
