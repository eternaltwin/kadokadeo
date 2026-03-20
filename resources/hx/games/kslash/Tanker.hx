package kslash;

class Tanker extends Runner {
	public function new(mc) {
		super(mc);
		stLevel = 3;
		hp = 50;
		score = Cs.C300;
		stClimbWait = 12; // 16
		stTossClimb = 6; // 12
		stTossSmart = 2;
		stClimb = 36 * Cs.NEW_GEN_SCALE;
		speed = 4 * Cs.NEW_GEN_SCALE;
		stDrop.push({w: 40, id: 1});
		stDrop.push({w: 10, id: 2});
		stDrop.push({w: 30, id: 5});
		score = Cs.C100;
	}

	public override function hit(shot:Star) {
		if (step == Cs.ST_NORMAL) {
			if (shot.vx * sens < 0) {
				var skinName = Cs.game.optList[Cs.OPT_FLAMES] ? "mcNinjaShot2" : "mcNinjaShot1";
				var p = Cs.game.newPart(skinName);
				p.x = shot.root._x;
				p.y = shot.root._y;
				p.root.loop = true;
				p.root.play();
				p.vx = -shot.vx * 0.75 * Cs.NEW_GEN_SCALE;
				p.vy = shot.vy - 3 * Cs.NEW_GEN_SCALE;
				p.timer = 20 + Cs.rand() * 10;
				p.weight = 0.4 * Cs.NEW_GEN_SCALE;
				return;
			}
		}
		super.hit(shot);
	}

	public override function cut(n) {
		if ((Cs.game.hero.x - x) * sens < 0) {
			super.cut(n);
		} else {
			throwMonster(1.57 - (1.57 * Cs.game.hero.sens), 12 * Cs.NEW_GEN_SCALE);
		}
	}

	public override function throwMonster(a, p) {
		if (flGround && hp > 0) {
			root.gotoAndStop("walk_loop");
		}
		super.throwMonster(a, p);
	}

	public override function crossSquare() {
		super.crossSquare();

		if (Cs.game.checkFree(x + sens, y + 1)) {
			if (isSmart()) {
				var dif = Cs.game.hero.x - x;
				if (Cs.game.hero.y <= y + 3 && Std.int(dif / Math.abs(dif)) != sens) {
					setSens(-sens);
				}
			} else {
				if (Cs.rand() < 0.7) {
					setSens(-sens);
				}
			}
		}
	}
}
