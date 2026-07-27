package cookinglili;

import mt.Timer;

class Spark extends Fx {
	var sp:Float;
	var ang:Float;
	var angSpeed:Float;

	public function new(g, dm, x, y, id) {
		super(g);
		ang = (Seed.randomVfx(360) * Math.PI * 2) / 360;
		mc = dm.attach("fx_spark" + (id + 1), Cs.DP_FX);
		mc.play();
		mc.loop = true;
		mc._x = x;
		mc._y = y;
		sp = KadoKadeoManager.I(5);
		angSpeed = 0.1;
	}

	override public function destroy() {
		game.girl.glowStep = 1;
		super.destroy();
	}

	/*------------------------------------------------------------------------
		LOOP
		------------------------------------------------------------------------ */
	override public function update() {
		super.update();
		if (sp < KadoKadeoManager.S(10))
			sp += KadoKadeoManager.S(0.5) * Timer.tmod;
		var tx = game.girl.mc._x;
		var ty = game.girl.mc._y - KadoKadeoManager.I(10);
		var tang = Math.atan2(ty - mc._y, tx - mc._x);
		var delta = tang - ang;
		if (delta < -Math.PI)
			delta += 2 * Math.PI;
		if (delta > Math.PI)
			delta -= 2 * Math.PI;
		ang += (delta) * angSpeed;
		if (angSpeed < 0.5)
			angSpeed += 0.01 * Timer.tmod;
		if (mc._y <= ty) {
			destroy();
		} else {
			mc._rotation = ang * 180 / (Math.PI);

			mc._x += Math.cos(ang) * sp;
			mc._y += Math.sin(ang) * sp;
		}
	}
}
