package kanjigaiden;

// Kanji.hx of the original: the hero's arm (the camera turns with Game.pos), its shots
class Kanji extends Phys {
	var sLock:Bool;

	public var speedy:Bool;

	// (never set before the first shot: undefined, `sCount > 0` false)
	var sCount:Float = Math.NaN;
	var kanji:MC;

	public var sType:Int;

	// (Haxe 4: the fields set after super(), the clip placed before it as in the original)
	public function new() {
		var mc = Game.me.dm.attach("hero", Game.DP_HERO);

		mc._x = Cs.mcw * 0.5;
		mc._y = Cs.mch;
		super(mc);
		kanji = mc;
		sType = 1;
		var h = smc3();
		if (h != null)
			h.gotoAndStop(sType);
		sLock = false;
		speedy = false;
	}

	// kanji.smc.smc.smc: the shuriken in the hand (its frame: the kind of shot)
	function smc3():Clip {
		var a = kanji.sub("smc");
		var b = a != null ? a.getClip("smc") : null;
		var c = b != null ? b.getClip("smc") : null;
		return c;
	}

	public function shoot() {
		if (!sLock) {
			if (sType == 2)
				sCount = Cs.sCool2;
			else
				sCount = Cs.sCool;
			sLock = true;
			var h = smc3();
			if (h != null)
				h.gotoAndStop(sType);
			var s = new Shot(sType);
			var smc = kanji.sub("smc");
			if (smc != null)
				smc.gotoAndPlay("_shoot");

			if (sType != 0) {
				// (Game.me.bonus[0] is undefined without a bonus: Flash ignores the decrement)
				var b = Game.me.bonus[0];
				if (b != null)
					b.qte--;
			}
		}
	}

	override public function update() {
		if (sCount > 0) {
			sCount -= Timer.tmod;
		} else {
			sLock = false;
		}
	}

	public function move(dir:Int) {
		switch (dir) {
			case 0:
				if (Game.me.pos < 1) {
					Game.me.pos += Cs.DEV * Timer.tmod;
					if (!sLock)
						Game.me.pos += 0.010;
					if (speedy)
						Game.me.pos += 0.020;
				}

			case 1:
				if (Cs.DEV < Game.me.pos) {
					Game.me.pos -= Cs.DEV * Timer.tmod;
					if (!sLock)
						Game.me.pos -= 0.010;
					if (speedy)
						Game.me.pos -= 0.020;
				} else {
					Game.me.pos = 0;
				}
		}
	}
}
