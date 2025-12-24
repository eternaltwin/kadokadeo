package kanji_gaiden;

import mt.bumdum.Lib;

class Shot { // }
	public var ratio:Float;
	public var plan:Int;

	public var goals:Array<Float>;
	public var mc:ASprite;

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
		mc = Game.me.dm.empty(depth);
		mc.smc = mc.attachMovie("kanji_gaiden/kunai", "kunai", 0);
		mc.smc.anchor.set(0.5, 0.5);
		sType = type;
		mc.smc.gotoAndStop(sType);
		cz = 1;
		pastCz = cz;
		var pos = Game.me.getPosShot(cz, hint);
		mc._x = pos.x;

		currentPlan = 0;
		progress = 0;

		Game.me.shoots.push(this);
	}

	public function update() {
		var tmode = Math.floor(mt.Timer.tmod);
		if (tmode < 1)
			tmode = 1;

		for (i in 0...tmode) {
			sProgress();
		}

		mc.smc.update();
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
		mc.removeChild(mc.smc);
		mc.smc = mc.attachMovie('kanji_gaiden/kunai_bounce', 'smc', 0);
		mc.smc.removeOnFrame = 9;
		mc.smc.gotoAndPlay(1);

		Game.spriteList.push(mc.smc);

		// mc.smc.smc.gotoAndStop(sType);
		mc._rotation = (160 + Std.random(40)) * (Std.random(2) - 2);
	}

	public function destroy() {
		Game.me.shoots.remove(this);
		mc.removeMovieClip();
	}

	// {
}
