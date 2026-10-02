package kslash;

class Monster extends Ent {
	// STATS
	public var stClimb:Float;
	public var stDrop:Array<{w:Int, id:Int}>;
	public var stLevel:Int;
	public var stTossClimb:Null<Int>;
	public var stTossSmart:Int;
	public var stTossShoot:Null<Int>;
	public var stClimbWait:Float;
	public var stShootWait:Float;
	public var score:Int;

	// VARIABLES
	public var flClimbAnim:Bool;
	public var flSpike:Bool;

	public var hp:Float;
	public var waitTimer:Float;
	public var flash:Null<Float>;

	public function new(mc:Clip) {
		super(mc);
		Cs.game.mList.push(this);

		stTossSmart = 10;
		flSpike = false;

		stDrop = [{w: 100, id: 1}, {w: 20, id: 2}, {w: 1, id: 3}];

		hp = 10;
		score = Cs.C0;
		stClimb = 21;

		initStep(Cs.ST_FLY);
	}

	public function initStep(n:Int) {
		step = n;
		switch (step) {
			case Cs.ST_NORMAL:
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

	override public function update() {
		super.update();
		switch (step) {
			case Cs.ST_CLIMB:
				waitTimer -= Timer.tmod;

				if (waitTimer < 15) {
					if (!flClimbAnim) {
						flClimbAnim = true;
						root.gotoAndPlay("climbEnd");
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

	function updateFlash() {
		if (flash != null) {
			var prc = flash;
			flash *= 0.7;
			if (flash < 1) {
				flash = null;
				prc = 0;
			}
			Cs.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	//
	public function cut(n:Float) {
		Cs.game.addScore(Cs.C50);
		harm(n);
		throwAt(1.57 - (1.57 * Cs.game.hero.sens), 10);
	}

	public function hit(shot:Star) {
		Cs.game.addScore(Cs.C10);
		harm(shot.damage);
		throwAt(Cs.q(Math.atan2(shot.vy, shot.vx)), 2);
	}

	public function harm(n:Float) {
		hp -= n;
		if (hp < 0) {
			death();
		} else {
			flash = 100;
		}
	}

	public function death() {
		Cs.setPercentColor(root, 0, 0xFFFFFF);
		Cs.game.addScore(score);
		Cs.game.spawnBonus(root._x, root._y, getDrop());
		Cs.game.monsterLevel -= stLevel;
		leaveSquare();
		Cs.game.mList.remove(this);
	}

	function getDrop():Int {
		var sum = 0;
		for (d in stDrop)
			sum += d.w;
		var rnd = Seed.random(sum);
		sum = 0;
		for (d in stDrop) {
			sum += d.w;
			if (sum > rnd)
				return d.id;
		}
		return 0;
	}

	// throw(a, p) of the original
	public function throwAt(a:Float, p:Float) {
		var vitx = Cs.q(Math.cos(a) * p);
		var vity = Cs.q(Math.sin(a) * p) - 3;
		if (flGround) {
			vity = Math.min(0, vity);
			if (vity < 0)
				initStep(Cs.ST_FLY);
		}
		vx += vitx;
		vy += vity;
	}

	function tryJumpFront() {
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

	function jumpFront(dist:Int) {
		initStep(Cs.ST_FLY);
		vy = -10;
		vx = Cs.q(Math.pow(dist * 24, 0.5)) * sens;
	}

	// ON
	override public function land() {
		super.land();
		initStep(Cs.ST_NORMAL);
	}

	override public function crossSquare() {
		super.crossSquare();

		var flSmart = isSmart();

		// CLIMB
		if (step == Cs.ST_NORMAL && stTossClimb != null && Seed.rand() * stTossClimb < 1) {
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

	override public function fall() {
		initStep(Cs.ST_FLY);
	}

	override public function bang() {
		super.bang();
		setSens(-sens);
	}

	override public function enterSquare() {
		var list = Cs.game.gridList(x, y);
		if (list != null)
			list.push(this);
	}

	override public function leaveSquare() {
		super.leaveSquare();
		var list = Cs.game.gridList(x, y);
		if (list != null)
			list.remove(this);
	}

	// TOOLS
	function chooseWay() {
		var sens = Seed.random(2) * 2 - 1;
		if (isSmart())
			sens = (Cs.game.hero.x < x) ? -1 : 1;
		setSens(sens);
	}

	// IS ?
	function isSmart():Bool {
		return Seed.rand() * stTossSmart < 1;
	}
}
