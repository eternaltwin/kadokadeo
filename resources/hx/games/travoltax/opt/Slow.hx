package travoltax.opt;

import common_haxe_avm1.display.ASprite;
import kado.Seed;
import pixi.filters.blur.BlurFilter;
import travoltax.Common.Cs;
import travoltax.Game;
import travoltax.Option;
import mt.bumdum.Lib;
import mt.bumdum.Phys;

class Grim extends ASprite {
	public var c:Float;
}

class Slow extends Option {
	var list:Array<Grim>;
	var speed:Float;

	public function new() {
		super();
		Game.me.speed *= 0.3;

		speed = 100 * Cs.NEW_GEN_SCALE;

		list = [];
		var max = 36;
		for (i in 0...max) {
			var c = i / max;
			var mc:Grim = cast Game.me.dm.attach("partTwinkle", Game.DP_PLASMA);
			mc._x = Cs.MX + Seed.randVfx() * (Cs.XMAX * Cs.SIZE);
			mc._y = Cs.MY + Seed.randVfx() * Cs.mch;
			mc._xscale = mc._yscale = 100 + c * 200;
			mc.c = c;
			mc.gotoAndPlay(Seed.randomVfx(mc._totalframes) + 1);
			list.push(mc);
			updateGrim(mc);
		}
	}

	public override function update() {
		super.update();

		speed *= 0.9;
		if (speed < 0.5 * Cs.NEW_GEN_SCALE)
			speed = 0.5 * Cs.NEW_GEN_SCALE;

		var a = list.copy();
		for (mc in a)
			updateGrim(mc);
		if (list.length == 0)
			kill();
	}

	function updateGrim(mc:Grim) {
		mc._y -= speed * (0.2 + mc.c) * mt.Timer.tmod;
		if (mc._y < -mc._height * 0.5)
			mc._y += Cs.mch + mc._height;
		var fl = new BlurFilter();
		fl.blurX = 0;
		fl.blurY = speed * 2;
		mc.filters = [fl];
		if (speed < 1 * Cs.NEW_GEN_SCALE) {
			mc.filters = [];
			mc._xscale -= 20;
			mc._yscale = mc._xscale;
			if (mc._xscale < 0) {
				mc.removeMovieClip();
				list.remove(mc);
			}
		}
	}

	public override function kill() {
		super.kill();
	}
}
