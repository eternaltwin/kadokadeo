package paradice;

// Gem.mt of the original: a coloured ball (frozen when flIce)
class Gem extends Ball {
	public function new() {
		super();
		type = 0;

		var max = 3;
		var p = Cs.game.play;
		if (p > 20)
			max++;
		if (p > 60)
			max++;
		col = Seed.random(max);
		setSkin(root);
	}

	override public function setSkin(mc:MC) {
		super.setSkin(mc);
		mc.gotoAndStop(1);
		var frame = col + 1;
		if (flIce)
			frame += 10;
		mc.sub("b").gotoAndStop(frame);
	}

	override public function explode() {
		// (the shards only change the picture: the visual random)
		for (i in 0...3) {
			var p = new Part(Cs.game.dm.attach("partIce", Game.DP_PART));
			var a = Seed.randVfx() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = 0.5 + Seed.randVfx() * 3;
			var ray = 5;
			p.x = root._x + ca * ray;
			p.y = root._y + sa * ray;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.vr = (Seed.randVfx() * 2 - 1) * 16;
			p.weight = 0.1 + Seed.randVfx() * 0.2;
			p.root._rotation = a / 0.0157 + 90;
			p.root.gotoAndPlay(Seed.randomVfx(20) + 1);
			p.timer = 10 + Seed.randVfx() * 50;
			p.scale = 50 + Seed.randVfx() * 100;
			p.fadeType = 1;
			p.root._xscale = p.scale;
			p.root._yscale = p.scale;
		}
		super.explode();
	}
}
