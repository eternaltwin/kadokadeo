package cerealpunk;

// Legume.mt: a cereal of the grid (or a bubble, a stone, a bonus)
class Legume {
	var game:Game;

	public var id:Int;
	// (undefined until set in Flash: false)
	public var moved:Bool = false;
	public var blast:Bool = false;
	public var mc:MC;

	// (undefined until initExplode sets it: NaN, like Flash, for the bonuses)
	var timer:Float = Math.NaN;

	public var life:Int;
	public var gold:Bool;

	public function new(g:Game, id:Int, x:Int, y:Int) {
		game = g;
		this.id = id;
		mc = game.dmanager.attach("legume", Const.PLAN_LEGUME);
		mc._x = x * 30 + Const.DX;
		mc._y = y * 30 + Const.DY;
		mc.gotoAndStop(Std.string(id + 1));
		var sub = mc.sub("sub");
		if (sub != null)
			sub.stop();
		life = Const.PIERRE_LIFE;
		gold = (id >= Const.GOLD && id < Const.GOLD + 6);
		if (gold)
			this.id -= Const.GOLD;
	}

	// (the particles only change the picture: visual random)
	static inline function rnd():Float {
		return Seed.randVfx();
	}

	public function initExplode() {
		switch (id) {
			case Const.BULLE:
				timer = 0;
				for (i in 0...8) {
					var p = game.animator.newPart("partBubble");
					var a = rnd() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var ray = 16;
					var sp = 0.5 + rnd() * 0.5;
					p._x = mc._x + ca * ray;
					p._y = mc._y + sa * ray;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.frict = 0.96;
					p.timer = 10 + rnd() * 10;
				}
				mc.removeMovieClip();

			case Const.BONUS1, Const.BONUS2:
				var link = "partBonus2";
				if (id == Const.BONUS1)
					link = "partBonus";
				for (i in 0...24) {
					var p = game.animator.newPart(link);
					var a = rnd() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var ray = rnd() * 20;
					var sp = 1 + rnd() * 5;
					p._x = mc._x + ca * ray;
					p._y = mc._y + sa * ray;
					p.vx = ca * sp;
					p.vy = -Math.abs(sa * sp);
					p.vr = (rnd() * 2 - 1) * 20;
					p.fvr = 0.98;
					p.frict = 0.97;
					p.weight = 0.05 + rnd() * 0.2;
					p.timer = 10 + rnd() * 35;
					p.scale = 50 + rnd() * 60;
					p._xscale = p.scale;
					p._yscale = p.scale;
					p.gotoAndPlay(Std.string(Seed.randomVfx(p._totalframes) + 1));
				}
				mc.removeMovieClip();

			default:
				for (i in 0...8) {
					var p = game.animator.newPart("partRay");
					p._x = mc._x;
					p._y = mc._y;
					p._rotation = rnd() * 360;
					p._xscale = 30 + rnd() * 60;
					p.scale = 150 + rnd() * 350;
					p._yscale = p.scale;
					p.vr = 0.5 + rnd() * 4;
					p.fvr = 0.9 + rnd() * 0.1;
					p.timer = 10 + rnd() * 10;
					p.ft = 0;
					p.gotoAndStop(Std.string(Seed.randomVfx(p._totalframes) + 1));
				}
				timer = 0;
				var pc = game.animator.newPart("partCircle");
				pc._x = mc._x;
				pc._y = mc._y;
		}
	}

	public function initDestroy() {
		switch (id) {
			case Const.BONUS1, Const.BONUS2:
				for (i in 0...8) {
					var p = game.animator.newPart("partBonusDie");
					var a = rnd() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var ray = 8;
					var sp = 1 + rnd() * 3;
					p._x = mc._x + ca * ray;
					p._y = mc._y + sa * ray;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.frict = 0.96;
					p.timer = 10 + rnd() * 10;
					p.scale = 50 + rnd() * 80;
					p._xscale = p.scale;
					p._yscale = p.scale;
					var frame = 1;
					if (rnd() < 0.5) {
						frame = 2;
						if (id == Const.BONUS1)
							frame = 3;
					}
					p.gotoAndStop(Std.string(frame));
				}

				var pc = game.animator.newPart("partCircle2");
				pc._x = mc._x;
				pc._y = mc._y;
				var sc = 150;
				pc._xscale = sc;
				pc._yscale = sc;

				mc.removeMovieClip();
			default:
				for (i in 0...8) {
					var p = game.animator.newPart("partPiece");
					var a = rnd() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var ray = 6 + rnd() * 10;
					var sp = 0.5 + rnd() * 3;
					p._x = mc._x + ca * ray;
					p._y = mc._y + sa * ray;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.frict = 0.96;
					p.timer = 10 + rnd() * 10;
				}

				var pc = game.animator.newPart("partCircle2");
				pc._x = mc._x;
				pc._y = mc._y;
				mc.removeMovieClip();
		}
	}

	// false: done (taken out of Animator.explodes)
	public function explodeMain():Bool {
		switch (id) {
			case Const.BULLE:
				return false;
			default:
				timer += Timer.tmod;
				Const.setPercentColor(mc, Math.min(timer * 25, 100), 0xFFFFFF);
				var lim = 10;
				if (timer > lim) {
					mc._xscale -= (timer - lim) * Timer.tmod;
					mc._yscale = mc._xscale;
					timer += 2 * Timer.tmod;
				}

				// compiled `!(_xscale > 0)`: true for a removed clip (a bonus, a destroyed cereal: undefined)
				if (!(mc._xscale > 0)) {
					mc.removeMovieClip();
					return false;
				}
		}
		return true;
	}

	// a stone next to an explosion cracks; at its last life it disappears or turns into a bonus. false: removed
	public function stoneParts():Bool {
		life--;

		for (i in 0...8) {
			var p = game.animator.newPart("partStone");
			var a = rnd() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var ray = 10 + rnd() * 5;
			p._x = mc._x + ca * ray;
			p._y = mc._y + sa * ray;
			p.vx = 0;
			p.vy = 0;
			p.frict = 0.96;
			p.weight = 0.2 + rnd() * 0.5;
			p.timer = 10 + rnd() * 10;
		}

		var sub = mc.sub("sub");
		if (sub != null)
			sub.gotoAndStop(Std.string(Const.PIERRE_LIFE + 1 - life));
		if (life == 0) {
			if (Seed.random(2) == 0) {
				mc.removeMovieClip();
				return false;
			}
			id = Const.BONUS1 + (Seed.random(20) == 0 ? 1 : 0);
			mc.gotoAndStop(Std.string(id + 1));
		}
		return true;
	}
}
