package kslash;

class Runner extends Monster {
	var flFlyUp:Bool;
	var flStraight:Bool;
	var flWalk:Bool;

	public var speed:Float;

	public function new(mc:Clip) {
		super(mc);

		setSens(Seed.random(2) * 2 - 1);

		flWalk = true;
		stClimbWait = 26;

		initStep(Cs.ST_FLY);
	}

	override public function initStep(n:Int) {
		super.initStep(n);
		switch (step) {
			case Cs.ST_NORMAL:
				if (!flWalk) {
					flWalk = true;
					nextAnim = "walk";
				} else {
					nextAnim = "walk_loop";
				}
			case Cs.ST_FLY:
				flGround = false;
			case Cs.ST_CLIMB:
				nextAnim = "climb";
			case Cs.ST_SHOOT:
				nextAnim = "shootWait";
		}
	}

	override public function update() {
		super.update();
		switch (step) {
			case Cs.ST_NORMAL:
				var dvx = sens * speed - vx;
				var lim = 0.5;
				vx += Math.min(Math.max(-lim, dvx * 0.2), lim) * Timer.tmod;
			case Cs.ST_FLY:
				if (flFlyUp && vy > 0) {
					flFlyUp = false;
					if (flStraight) {
						nextAnim = "fly_straight_down";
						flStraight = false;
					} else {
						nextAnim = "fly_down";
					}
				}
		}
	}

	override function jumpFront(dist:Int) {
		super.jumpFront(dist);
		flStraight = true;
		flFlyUp = true;
		nextAnim = "fly_straight_up";
	}

	override public function throwAt(a:Float, p:Float) {
		if (flGround && hp > 0) {
			root.gotoAndStop("walk_loop");
		}
		super.throwAt(a, p);
	}

	//
	override public function climb() {
		super.climb();
		root.gotoAndStop("fly_up");
		flFlyUp = true;
		flWalk = false;
	}

	override public function land() {
		super.land();
		chooseWay();
	}

	override public function death() {
		root.gotoAndPlay("death");
		super.death();
	}
}
