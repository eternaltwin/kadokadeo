package kanjisnightmare;

import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;
import mt.Timer;
import mt.bumdum.Sprite;

class Bonus extends Sprite {
	var UNIQUE:Int;

	public var id:Int;

	var time:Float;

	public function new(mc, n:Int) {
		super(mc);
		mc.play();
		mc.loop = true;
		Cs.game.bonusList.push(this);
		var vanish = root.attachMovie("FXVanish");
		vanish.play();
		vanish.removeOnFrame = 60;
		time = 300;

		if (n == 25 || n == 8) {
			if (UNIQUE == null)
				UNIQUE = n;
			else
				n = UNIQUE;
		}

		id = n;
	}

	public override function update() {
		time -= Timer.tmod;
		if (time < 10) {
			root._alpha = time * 10;
			if (time < 0)
				kill();
		}

		super.update();
	}

	public function take() {
		var pid = null;
		var sc = null;
		switch (id) {
			case 1:
				sc = Cs.C200;
				pid = 0;
			case 2:
				sc = Cs.C1000;
				pid = 0;
			case 3:
				sc = Cs.C5000;
				pid = 0;
			case 4:
				Cs.game.hero.incStar(20);
				pid = 1;
			case 5:
				Cs.game.hero.incStar(50);
				pid = 1;
			case 6:
				Cs.game.hero.incKunai(1);
				pid = 1;
			case 7:
				Cs.game.hero.hpUp();
				pid = 1;
			case 8:
				Cs.game.hero.initAura();
				pid = 1;
			case _:
				Cs.game.hero.optList[id - 20] = true;
				Cs.game.hero.updateIcons();
				pid = 1;
				if (id == 24) {
					Hero.SPEED *= 1.5;
				}
		}
		//

		switch (pid) {
			case 0:
				for (i in 0...12) {
					var p = Cs.game.newPart("partSpark");
					var a = Seed.randVfx() * 6.28;
					var d = Seed.randVfx() * Cs.S(6 + 18 * (1 - (i / 24)));
					p.x = root._x + Math.cos(a) * d;
					p.y = root._y + Math.sin(a) * d;
					p.timer = 10 + Seed.randVfx() * 10;
					p.sleep = Math.max(0, Math.pow(i * 30, 0.5) - 8);
					p.setScale(30 + Seed.randVfx() * 100 - p.sleep * 2);
					p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
					p.root.onFrame.set(6, function() {
						p.root.gotoAndPlay(2);
					});
				}
			case 1:
				for (i in 0...3) {
					var p = Cs.game.newPart("partCircle");
					p.x = root._x;
					p.y = root._y;
					p.root._rotation = Seed.randVfx() * 360;
					p.timer = 18 - i * 3;
					p.vs = 6 + i * 8;
					p.vr = 8 + i * 12;
				}
			case 2:
				var max = 8;
				for (i in 0...max) {
					for (n in 0...2) {
						var p = Cs.game.newPart("partLight");
						p.root.play();
						p.root.loop = true;
						p.x = root._x;
						p.y = root._y;
						var a = ((i + 0.5 * n) / max) * 6.28;
						var speed = Cs.S(3 + n * 2);
						p.vx += Math.cos(a) * speed;
						p.vy += Math.sin(a) * speed;
						p.timer = 26 + Seed.randVfx() * 4 - n * 10;
						p.frict = 0.9;
					}
				}
		}

		if (sc != null) {
			if (Cs.game.hero.optList[3])
				sc = KKApi.cmult(sc, KKApi.const(2));
			addScore(sc);
		}

		Cs.game.stats.opt[id - 1]++;

		kill();
	}

	function addScore(n) {
		Cs.game.genScore(root._x, root._y, n);
	}

	public override function kill() {
		Cs.game.bonusList.remove(this);
		root.removeMovieClip();
	}
}
