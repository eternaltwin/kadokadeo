package cookinglili;

import mt.Timer;

class Ice extends Fx {
	var dx:Float;
	var dy:Float;

	public function new(g, x, y) {
		super(g);
		mc = game.dm.attach("fx_ice", Cs.DP_FX);
		mc._x = x;
		mc._y = y;
		mc._xscale = Seed.randomVfx(50) + 50;
		mc._yscale = mc._xscale;
		dx = KadoKadeoManager.S(Seed.randomVfx(5) + 1) * (Seed.randomVfx(2) * 2 - 1);
		dy = -KadoKadeoManager.S(Seed.randomVfx(5) + 5);
	}

	override public function update() {
		super.update();
		dy += Cs.FX_GRAVITY * Timer.tmod;
		mc._rotation += dx * 2;
		mc._x += dx;
		mc._y += dy;
		if (mc._y >= Cs.GHEI + KadoKadeoManager.I(5)) {
			destroy();
		}
	}
}
