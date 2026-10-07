package kanjigaiden;

// Bonus.hx of the original: the bonus of a monkey of the 5th kind (the icon in the bottom right corner)
class Bonus {
	var mc:MC;
	var type:Int;
	var lifeTime:Float;

	// shots left (the speed bonus never sets it: undefined, NaN after a shot, `qte < 0` false)
	public var qte:Float = Math.NaN;

	public function new(bt:Int) {
		// port: the icon of each kind is a copy of the clip with its smc on that frame (the entrance and vanishing filters
		// of the timeline baked in): it replaces apply()'s mc.smc.gotoAndStop(type + 1)
		mc = Game.me.dm.attach("bonus" + (bt + 1), Game.DP_BONUS);
		type = bt;
		lifeTime = Cs.bLife;
		mc._xscale = -80;
		mc._yscale = 80;
		mc._x = Cs.mch - 35;
		mc._y = Cs.mch - 35;

		apply();
	}

	function apply() {
		switch (type) {
			case 0:
				// speed shuriken
				Game.me.hero.sType = 2;
				qte = Cs.AMMO;
			case 1:
				// power shuriken
				Game.me.hero.sType = 3;
				qte = Cs.AMMO;
			case 2:
				// iron banana
				Game.me.hero.sType = 4;
				qte = Cs.AMMO - 10;
			case 3:
				// speed up
				Game.me.hero.speedy = true;
		}
	}

	public function update() {
		switch (type) {
			case 0:

			case 1:

			case 2:

			case 3:
				lifeTime -= Timer.tmod;
		}

		if ((lifeTime < 0) || (qte < 0)) {
			destroy();
		}
	}

	public function destroy() {
		Game.me.hero.sType = 1;
		Game.me.hero.speedy = false;

		mc.gotoAndPlay("_vanish");
		Game.me.bonus.remove(this);
	}
}
