package kslash;

import mt.Timer;

class Flyer extends Monster {
	var speed:Float;
	var trg:{x:Float, y:Float};

	var waitTimerMax:Float;

	public function new(mc) {
		super(mc);
		mc.removeOnFrame = 50;
		mc.onFrame.set(16, () -> mc.gotoAndPlay(1));
		mc.onFrame.set(23, () -> mc.gotoAndPlay(1));
		animFrame.set("fly", 1);
		animFrame.set("hit", 17);
		animFrame.set("death", 31);
		root.play();
		stLevel = 2;
		score = Cs.C120;
		setSens(Cs.random(2) * 2 - 1);
		initStep(Cs.ST_NORMAL);

		flCol = false;

		stDrop.push({w: 150, id: 4});
		stDrop.push({w: 50, id: 8});

		waitTimer = 0;
		waitTimerMax = 100;

		weight = 0;
		hp = 30;
		score = Cs.C30;
	}

	public override function update() {
		super.update();
		switch (step) {
			case Cs.ST_NORMAL:
				waitTimer -= Timer.tmod;
				if (waitTimer < 0) {
					chooseTrg();
					waitTimer = waitTimerMax + Cs.rand() * 20;
					waitTimerMax = Math.max(0, waitTimerMax - 8);
				}
				move();
				// root._rotation = vx*3;
				var dx = Cs.game.hero.root._x - root._x;
				if (dx * sens < 0)
					setSens(-sens);
		}
	}

	public function move() {
		var dx = trg.x - root._x;
		var dy = trg.y - root._y;
		var a = Math.atan2(dy, dx);
		var dist = Math.sqrt(dx * dx + dy * dy);

		var c = 0.1 * Cs.NEW_GEN_SCALE;
		var lim = 0.4 * Cs.NEW_GEN_SCALE;

		vx += Math.min(Math.max(-lim, Math.cos(a) * dist * c), lim);
		vy += Math.min(Math.max(-lim, Math.sin(a) * dist * c), lim);
	}

	public function chooseTrg() {
		var dx = Cs.game.hero.root._x - root._x;
		var dy = Cs.game.hero.root._y - root._y;

		var a = Math.atan2(dy, dx);
		var dist = Math.min(Math.sqrt(dx * dx + dy * dy), 160 * Cs.NEW_GEN_SCALE);
		trg = {
			x: root._x + Math.cos(a) * dist,
			y: root._y + Math.sin(a) * dist
		};
		// Log.trace("chooseTrg("+trg.x+","+trg.y+")")
	}

	public override function hit(shot) {
		nextAnim = "hit";
		super.hit(shot);
	}

	public override function death() {
		root.gotoAndPlay(animFrame.get("death"));
		super.death();
	}
}
