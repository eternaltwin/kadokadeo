package kslash;

class Soldier extends Runner {
	var stMaxShot:Int;

	public function new(mc) {
		super(mc);
		stShootWait = 36;
		stDrop.push({w: 1, id: 10});
	}

	public function setLevel(n) {
		stLevel = n;
		switch (stLevel) {
			case 1:
				hp = 10;
				score = Cs.C30;
				stClimbWait = 32;
				stTossClimb = 12;
				stTossSmart = 4;
				stTossShoot = null;
				speed = 2 * Cs.NEW_GEN_SCALE;
				stDrop.push({w: 70, id: 4});
			// stDrop.push({w:500,id:10});
			case 2:
				hp = 40;
				score = Cs.C100;
				stTossClimb = 12;
				stTossSmart = 3;
				stTossShoot = 10;
				stMaxShot = 3;
				speed = 3 * Cs.NEW_GEN_SCALE;
				stDrop.push({w: 50, id: 4});
				stDrop.push({w: 30, id: 5});
				stDrop.push({w: 20, id: 8});
				stDrop.push({w: 1, id: 9});
			case 3:
				hp = 60;
				score = Cs.C200;
				stTossClimb = 6;
				stTossSmart = 1;
				stTossShoot = 4;
				stMaxShot = 1;
				stShootWait = 12;
				speed = 5 * Cs.NEW_GEN_SCALE;
				flSpike = true;
				stDrop.push({w: 40, id: 5});
				stDrop.push({w: 20, id: 6});
				stDrop.push({w: 20, id: 7});
				stDrop.push({w: 1, id: 9});
		}
		root.gotoAndStop(stLevel);
	}

	public override function update() {
		super.update();
		switch (step) {
			case Cs.ST_SHOOT:
				if ((Cs.game.hero.x - x) * sens < 0) {
					setSens(-sens);
				}
		}
	}

	public override function crossSquare() {
		super.crossSquare();

		if (step == Cs.ST_NORMAL) {
			if (Cs.game.checkFree(x + sens, y + 1)) {
				if (isSmart()) {
					if (Cs.game.hero.y > y + 3) {} else {
						var dif = Cs.game.hero.x - x;
						if (Std.int(dif / Math.abs(dif)) == sens) {
							tryJumpFront();
						} else {
							setSens(-sens);
						}
					}
				} else {
					var rnd = Cs.random(7);
					switch (rnd) {
						case 1 | 2:
							tryJumpFront();
						case _:
							setSens(-sens);
					}
				}
			} else {
				if (stTossShoot != null && Cs.random(stTossShoot) == 0) {
					var d = getDist(Cs.game.hero);
					if (d < 180 * Cs.NEW_GEN_SCALE) {
						initStep(Cs.ST_SHOOT);
					}
				}
			}
		}
	}

	public override function shoot() {
		var d = getDist(Cs.game.hero);
		var a = getAng(Cs.game.hero);
		var speed = 6 * Cs.NEW_GEN_SCALE;
		var max = stMaxShot;
		for (i in 0...max) {
			var da = (i / (max - 1) - 0.5) * 0.4;
			if (max == 1)
				da = 0;
			var s = new Kunai(Cs.game.mdm.attach("mcKunai", Game.DP_SHOOT));
			s.root._x = root._x;
			s.root._y = root._y;
			s.root._rotation = (a + da) / 0.0174;
			s.vx = Math.cos(a + da) * speed;
			s.vy = Math.sin(a + da) * speed;
			s.x = x;
			s.y = y;
			s.dx = dx;
			s.dy = dy;
		}
		super.shoot();
	}
}
