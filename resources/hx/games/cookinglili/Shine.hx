package cookinglili;

import pixi.core.Pixi.BlendModes;
import mt.Timer;

class Shine extends Fx {
	var dx:Float;
	var dy:Float;
	var fl_h:Bool;

	public function new(g, x:Float, y:Float, fl_h) {
		super(g);
		mc = game.dm.attach("fx_shine", Cs.DP_FX);
		mc.blendMode = BlendModes.OVERLAY;
		mc.play();
		mc.loop = true;
		mc._x = x + KadoKadeoManager.S(Seed.randomVfx(15)) * (Seed.randomVfx(2) * 2 - 1);
		mc._y = y + KadoKadeoManager.S(Seed.randomVfx(10)) * (Seed.randomVfx(2) * 2 - 1);
		mc._xscale = Seed.randomVfx(100) + 50;
		mc._yscale = mc._xscale;
		mc._alpha = Seed.randomVfx(30) + 70;
		dy = KadoKadeoManager.S(Seed.randomVfx(50) / 10 + 4);
		if (fl_h) {
			dx = dy * (Seed.randomVfx(2) * 2 - 1);
			dy = 0;
			mc._rotation = 90;
		} else {
			mc._y += KadoKadeoManager.I(10);
		}
	}

	override public function update() {
		super.update();
		dx *= 0.9;
		dy *= 0.9;
		mc._alpha -= Timer.tmod * 3;
		mc._xscale -= Timer.tmod * 2;
		mc._yscale = mc._xscale;
		mc._x += dx;
		mc._y += dy;
		if (mc._alpha <= 0) {
			destroy();
		}
	}
}
