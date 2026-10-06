package cyclopean;

class Bille extends Phys {
	public static inline var TURN = 0.4;
	public static inline var RAY = 5;

	public var step:Int;
	public var bTimer:Null<Float>;

	var angle:Float;
	var timer:Float;
	var sp:Float;

	public function new() {
		var mc = Cs.game.dm.attach("bille", Game.DP_PIOU);
		super(mc);

		frict = 0.98;
		//
		Cs.game.bList.push(this);
		//
		var rb = new RoundBouncer(this);
		bouncer = rb;
		bouncer.frict = 0.5;
		rb.setRoundShape(RAY, 4);
		bouncer.onBounce = onBounce;

		//
		angle = 0;
		step = 1;
		//
		newSpeedRot(5, 30);

		setColor(Seed.random(root._totalframes) + 1);
	}

	// the balls in the pentacle only turn around it (no collision, no score): their random draws are visual
	public function initGeneratorMode():Void {
		step = 2;
		frict = 0.95;
		sp = 0.4 + Seed.randVfx() * 0.5;
		bTimer = 200;
		timer = 0;
		newSpeedRot(15, 15);
	}

	override public function update():Void {
		var tmod = Game.tmod;
		switch (step) {
			case 1:
				sp = 0.6;
				towardAngle(Cs.game.ball);
				if (getDist({x: Cs.LEVEL_SIDE * 0.5, y: Cs.LEVEL_SIDE * 0.5}) < 100) {
					initGeneratorMode();
					Cs.game.generator.push(root._currentframe);
					if (!Cs.game.flCenterActive)
						kill();
				}

			case 2:
				var center = {x: Cs.LEVEL_SIDE * 0.5, y: Cs.LEVEL_SIDE * 0.5};
				towardAngle(center);

				if (Seed.randVfx() < 0.2 && tmod < 1.4) {
					var p = Cs.game.newPart("mcLightFlip");
					var c = Seed.randVfx() * 0.5;
					p.x = x;
					p.y = y;
					p.vx = vx * c;
					p.vy = vy * c;
					p.setScale(100 + Seed.randVfx() * 100);
					p.timer = 10 + Seed.randVfx() * 10;
					p.fadeType = 0;
				}

				if (bTimer != null) {
					bTimer -= tmod;
					if (bTimer < 0) {
						bTimer = null;
						bouncer = null;
					}
				}
		}
		super.update();
	}

	function towardAngle(trg:{x:Float, y:Float}):Void {
		var tmod = Game.tmod;
		var da = Cs.hMod(getAng(trg) - angle, 3.14);
		angle += Cs.mm(-TURN, da * 0.2 * tmod, TURN);
		vx += Cs.cos(angle) * sp * tmod;
		vy += Cs.sin(angle) * sp * tmod;
	}

	function onBounce(x:Float, y:Float):Void {
		if (Math.abs(vx) + Math.abs(vy) > 7) {
			newSpeedRot(5, 10 + Math.abs(vx) + Math.abs(vy) * 3);
		}
	}

	override public function kill():Void {
		Cs.game.bList.remove(this);
		super.kill();
	}

	// the spin of the picture: visual random
	function newSpeedRot(base:Float, inc:Float):Void {
		vr = (base + Seed.randVfx() * inc) * (Seed.randomVfx(2) * 2 - 1);
	}

	public function setColor(fr:Int):Void {
		root.gotoAndStop(fr);
	}
}
