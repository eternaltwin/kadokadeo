package kslash;

class Soldier extends Runner {
	var stMaxShot:Null<Int>;

	public function new(mc:Clip) {
		super(mc);
		stShootWait = 36;
		stDrop.push({w: 1, id: 10});
	}

	public function setLevel(n:Int) {
		stLevel = n;
		switch (stLevel) {
			case 1:
				hp = 10;
				score = Cs.C30;
				stClimbWait = 32;
				stTossClimb = 12;
				stTossSmart = 4;
				stTossShoot = null;
				speed = 2;
				noSpikes();
				stDrop.push({w: 70, id: 4});
			case 2:
				hp = 40;
				score = Cs.C100;
				stTossClimb = 12;
				stTossSmart = 3;
				stTossShoot = 10;
				stMaxShot = 3;
				speed = 3;
				noSpikes();
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
				speed = 5;
				flSpike = true;
				stDrop.push({w: 40, id: 5});
				stDrop.push({w: 20, id: 6});
				stDrop.push({w: 20, id: 7});
				stDrop.push({w: 1, id: 9});
		}
		// skin of the level (the death pieces take the frame of b1)
		root.getClip("b1").gotoAndStop(stLevel);
	}

	override public function update() {
		super.update();
		switch (step) {
			case Cs.ST_SHOOT:
				if ((Cs.game.hero.x - x) * sens < 0)
					setSens(-sens);
		}
	}

	//
	override public function crossSquare() {
		super.crossSquare();

		if (step == Cs.ST_NORMAL) {
			if (Cs.game.checkFree(x + sens, y + 1)) {
				if (isSmart()) {
					if (Cs.game.hero.y > y + 3) {} else {
						var dif = Cs.game.hero.x - x;
						// (same square: 0 / 0 = NaN, int(NaN) = 0 like in Flash)
						if (Std.int(dif / Math.abs(dif)) == sens) {
							tryJumpFront();
						} else {
							setSens(-sens);
						}
					}
				} else {
					var rnd = Seed.random(7);
					switch (rnd) {
						case 0:
						case 1 | 2:
							tryJumpFront();
						default:
							setSens(-sens);
					}
				}
			} else {
				if (stTossShoot != null && Seed.random(stTossShoot) == 0) {
					var d = getDist(Cs.game.hero.root);
					if (d < 180) {
						initStep(Cs.ST_SHOOT);
					}
				}
			}
		}
	}

	override public function shoot() {
		var a = getAng(Cs.game.hero.root);
		var speed = 3;
		var max:Int = stMaxShot;
		for (i in 0...max) {
			var da = (i / (max - 1) - 0.5) * 0.4;
			if (max == 1)
				da = 0;
			var s = new Kunai(Clip.attach(Cs.game.mdm, "mcKunai", Game.DP_SHOOT));
			s.root._x = root._x;
			s.root._y = root._y;
			s.root._rotation = (a + da) / 0.0174;
			s.vx = Cs.q(Math.cos(a + da) * speed);
			s.vy = Cs.q(Math.sin(a + da) * speed);
			s.x = x;
			s.y = y;
			s.dx = dx;
			s.dy = dy;
		}
		super.shoot();
	}

	function noSpikes() {
		for (name in ["b3", "b4", "b5"])
			root.getClip(name).gotoAndStop(2);
	}
}
