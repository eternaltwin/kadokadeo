package judocommando;

class PowerUp extends Ent {
	var btype:Bonus;
	var timer:Int;

	public function new(bt:Bonus) {
		super(Game.me.dm.attach("mcBonus", Game.DP_BONUS));
		type = BONUS;
		ray = 0.25;

		btype = bt;

		root.gotoAndStop(Type.enumIndex(btype) + 1);
		switch (btype) {
			case Gem(tag):
				var smc = root.sub("smc");
				if (smc != null)
					smc.gotoAndStop(Type.enumIndex(tag) + 1);
			default:
		}

		timer = 150;
	}

	override function update() {
		super.update();

		// the sparkle of the gem (visual random)
		if (Seed.randVfx() * 50 < 1) {
			var s = root.sub2("smc", "smc");
			if (s != null)
				s.play();
		}
		if (timer-- <= 0)
			vanish();
	}

	override function land() {
		if (Math.abs(vy) < 1) {
			oy = 1 - ray;
			stopPhys();
		}
	}

	public function activate() {
		switch (btype) {
			case Gem(tag):
				var index = Type.enumIndex(tag);
				Game.me.playInfo._g[index]++;
				Game.me.tags[index] = true;
				Game.me.fxScore(root._x, root._y, Cs.SCORE_GEM);
				Game.me.updateGems(index);
			case Burger:
				Game.me.playInfo._b[1]++;
				Game.me.hero.incLife(3);
			case Yakitori:
				Game.me.playInfo._b[0]++;
				Game.me.hero.incLife(1);
		}

		for (i in 0...8) {
			var p = new Phys(Game.me.dm.attach("fxTwinkle", Game.DP_FX));
			p.x = root._x + Seed.randomVfx(11) - 5;
			p.y = root._y + Seed.randomVfx(11) - 5;
			p.weight = -(0.05 + Seed.randVfx() * 0.05);
			p.frict = 0.92;
			p.timer = 10 + Seed.randVfx() * 15;
			p.sleep = Seed.randVfx() * 12;
			p.root._visible = false;
			Cs.randomize(p.root);
			p.root.play();
			p.updatePos();
			p.fadeType = 1;
		}

		kill();
	}

	function vanish() {
		Game.me.fxAttach("mcVanish", root._x, root._y - 1);
		kill();
	}
}
