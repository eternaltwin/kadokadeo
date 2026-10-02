package kslash;

class Bonus {
	public var root:Clip;

	public var id:Int;
	public var time:Float;

	public function new(mc:Clip) {
		root = mc;
		Cs.game.bList.push(this);
		time = 300;
	}

	public function update() {
		time -= Timer.tmod;
		if (time < 10) {
			root._alpha = time * 10;
			if (time < 0)
				kill();
		}
	}

	public function setId(n:Int) {
		id = n;
		root.gotoAndStop(id);
	}

	public function take() {
		var pid:Null<Int> = null;
		switch (id) {
			case 1:
				addScore(Cs.C200);
				pid = 0;
			case 2:
				addScore(Cs.C1000);
				pid = 0;
			case 3:
				addScore(Cs.C5000);
				pid = 0;
				// (no break in the original: the red gem also gives the 20 shurikens of case 4)
				Cs.game.hero.incStar(20);
				pid = 1;
			case 4:
				Cs.game.hero.incStar(20);
				pid = 1;
			case 5:
				Cs.game.hero.incStar(50);
				pid = 1;
			case 6 | 7 | 8:
				Cs.game.optList[id - 6] = true;
				Cs.game.updateIcons();
				pid = 1;
			case 9:
				for (i in 0...18) {
					Cs.game.newMonster(3);
				}
				addScore(Cs.C8000);
			case 10:
				Cs.game.hero.initSupa();
		}
		//

		switch (pid) {
			case 0:
				for (i in 0...12) {
					var p = Cs.game.newPart("partSpark");
					var a = Seed.randVfx() * 6.28;
					var d = Seed.randVfx() * (6 + 18 * (1 - (i / 24)));
					p.root._x = root._x + Math.cos(a) * d;
					p.root._y = root._y + Math.sin(a) * d;
					p.t = 10 + Seed.randVfx() * 10;
					p.wt = Math.max(0, Math.pow(i * 30, 0.5) - 8);
					p.scale = 30 + Seed.randVfx() * 100 - p.wt * 2;
					p.root._xscale = p.scale;
					p.root._yscale = p.scale;
					p.ft = 0;

					p.root._visible = false;
				}
			case 1:
				for (i in 0...3) {
					var p = Cs.game.newPart("partCircle");
					p.root._x = root._x;
					p.root._y = root._y;
					p.root._rotation = Seed.randVfx() * 360;
					p.t = 18 - i * 3;
					p.vs = 6 + i * 8;
					p.vr = 8 + i * 12;
				}
			case _:
		}

		Cs.game.stats.opt[id - 1]++;

		kill();
	}

	function addScore(n:Int) {
		Cs.game.addScore(n);
		var p = Cs.game.newScore(KKApi.val(n));
		p.root._x = root._x;
		p.root._y = root._y;
		p.vy = -1;
		p.t = 24;
	}

	function kill() {
		Cs.game.bList.remove(this);
		root.removeMovieClip();
	}
}
