package kslash;

import mt.Timer;

class Runner extends Monster {
	var flFlyUp:Bool;
	var flStraight:Bool;
	var flWalk:Bool;
	var speed:Float;

	public function new(mc) {
		super(mc);
		mc.stopOnFrame = [36, 65, 72, 86, 95, 132];
		mc.removeOnFrame = 118;
		mc.onFrame.set(17, () -> mc.gotoAndPlay(5));
		mc.onFrame.set(140, () -> mc.gotoAndPlay(5));
		mc.onFrame.set(132, () -> mc.gotoAndPlay(127));
		animFrame.set("walk", 1);
		animFrame.set("walk_loop", 5);
		animFrame.set("climb", 20);
		animFrame.set("climbEnd", 37);
		animFrame.set("fly_up", 53);
		animFrame.set("fly_down", 66);
		animFrame.set("fly_straight_up", 75);
		animFrame.set("fly_straight_down", 87);
		animFrame.set("death", 99);
		animFrame.set("shootWait", 119);
		animFrame.set("shoot", 133);

		setSens(Cs.random(2) * 2 - 1);

		flWalk = true;
		stClimbWait = 26;

		initStep(Cs.ST_FLY);
	}

	public override function initStep(n) {
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

	public override function update() {
		super.update();
		switch (step) {
			case Cs.ST_NORMAL:
				var dvx = sens * speed - vx;
				var lim = 0.5 * Cs.NEW_GEN_SCALE;
				vx += Math.min(Math.max(-lim, dvx * 0.2 * Cs.NEW_GEN_SCALE), lim) * Timer.tmod;
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

	public override function jumpFront(dist) {
		super.jumpFront(dist);
		flStraight = true;
		flFlyUp = true;
		nextAnim = "fly_straight_up";
	}

	public override function throwMonster(a, p) {
		if (flGround && hp > 0) {
			root.gotoAndStop(animFrame.get("walk_loop"));
		}
		super.throwMonster(a, p);
	}

	//

	public override function climb() {
		super.climb();
		root.gotoAndStop(animFrame.get("fly_up"));
		flFlyUp = true;
		flWalk = false;
	}

	public override function land() {
		super.land();
		chooseWay();
	}

	public override function death() {
		// Cs.game.spawnBonus(x,y)
		root.gotoAndPlay(animFrame.get("death"));
		super.death();
	}
}
