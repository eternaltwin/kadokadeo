package kslash;

import pixi.core.text.Text;
import mt.Timer;

class Bonus {
	public var root:ASprite;

	var id:Int;
	var time:Float;

	public function new(mc) {
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

	public function setId(n) {
		id = n;
		root.gotoAndStop(id);
	}

	public function take() {
		var pid = null;
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

		switch (pid) {
			case 0:
				for (i in 0...12) {
					var p = Cs.game.newPart("partSpark");
					var a = Math.random() * 6.28;
					var d = Math.random() * (6 + 18 * (1 - (i / 24)));
					p.x = root._x + Math.cos(a) * d;
					p.y = root._y + Math.sin(a) * d;
					p.timer = 10 + Math.random() * 10;
					p.sleep = Math.max(0, Math.pow(i * 30, 0.5) - 8);
					p.scale = 30 + Math.random() * 100 - p.sleep * 2;
					p.fadeType = 0;
					p.root._visible = false;
				}
			case 1:
				for (i in 0...3) {
					var p = Cs.game.newPart("partCircle");
					p.x = root._x;
					p.y = root._y;
					p.root._rotation = Math.random() * 360;
					p.timer = 18 - i * 3;
					p.vs = 6 + i * 8;
					p.vr = 8 + i * 12;
				}
			case 2:
				var max = 8;
				for (i in 0...max) {
					for (n in 0...2) {
						var p = Cs.game.newPart("partLight");
						p.x = root._x;
						p.y = root._y;
						var a = ((i + 0.5 * n) / max) * 6.28;
						var speed = (3 + n * 2);
						p.vx += Math.cos(a) * speed;
						p.vy += Math.sin(a) * speed;
						p.timer = 26 + Math.random() * 4 - n * 10;
						p.frict = 0.9;
					}
				}
		}

		Cs.game.stats.opt[id - 1]++;
		kill();
	}

	public function addScore(n) {
		Cs.game.kkm.addScore(n);
		var p = Cs.game.newPart(null);
		p.x = root._x;
		p.y = root._y;
		p.vy = -1;
		p.timer = 24;
		p.field = new Text(Std.string(n), {
			fontFamily: "Arial",
			fill: 0xFFFFFF,
		});
	}

	public function kill() {
		Cs.game.bList.remove(this);
		root.removeMovieClip();
	}
}
