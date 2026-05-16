package interwheel;

import mt.Timer;
import pixi.core.Pixi.BlendModes;

class Bubble extends Part {
	var dec:Float;
	var dsp:Float;
	var ec:Float;
	var outTimer:Float;

	public function new(mc) {
		mc = Cs.game.dm.attach("mcBubble", Game.DP_WPART);
		super(mc);
		frict = 0.98;
		dec = Seed.randVfx() * 628;
		dsp = 10 + Seed.randVfx() * 20;
		ec = 0.5 + Seed.randVfx() * 4;
		weight = -(0.15 + Seed.randVfx() * 0.5);
		setScale(30 + Seed.randVfx() * 50);
		root.stop();

		root.blendMode = BlendModes.SCREEN;
	}

	public override function update() {
		if (outTimer != null) {
			outTimer -= Timer.tmod;
			y = Cs.game.water._y;
			setScale(scale + Timer.tmod);
			if (outTimer < 0) {
				kill();
			}
		} else {
			dec = (dec + dsp * Timer.tmod) % 628;
			vx = Math.cos(dec / 100) * ec;
			if (y < Cs.game.water._y) {
				y = Cs.game.map._y;
				vx = 0;
				vy = 0;
				root.nextFrame();
				outTimer = 10 + Seed.randVfx() * 20;
			}
		}

		super.update();
	}
}
