package kanjigaiden;

import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;

class AnonSprite7666957 extends ASprite {
	public var bmp:RenderTexture;
}

class Bamboo extends ASprite {
	public var taupe:ASprite;
	public var bottom:ASprite;
}

class Plan { // }
	public static var DP_M = 1;
	public static var DP_CANVAS = 2;
	public static var DP_BB = 3;

	public static var me:Plan;

	public var mcPlan:ASprite;
	public var cz:Float;
	public var z:Float;

	public var dm:mt.DepthManager;
	public var width:Int;

	public var nbPl:Int;

	public var nbBamb:Int;

	public var bamboos:Array<Float> = [];

	public var monkeys:Array<Monkey> = [];

	var canvas:AnonSprite7666957;

	public function new(mc:ASprite, nb:Int, dev:Float, type:Int) {
		mcPlan = mc;
		me = this;
		nbPl = nb;
		cz = dev;

		width = Math.ceil((900 + 1800 * (1 - cz)));

		var pos = Game.me.getPos(cz);
		mcPlan._x = pos.x;
		z = Cs.mch * 0.5 + pos.y;

		dm = new mt.DepthManager(mc);

		canvas = cast dm.empty(DP_CANVAS);
		canvas._x = 0;
		canvas._y = 0;

		var bmp = RenderTexture.create(width + 20, Cs.mch);
		canvas.bmp = bmp;

		switch (type) {
			case 0:
				// Bamboonier
				bamboos = [];
				// initBamboo();
				initBambooDraw();
				initNature();

			case 1:
				// FG

			case 2:
				// Interplan
				initNature();
		}

		canvas.attachBitmap(bmp, 0);
	}

	public function update() {
		var pos = Game.me.getPos(cz);
		mcPlan._x = -pos.x;
	}

	public function addMonkey() {
		var m:Monkey = new Monkey(this, cz, z, nbPl);
		Game.me.monkeys.push(m);
	}

	public function addMonkeyTyped(mtype:Int, life:Int, diff:Int, btype:Int) {
		var m:Monkey = new Monkey(this, cz, z, nbPl, mtype, life, diff, btype);
		Game.me.monkeys.push(m);
	}

	function drawB(b:ASprite) {
		canvas.bmp.draw(b, new Matrix());
	}

	function initBambooDraw() {
		var b:Bamboo = cast new ASprite("bamboo");
		trace(b);
		b.anchor.set(0.5, 1);
		b.taupe = new ASprite('taupe');
		b.addChild(b.taupe);
		b.taupe.position.set(9, -328);
		b.bottom = new ASprite('bambooBottom');
		b.addChild(b.bottom);
		b.bottom.position.set(8, 11);

		b.taupe.gotoAndStop(Std.random(b.taupe._totalframes) + 1);
		b.bottom.gotoAndStop(Std.random(b.bottom._totalframes) + 1);
		b._x = 0;
		b._y = z - Cs.SPHERATIO * Math.sin(0);
		b._rotation = -Cs.SPHERANGLE;
		b._xscale = (cz * 100);
		b._yscale = b._xscale;
		drawB(b);

		b.taupe.gotoAndStop(Std.random(b.taupe._totalframes) + 1);
		b.bottom.gotoAndStop(Std.random(b.bottom._totalframes) + 1);
		b._x = width;
		b._y = z - Cs.SPHERATIO * Math.sin(3.14);
		b._xscale = (cz * 100);
		b._yscale = b._xscale;
		b._rotation = Cs.SPHERANGLE;
		drawB(b);

		var nb = Math.ceil((width) / 120) + nbPl * 7;
		var range = Math.ceil(width / nb);

		for (i in 0...nb) {
			b.taupe.gotoAndStop(Std.random(b.taupe._totalframes) + 1);
			b.bottom.gotoAndStop(Std.random(b.bottom._totalframes) + 1);
			b._x = range * i + Std.random((range - 30)) - (range - 30) / 2;
			var ratiooo = Math.sin(b._x / width * 3.14);
			b._y = z - Cs.SPHERATIO * ratiooo;
			if (b._x < (width * 0.5))
				b._rotation = -(Cs.SPHERANGLE - ratiooo * Cs.SPHERANGLE);
			else
				b._rotation = Cs.SPHERANGLE - ratiooo * Cs.SPHERANGLE;

			if (Std.random(2) == 1)
				b._xscale = (cz * 100);
			else
				b._xscale = -(cz * 100);

			b._yscale = Math.abs(b._xscale);
			// (cast b.mask).y = Std.random(385);

			drawB(b);
			bamboos.push(b._x);
		}
	}

	function initNature() {
		var nb = Math.ceil(width / (100 * cz));

		for (i in 0...nb) {
			var h = new ASprite("herbes");
			h._x = i * 300 * cz;
			h._y = z;
			h._xscale = (cz * 100);
			h._yscale = h._xscale;

			var ratiooo = Math.sin(h._x / width * 3.14);
			h._y = z - Cs.SPHERATIO * ratiooo + cz * (20);

			drawB(h);
			h.removeMovieClip();
		}
	}

	public function move(dir:Int) {
		switch (dir) {
			case 0:
				if (mcPlan._x > -(width - Cs.mcw)) {
					mcPlan._x -= Cs.DEV * cz;
				} else {
					mcPlan._x = -(width - Cs.mcw);
				}
			case 1:
				if ((mcPlan._x) < width) {
					mcPlan._x += Cs.DEV * cz;
				} else {
					mcPlan._x = width;
				}
		}
	}

	public function hittest(x:Float, type):Bool {
		var ret = false;
		for (b in bamboos) {
			var left = mcPlan._x + b - 30 * cz;
			var right = mcPlan._x + b + 30 * cz;
			if (x < right && x > left)
				ret = true;
		}

		if (!ret) {
			var rect:Rectangle = new Rectangle();
			for (m in Game.me.monkeys) {
				if ((m.pl == nbPl) && !m.protected) {
					m.mcMonkey.smc.getBounds(true, rect);
					var left = mcPlan._x + m.x - rect.width * 0.5;
					var right = mcPlan._x + m.x + rect.width * 0.5;
					if (x < right && x > left) {
						m.ouch(type);
						return ret;
					}
				}
			}
		}

		return ret;
	}

	// {
}
