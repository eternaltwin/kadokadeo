package kslash;

class Tanker extends Runner {
	public function new(mc:Clip) {
		super(mc);
		stLevel = 3;
		hp = 50;
		score = Cs.C300;
		stClimbWait = 12;
		stTossClimb = 6;
		stTossSmart = 2;
		stClimb = 36;
		speed = 4;
		stDrop.push({w: 40, id: 1});
		stDrop.push({w: 10, id: 2});
		stDrop.push({w: 30, id: 5});
		score = Cs.C100;
	}

	// ON
	// the shield stops the shurikens coming from the front: they bounce
	override public function hit(shot:Star) {
		if (step == Cs.ST_NORMAL) {
			if (shot.vx * sens < 0) {
				var p = Cs.game.newPart("mcNinjaShot");
				p.root._x = shot.root._x;
				p.root._y = shot.root._y;
				p.root.gotoAndStop(Cs.game.optList[Cs.OPT_FLAMES] ? 2 : 1);
				p.vx = -shot.vx * 0.75;
				p.vy = shot.vy - 3;
				p.t = 20 + Seed.randVfx() * 10;
				p.weight = 0.4;
				return;
			}
		}
		super.hit(shot);
	}

	// cut from behind only, pushed back otherwise
	override public function cut(n:Float) {
		if ((Cs.game.hero.x - x) * sens < 0) {
			super.cut(n);
		} else {
			throwAt(1.57 - (1.57 * Cs.game.hero.sens), 12);
		}
	}

	override public function throwAt(a:Float, p:Float) {
		if (flGround && hp > 0) {
			root.gotoAndStop("walk_loop");
		}
		super.throwAt(a, p);
	}

	override public function crossSquare() {
		super.crossSquare();

		if (Cs.game.checkFree(x + sens, y + 1)) {
			if (isSmart()) {
				var dif = Cs.game.hero.x - x;
				if (Cs.game.hero.y <= y + 3 && Std.int(dif / Math.abs(dif)) != sens) {
					setSens(-sens);
				}
			} else {
				if (Seed.rand() < 0.7)
					setSens(-sens);
			}
		}
	}
}
