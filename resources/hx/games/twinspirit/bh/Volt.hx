package twinspirit.bh;

class Volt extends Behaviour {
	var charge:Int;
	var inc:Int;
	var parts:Float;

	public function new() {
		super();
		inc = 1;
	}

	override public function init(b:Bad) {
		super.init(b);
		charge = 0;
		parts = 0;
	}

	override public function update() {
		charge += inc;
		parts += Math.max(charge * 0.15 - 8, 0);

		// FX
		while (parts > 0) {
			var mc = Game.me.dm.attach("volt", Game.DP_FX);
			mc.removeAfter = true;
			mc._x = b.x + (Seed.randVfx() * 2 - 1) * b.ray;
			mc._y = b.y + (Seed.randVfx() * 2 - 1) * b.ray;
			mc.blendMode = pixi.core.Pixi.BlendModes.ADD;
			mc._rotation = Seed.randVfx() * 360;
			parts--;
		}

		// SHOOT
		if (charge > 100) {
			charge = -b.seed.random(50);
			var dest = [ShotType(STVolt)];
			for (i in 0...20) {
				dest.push(ShotPos((b.seed.rand() * 2 - 1) * b.ray, (b.seed.rand() * 2 - 1) * b.ray));
				dest.push(Aim(0.01, 8 + b.seed.rand() * 6));
				dest.push(Wait(0.25));
			}
			b.addDestiny(dest);
		}

		// root.smc.smc turns with the speed
		var s = b.skinSmc();
		if (s != null)
			s._rotation += b.vx * 10;
	}
}
