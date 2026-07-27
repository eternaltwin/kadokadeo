package cookinglili;

import pixi.core.Pixi.BlendModes;
import mt.Timer;

class ShineDrop extends Fx {
	var dx:Float;
	var dy:Float;

	public function new(g, x, y) {
		super(g);
		mc = game.dm.attach("fx_shine", Cs.DP_FX);
		mc.blendMode = BlendModes.OVERLAY;
		mc.play();
		mc.loop = true;
		mc._x = x;
		mc._y = y;
		mc._xscale = Seed.randomVfx(50) + 50;
		mc._yscale = mc._xscale;
		dx = KadoKadeoManager.S(Seed.randomVfx(5) + 1) * (Seed.randomVfx(2) * 2 - 1);
		dy = -KadoKadeoManager.S(Seed.randomVfx(5) + 5);
	}

	override public function update() {
		super.update();
		if (dy <= 0 || mc._y <= KadoKadeoManager.I(30)) {
			dy += Cs.FX_GRAVITY * Timer.tmod;
			dx *= 0.95;
		} else {
			dx *= 0.7;
			dy *= 0.92;
			//			dx+= (Seed.randomVfx(10)/10) * (Seed.randomVfx(2)*2-1);
		}
		mc._rotation += dx * 2;
		mc._x += dx;
		mc._y += dy;
		mc._alpha -= Timer.tmod * 2;
		if (mc._alpha <= 0) {
			destroy();
		}
	}
}
