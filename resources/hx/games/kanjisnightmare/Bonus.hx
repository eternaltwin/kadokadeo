package kanjisnightmare;

class Bonus extends Sprite {
	// the aura (8) and the kick (25) share a slot: the first one dropped is the only one of the game
	public static var UNIQUE:Null<Int>;

	public var id:Int;
	public var time:Float;

	public function new(mc:ASprite) {
		super(mc);
		Cs.game.bonusList.push(this);
		time = 300;
	}

	override public function update() {
		time -= Timer.tmod;
		if (time < 10) {
			root._alpha = time * 10;
			if (time < 0) {
				kill();
				return;
			}
		}
		super.update();
	}

	public function setId(n:Int) {
		if (n == 25 || n == 8) {
			if (UNIQUE == null)
				UNIQUE = n;
			else
				n = UNIQUE;
		}
		id = n;
		root.gotoAndStop(id);
	}

	public function take() {
		var hero = Cs.game.hero;
		var pid:Null<Int> = null;
		var sc:Null<Int> = null;
		switch (id) {
			case 1:
				sc = Cs.C200;
				pid = 0;
			case 2:
				sc = Cs.C1000;
				pid = 0;
			case 3:
				// no break in the original: also gives the 20 shurikens of the bonus 4
				sc = Cs.C5000;
				pid = 0;
				hero.incStar(20);
				pid = 1;
			case 4:
				hero.incStar(20);
				pid = 1;
			case 5:
				hero.incStar(50);
				pid = 1;
			case 6:
				hero.incKunai(1);
				pid = 1;
			case 7:
				hero.hpUp();
				pid = 1;
			case 8:
				hero.initAura();
				pid = 1;
			default:
				hero.optList[id - 20] = true;
				hero.updateIcons();
				pid = 1;
				if (id == 24)
					Hero.SPEED *= 1.5;
		}

		var bx = root._x;
		var by = root._y;
		switch (pid) {
			case 0:
				for (i in 0...12) {
					var p = Cs.game.newPart("partSpark");
					var a = Seed.randVfx() * 6.28;
					var d = Seed.randVfx() * (6 + 18 * (1 - (i / 24)));
					p.x = bx + Math.cos(a) * d;
					p.y = by + Math.sin(a) * d;
					p.timer = 10 + Seed.randVfx() * 10;
					p.wait = Math.max(0, Math.pow(i * 30, 0.5) - 8);
					p.setScale(30 + Seed.randVfx() * 100 - p.wait * 2);
				}
			case 1:
				for (i in 0...3) {
					var p = Cs.game.newPart("partCircle");
					p.x = bx;
					p.y = by;
					p.root._rotation = Seed.randVfx() * 360;
					p.timer = 18 - i * 3;
					p.vs = 6 + i * 8;
					p.vr = 8 + i * 12;
				}
			default:
		}

		if (sc != null) {
			if (hero.optList[3])
				sc = KKApi.cmult(sc, KKApi.const(2));
			Cs.game.genScore(bx, by, sc);
		}
		Cs.game.stats.opt[id - 1]++;
		kill();
	}

	override public function kill() {
		dead = true;
		Cs.game.bonusList.remove(this);
		root.removeMovieClip();
		Cs.game.sList.remove(this);
	}
}
