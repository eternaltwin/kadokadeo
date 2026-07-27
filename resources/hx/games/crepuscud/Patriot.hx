package crepuscud;

import common_haxe_avm1.MouseManager;

class Patriot extends Projectile {
	static var HERO_RAY = KadoKadeoManager.I(20);

	var distanceMax:Float;
	var parc:Float;
	var mcTarget:ASprite;
	var mcTargetTimer:Float = 0;

	public function new(?mc:ASprite) {
		if (mc == null)
			mc = Game.me.dm.attach("mcPatriot", Game.DP_MISSILE);
		super(mc);
		Game.me.patriots.push(this);

		parc = 0;

		var dx = MouseManager.getX() - Game.DX;
		var dy = MouseManager.getY() - Game.RGY;

		angle = Game.me.angle;
		distanceMax = Math.sqrt(dx * dx + dy * dy) - HERO_RAY;
		x = Game.DX + Math.cos(angle) * HERO_RAY;
		y = Game.RGY + Math.sin(angle) * HERO_RAY;

		setAngle(angle);
		setSpeed(KadoKadeoManager.I(10));

		if (Game.me.expl < 5) {
			mcTarget = Game.me.root.attachMovie("mcTarget");
			mcTarget._x = MouseManager.getX();
			mcTarget._y = MouseManager.getY();
			mcTarget._alpha = 50;
		}
	}

	override function update() {
		super.update();
		parc += speed * mt.Timer.tmod;

		if (parc >= distanceMax) {
			explode();
		}

		if (mcTarget != null) {
			mcTargetTimer += mt.Timer.tmod;
			if (mcTargetTimer > 60) {
				mcTarget.removeMovieClip();
				mcTarget = null;
			}
		}
	}

	public function explode() {
		var onde = new Onde(x, y, Cs.RAY_PATRIOT);
		var multi = 1;

		if (Cs.FL_PERFECT) {
			for (mis in Game.me.missiles) {
				var dx = x - mis.x;
				var dy = y - mis.y;
				if (Math.sqrt(dx * dx + dy * dy) < Cs.PERFECT_RAY)
					multi = 2;
			}
		}

		onde.pool = {n: 0, multi: multi};
		kill();
	}

	override function kill() {
		if (mcTarget != null) {
			mcTarget.removeMovieClip();
		}
		Game.me.patriots.remove(this);
		super.kill();
	}
}
