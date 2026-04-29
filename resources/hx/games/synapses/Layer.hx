package synapses;

import mt.bumdum.Lib;
import pixi.core.math.Matrix;

class Layer {
	public static var DEEP = 6;
	public static inline var RT_SCALE:Float = 0.5;

	public var root:ASprite;
	public var trg:ASprite;
	public var dm:mt.DepthManager;

	public var dx:Float;
	public var dy:Float;

	public var bmp:RenderTexture;

	public var cels:Array<ASprite>;

	public function new() {
		root = Game.me.dm.empty(Game.DP_BRANCH);
		dm = new mt.DepthManager(root);

		var rtWidth = Std.int(Math.ceil(Cs.mcw * RT_SCALE));
		var rtHeight = Std.int(Math.ceil(Cs.mch * RT_SCALE));
		bmp = RenderTexture.create(rtWidth, rtHeight);
		// bmp = new flash.display.BitmapData(Cs.mcw, Cs.mch, true, 0);

		trg = dm.empty(10);
		trg.attachBitmap(bmp, 1);
		trg._xscale = trg._yscale = 100 / RT_SCALE;

		// Filt.glow(root, 10 * Cs.NEW_GEN_SCALE, 1, 0xFFFFFF);
	}

	public function draw(mc:ASprite) {
		var m = new Matrix();
		m.scale(RT_SCALE, RT_SCALE);
		// m.scale(mc._xscale * 0.01, mc._yscale * 0.01);
		// m.rotate(mc._rotation * 0.0174);
		// m.translate(mc._x, mc._y);
		// trace("Drawing at " + mc._x + ", " + mc._y + " with scale " + mc.scale.x + ", " + mc.scale.y + " and rotation " + untyped mc.angle);
		bmp.draw(mc, m);
	}

	public function initTunnel(x, y) {
		dx = x;
		dy = y;
		root.filters = [];
		trg.filters = [];
		Game.me.tunnel.unshift(this);

		cels = [];

		//
		for (i in 0...8) {
			var mc = dm.attach("mcCell", 0);
			mc._xscale = mc._yscale = 50 + Seed.randVfx() * 75;
			mc._rotation = Seed.randVfx() * 360;
			mc.gotoAndStop(Seed.randomVfx(mc._totalframes) + 1);
			// imc.gotoAndStop(1);

			var sx = Seed.randVfx() * 2 - 1;
			var sy = Seed.randVfx() * 2 - 1;

			if (Seed.randomVfx(2) == 0)
				sx = Seed.randomVfx(2) * 2 - 1;
			else
				sy = Seed.randomVfx(2) * 2 - 1;

			var rx = Cs.mcw * 0.5 + mc._width * 0.5 + Seed.randVfx() * (200 * Cs.NEW_GEN_SCALE);
			var ry = Cs.mch * 0.5 + mc._height * 0.5 + Seed.randVfx() * (200 * Cs.NEW_GEN_SCALE);

			mc._x = Cs.mcw * 0.5 + rx * sx;
			mc._y = Cs.mch * 0.5 + ry * sy;

			cels.push(mc);
		}
	}

	public function updateTunnel(n:Float) {
		var c = 1 - n / DEEP;
		var c = Math.pow(c, 2);

		var ray = Cs.mcw * 0.5;
		root._x = ray + (Game.me.bdx + dx - ray) * c;
		root._y = ray + (Game.me.bdy + dy - ray) * c;
		root._xscale = root._yscale = c * 100;

		root.filters = [];
		var bl = (1 - c) * 6;
		// Filt.blur(root,bl,bl);

		if (c <= 0) {
			Game.me.tunnel.remove(this);
			kill();
		}

		var cc = 1 - c;
		Col.setPercentColor(root, 20 + cc * 80, Game.BG_COLOR);

		//
		var coef = n - Math.abs(n);
		if (mt.Timer.tmod > 1.4) {
			for (mc in cels) {
				mc._xscale *= Game.me.frict;
				mc._yscale = mc._xscale;
			}
			if (cels[0]._xscale < 5)
				while (cels.length > 0)
					cels.pop().removeMovieClip();
		}
	}

	public function kill() {
		bmp.destroy();
		root.removeMovieClip();
	}
}
