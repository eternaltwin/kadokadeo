package cyclopean;

class Ball extends Phys {
	public static inline var RAY = 8;
	public static inline var WEIGHT = 0.5;

	var vrot:Float;

	public function new() {
		var mc = Cs.game.dm.attach("piou", Game.DP_PIOU);
		super(mc);

		frict = 0.98;
		weight = 0.5;

		// the spin only turns the picture: visual random
		vrot = (Seed.randVfx() * 2 - 1) * 20;
		root._rotation = Seed.randVfx() * 360;
		root._xscale = 135;
		root._yscale = root._xscale;
		//
		var rb = new RoundBouncer(this);
		bouncer = rb;
		bouncer.frict = 0.5;
		rb.setRoundShape(RAY, 16);
		// (onSwapPixel = traceQueue: it copies a trace into Cs.game.prc, a bitmap the game never creates: nothing)
		rb.hitPoint = impact;
		// (initTrace: the trace bitmap of traceQueue)
	}

	override public function update():Void {
		var eList = Cs.game.eList;
		var i = 0;
		// (e.collide can remove the element: the next one moves to index i and waits for the next frame)
		while (i < eList.length) {
			var e = eList[i];
			var dx = x - e.x;
			var dy = y - e.y;
			var screen_limit = 280;
			if (Math.abs(dx) < screen_limit && Math.abs(dy) < screen_limit) {
				if (!e.flActive)
					e.attach();
				if (getDist(e) < RAY + Element.RAY) {
					e.collide(this);
				}
			} else {
				if (e.flActive)
					e.detach();
			}
			i++;
		}

		// (once per Flash frame, not scaled by tmod)
		root._rotation += vrot;

		super.update();
	}

	function impact(cp:{x:Int, y:Int}):Void {
		var pw = Cs.mm(0, Math.sqrt(vx * vx + vy * vy) * 0.5 - 3, 8);

		var i = 0;
		while (i < pw) {
			var p = Cs.game.newPart("partImpact");
			var a = Seed.randVfx() * 6.28;
			var sp = 0.5 + Seed.randVfx() * pw * 2;
			p.x = cp.x;
			p.y = cp.y;
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.vr = (Seed.randVfx() * 2 - 1) * 20;
			p.timer = 10 + Seed.randVfx() * 10;
			p.fadeType = 0;
			p.setScale(50 + Seed.randVfx() * 80);
			p.root._rotation = Seed.randVfx() * 360;
			p.bouncer = new Bouncer(p);
			i++;
		}
		vrot = (Seed.randVfx() * 2 - 1) * (10 + pw * 2);
	}
	// (blast: never called)
}
