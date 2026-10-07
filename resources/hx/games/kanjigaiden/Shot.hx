package kanjigaiden;

// Shot.hx of the original: a kunai thrown into the planes; at each plane it reaches it hits a bamboo or a monkey, or
// goes on to the next one (behind that plane's bamboos). Port: pBonus (commented out in the original) is left out.
class Shot {
	public var ratio:Float;
	public var plan:Int;

	public var goals:Array<Float>;
	public var mc:MC;

	var currentPlan:Int;
	var progress:Float;

	var cz:Float;
	var pastCz:Float;
	var hint:Float;
	var sType:Int;

	var depth:Int;

	public function new(type:Int) {
		hint = Game.me.pos;
		depth = Game.DP_SHOOT;
		mc = Game.me.dm.attach("kunai", depth);
		sType = type;
		mc.gotoAndStop(1);
		var smc = mc.sub("smc");
		if (smc != null)
			smc.gotoAndStop(sType);
		cz = 1;
		pastCz = cz;
		var pos = Game.me.getPosShot(cz, hint);
		mc._x = pos.x;

		currentPlan = 0;
		progress = 0;

		Game.me.shoots.push(this);
		#if debug
		Game.me.stats.shots++;
		#end
	}

	public function update() {
		var tmode = Math.floor(Timer.tmod);
		if (tmode < 1)
			tmode = 1;

		for (i in 0...tmode) {
			sProgress();
		}
	}

	public function sProgress() {
		if (progress < 1) {
			if (sType == 2)
				progress += Cs.SHURIKEN2;
			else
				progress += Cs.SHURIKEN;
		} else {
			if (Game.me.plans[currentPlan].hittest(mc._x, sType)) {
				mc._x = -500;
				kill();
			} else if (currentPlan + 1 == Game.me.plans.length) {
				destroy();
			} else {
				currentPlan += 1;
				progress -= 1;
				pastCz = cz;
				depth = 10 - (currentPlan * 2);
				Game.me.dm.swap(mc, depth);
			}
		}

		// (after a hit the kunai bounces from here; after destroy() the removed clip ignores what follows)
		cz = (pastCz * (1 - progress) + Game.me.plans[currentPlan].cz * progress);

		var pos = Game.me.getPosShot(cz, hint);
		mc._x = pos.x;
		mc._y = (pos.y + Cs.mch * 0.5 - cz * 100 - 10);

		if (currentPlan == 0)
			mc._xscale = 100 * (1 - progress) + (100 * Game.me.plans[currentPlan].cz) * progress + 20;
		else if (currentPlan == 4) {
			mc._xscale = 100 * (1 - progress) + (100 * Game.me.plans[currentPlan].cz) * progress + 20;
			mc._alpha = 100 - 100 * (progress * 2);
		} else
			mc._xscale = (100 * Game.me.plans[currentPlan].cz) * (1 - progress) + (100 * Game.me.plans[currentPlan].cz) * progress + 20;
		mc._yscale = mc._xscale;
	}

	public function kill() {
		Game.me.shoots.remove(this);
		mc.gotoAndStop(2);
		// mc.smc.smc: the shuriken in the bounce
		var b = mc.sub("smc");
		var s = b != null ? b.getClip("smc") : null;
		if (s != null)
			s.gotoAndStop(sType);
		// (only the picture: visual random)
		mc._rotation = (160 + Seed.randomVfx(40)) * (Seed.randomVfx(2) - 2);
	}

	public function destroy() {
		Game.me.shoots.remove(this);
		mc.removeMovieClip();
	}
}
