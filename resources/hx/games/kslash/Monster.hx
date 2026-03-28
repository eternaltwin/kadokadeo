package kslash;

import mt.bumdum.Lib;
import mt.Timer;

class Monster extends Ent {
	// STATS
	public var stLevel:Int;

	var stClimb:Int;
	var stDrop:Array<{w:Int, id:Int}>;
	var stTossClimb:Int;
	var stTossSmart:Int;
	var stTossShoot:Int;
	var stClimbWait:Float;
	var stShootWait:Float;
	var score:Int;

	// VARIABLES
	var flClimbAnim:Bool;

	public var flSpike:Bool;
	public var hp:Float;

	var waitTimer:Float;
	var flash:Float;

	public function new(mc) {
		super(mc);
		Cs.game.mList.push(this);
		// mc.getGraphics().beginFill(0x00AADD, 0.5).drawRect(-Cs.SIZE / 2, -Cs.SIZE / 2, Cs.SIZE, Cs.SIZE);

		stTossSmart = 10;
		flSpike = false;

		stDrop = [{w: 100, id: 1}, {w: 20, id: 2}, {w: 1, id: 3}];

		hp = 10;
		score = Cs.C0;
		stClimb = 21 * Cs.NEW_GEN_SCALE;

		initStep(Cs.ST_FLY);
	}

	public function initStep(n) {
		step = n;
		switch (step) {
			case Cs.ST_FLY:
				flGround = false;
			case Cs.ST_CLIMB:
				flClimbAnim = false;
				waitTimer = stClimbWait;
				vx = 0;
			case Cs.ST_SHOOT:
				waitTimer = stShootWait;
				vx = 0;
		}
	}

	public override function update() {
		super.update();
		switch (step) {
			case Cs.ST_CLIMB:
				waitTimer -= Timer.tmod;

				if (waitTimer < 15) {
					if (!flClimbAnim) {
						flClimbAnim = true;
						root.gotoAndPlay(animFrame.get("climbEnd"));
					}
					if (waitTimer < 0) {
						climb();
					}
				}
			case Cs.ST_SHOOT:
				waitTimer -= Timer.tmod;
				if (waitTimer < 0) {
					shoot();
					nextAnim = "shoot";
				}
		}

		updateFlash();
	}

	public function climb() {
		vy -= stClimb;
		initStep(Cs.ST_FLY);
	}

	public function shoot() {
		initStep(Cs.ST_NORMAL);
	}

	public function updateFlash() {
		if (flash != null) {
			var prc = flash;
			flash *= 0.7;
			if (flash < 1) {
				flash = null;
				prc = 0;
			}
			Col.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	//
	public function cut(n) {
		KadoKadeoManager.kkm.addScore(Cs.C50);
		harm(n);
		throwMonster(1.57 - (1.57 * Cs.game.hero.sens), 10 * Cs.NEW_GEN_SCALE);
	}

	public function hit(shot:Star) {
		KadoKadeoManager.kkm.addScore(Cs.C10);
		harm(shot.damage);
		throwMonster(Math.atan2(shot.vy, shot.vx), 2 * Cs.NEW_GEN_SCALE);
	}

	public function harm(n) {
		hp -= n;
		if (hp < 0) {
			death();
		} else {
			flash = 100;
		}
	}

	public function death() {
		Col.setPercentColor(root, 0, 0xFFFFFF);
		KadoKadeoManager.kkm.addScore(score);
		Cs.game.spawnBonus(root._x, root._y, getDrop());
		Cs.game.monsterLevel -= stLevel;
		leaveSquare();
		Cs.game.mList.remove(this);
	}

	public function getDrop() {
		var sum = 0;
		for (d in stDrop) {
			sum += d.w;
		}
		var rnd = Cs.random(sum);
		sum = 0;
		for (d in stDrop) {
			sum += d.w;
			if (sum > rnd) {
				return d.id;
			}
		}
		return 0;
	}

	public function throwMonster(a, p) {
		var vitx = Math.cos(a) * p;
		var vity = Math.sin(a) * p - 3;
		if (flGround) {
			vity = Math.min(0, vity);
			if (vity < 0)
				initStep(Cs.ST_FLY);
		}
		vx += vitx;
		vy += vity;
	}

	public function tryJumpFront() {
		var dist = 0;
		while (dist < 6) {
			dist++;
			if (!Cs.game.checkFree(x + (sens * (dist + 1)), y + 1))
				break;
		}
		if (dist < 6) {
			jumpFront(dist);
		}
	}

	public function jumpFront(dist) {
		initStep(Cs.ST_FLY);
		vy = -10 * Cs.NEW_GEN_SCALE;
		vx = Math.pow(dist * 24 * Cs.NEW_GEN_SCALE, 0.6) * sens;
	}

	// ON
	public override function land() {
		super.land();
		initStep(Cs.ST_NORMAL);
	}

	public override function crossSquare() {
		super.crossSquare();

		var flSmart = isSmart();

		// CLIMB
		if (step == Cs.ST_NORMAL && stTossClimb != null && Cs.rand() * stTossClimb < 1) {
			var flDoIt = true;
			if (Cs.game.hero.y > y - 3 && flSmart)
				flDoIt = false;
			if (flDoIt) {
				for (i in 2...5) {
					if (!Cs.game.checkFree(x, y - i)) {
						initStep(Cs.ST_CLIMB);
						break;
					}
				}
			}
		}
	}

	public override function fall() {
		// super.fall();
		initStep(Cs.ST_FLY);
	}

	public override function bang() {
		super.bang();
		setSens(-sens);
	}

	public override function enterSquare() {
		if (x < 0 || x >= Game.XMAX || y < 0 || y >= Game.YMAX) {
			return;
		}
		Cs.game.grid[x][y].list.push(this);
	}

	public override function leaveSquare() {
		super.leaveSquare();
		if (x < 0 || x >= Game.XMAX || y < 0 || y >= Game.YMAX) {
			return;
		}
		Cs.game.grid[x][y].list.remove(this);
	}

	// TOOLS
	public function chooseWay() {
		var sens = Cs.random(2) * 2 - 1;
		if (isSmart())
			sens = (Cs.game.hero.x < x) ? -1 : 1;
		setSens(sens);
	}

	// IS ?
	public function isSmart() {
		return Cs.rand() * stTossSmart < 1;
	}
}
