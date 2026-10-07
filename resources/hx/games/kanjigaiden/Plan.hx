package kanjigaiden;

import kanjigaiden.MC.Plans;
import pixi.core.display.Container;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;

// Plan.hx of the original: a plane of the forest (cz: its depth, 0 far, 1 near), its bitmap of bamboos and grass, the
// monkeys on it
class Plan {
	public static var DP_M = 1;
	public static var DP_CANVAS = 2;
	public static var DP_BB = 3;

	public static var me:Plan;

	public var mcPlan:MC;
	public var cz:Float;
	public var z:Float;

	public var dm:Plans;
	public var width:Int;

	public var nbPl:Int;

	public var nbBamb:Int;

	public var bamboos:Array<Float>;

	public var monkeys:Array<Monkey>;

	// port: the bitmap of the plane (BitmapData of width + 20 x 300, drawn once by drawB), a render texture at 2 px
	// per Flash pixel; null for the planes that draw nothing in it (the foreground, the background)
	var canvas:RenderTexture;

	// port: the copy of the pictures of this plane (its scale and colour baked: kanjigaiden_assets.py), -1: none
	var gfx:Int;

	public function new(mc:MC, nb:Int, dev:Float, type:Int) {
		mcPlan = mc;
		me = this;
		nbPl = nb;
		cz = dev;

		width = Math.ceil((300 + 600 * (1 - cz)));

		var pos = Game.me.getPos(cz);
		mcPlan._x = pos.x;
		z = Cs.mch * 0.5 + pos.y;

		dm = new Plans(mc.clip, mc);

		gfx = type == 1 ? -1 : nbPl;

		switch (type) {
			case 0:
				// Bamboonier
				newCanvas();
				bamboos = [];
				initBambooDraw();
				initNature();

			case 1:
			// FG

			case 2:
				// Interplan
				newCanvas();
				initNature();
		}
	}

	public function update() {
		var pos = Game.me.getPos(cz);
		mcPlan._x = -pos.x;
	}

	// port: the copy of the monkey for this plane (its scale and the colour of the plane baked)
	inline function monkeyClip():String {
		return "monkey" + nbPl;
	}

	public function addMonkey() {
		var mmc = dm.attach(monkeyClip(), DP_M);
		var m:Monkey = new Monkey(mmc, cz, z, nbPl);
		Game.me.monkeys.push(m);
	}

	public function addMonkeyTyped(mtype:Int, life:Int, diff:Int, btype:Int) {
		var mmc = dm.attach(monkeyClip(), DP_M);
		var m:Monkey = new Monkey(mmc, cz, z, nbPl, mtype, life, diff, btype);
		Game.me.monkeys.push(m);
	}

	// ---------------------------------------------------------------- the bitmap
	// canvas: BitmapData(width + 20, Cs.mch, true, 0) attached at depth DP_CANVAS of the plane, at (0, 0)
	function newCanvas() {
		var r:Dynamic = KadoKadeoManager.kkm.renderer;
		if (r == null)
			return;
		canvas = (cast RenderTexture : Dynamic).create({width: (width + 20) * Clip.K, height: Cs.mch * Clip.K, resolution: 1});
		var s = new PixiSprite(canvas);
		s.scale.set(1 / Clip.K, 1 / Clip.K);
		dm.get(DP_CANVAS).addChild(s);
	}

	// a bamboo as drawB drew it: its parts (the strip masked by the outline, the dot, the bottom and the leaves on
	// their frames) through the matrix scale(xscale, |xscale|), rotate(3.14 * rotation / 180), translate(x, y)
	function drawBamboo(x:Float, y:Float, xscale:Float, rotation:Float, maskY:Float, bottom:Int, taupe:Int) {
		var r:Dynamic = KadoKadeoManager.kkm.renderer;
		if (r == null || canvas == null)
			return;
		var k = Clip.K * cz;
		// the outline of the bamboo masking the strip `mask` (moved to mask._y): composed in a picture the size of the
		// outline's (its trimmed rectangle in the sheet), the strip then the outline's alpha (DST_IN)
		var stalk = Tex.get("bbStalk" + gfx)[0];
		var tr = stalk.trim;
		var tx0 = tr != null ? tr.x : 0.0;
		var ty0 = tr != null ? tr.y : 0.0;
		var tw = tr != null ? tr.width : stalk.width;
		var th = tr != null ? tr.height : stalk.height;
		var tmp:RenderTexture = (cast RenderTexture : Dynamic).create({width: Math.ceil(tw), height: Math.ceil(th), resolution: 1});
		var c = new Container();
		// (texture pixels of the outline, its origin at ax, ay: k per Flash pixel of the bamboo, like the strip's)
		var ax = stalk.defaultAnchor.x * stalk.width - tx0;
		var ay = stalk.defaultAnchor.y * stalk.height - ty0;
		var vine = part("bbVine" + gfx, 1, k);
		vine.scale.set(Data.BB_VINE[0], Data.BB_VINE[3]);
		vine.position.set((Data.BB_VINE[4] - Data.BB_STALK[4]) * k + ax, (maskY - Data.BB_STALK[5]) * k + ay);
		c.addChild(vine);
		var out = new PixiSprite(stalk);
		out.position.set(-tx0, -ty0);
		out.blendMode = cast 25; // PIXI.BLEND_MODES.DST_IN
		c.addChild(out);
		r.render(c, {renderTexture: tmp, clear: true});
		c.destroy({children: true});

		var b = new Container();
		var masked = new PixiSprite(tmp);
		masked.scale.set(1 / k, 1 / k);
		masked.position.set(Data.BB_STALK[4] - ax / k, Data.BB_STALK[5] - ay / k);
		b.addChild(masked);
		b.addChild(placed("bbDot" + gfx, 1, k, Data.BB_DOT));
		b.addChild(placed("bbBottom" + gfx, bottom, k, Data.BB_BOTTOM));
		b.addChild(placed("bbTaupe" + gfx, taupe, k, Data.BB_TAUPE));
		draw(b, x, y, xscale, rotation);
		tmp.destroy(true);
	}

	// a picture of this plane (at k px per Flash pixel of the bamboo), with its pivot at the origin
	static function part(anim:String, frame:Int, k:Float):PixiSprite {
		var t = Tex.get(anim)[frame - 1];
		var s = new PixiSprite(t);
		s.anchor.copyFrom(t.defaultAnchor);
		s.scale.set(1 / k, 1 / k);
		return s;
	}

	static function placed(anim:String, frame:Int, k:Float, m:Array<Float>):PixiSprite {
		var s = part(anim, frame, k);
		s.position.set(m[4], m[5]);
		return s;
	}

	// canvas.bmp.draw(b, m) of drawB
	function draw(b:Container, x:Float, y:Float, xscale:Float, rotation:Float) {
		var r:Dynamic = KadoKadeoManager.kkm.renderer;
		var sx = xscale / 100;
		var sy = Math.abs(xscale) / 100;
		var a = 3.14 * rotation / 180;
		var K = Clip.K;
		var m = new Matrix(Math.cos(a) * sx * K, Math.sin(a) * sx * K, -Math.sin(a) * sy * K, Math.cos(a) * sy * K, x * K, y * K);
		var holder = new Container();
		b.transform.setFromMatrix(m);
		holder.addChild(b);
		r.render(holder, {renderTexture: canvas, clear: false});
		holder.destroy({children: true});
	}

	function initBambooDraw() {
		// (the clip `bamboo` attached, drawn and removed: its _x / _y / _xscale / _rotation as Flash keeps them; its
		// nested frames, mask._y and side are only pictures: visual random)
		var bx:Float;
		var by:Float;
		var bxs:Float;
		var brot:Float;
		var maskY:Float = 0;

		var taupe = Seed.randomVfx(Data.BB_TAUPES) + 1;
		var bottom = Seed.randomVfx(Data.BB_BOTTOMS) + 1;
		bx = 0;
		by = MC.twips(z - Cs.SPHERATIO * Math.sin(0));
		brot = -Cs.SPHERANGLE;
		bxs = (cz * 100);
		drawBamboo(bx, by, bxs, brot, maskY, bottom, taupe);

		taupe = Seed.randomVfx(Data.BB_TAUPES) + 1;
		bottom = Seed.randomVfx(Data.BB_BOTTOMS) + 1;
		bx = width;
		by = MC.twips(z - Cs.SPHERATIO * Math.sin(3.14));
		bxs = (cz * 100);
		brot = Cs.SPHERANGLE;
		drawBamboo(bx, by, bxs, brot, maskY, bottom, taupe);

		var nb = Math.ceil((width) / 120) + nbPl * 7;
		var range = Math.ceil(width / nb);

		for (i in 0...nb) {
			taupe = Seed.randomVfx(Data.BB_TAUPES) + 1;
			bottom = Seed.randomVfx(Data.BB_BOTTOMS) + 1;
			bx = MC.twips(range * i + Seed.random((range - 30)) - (range - 30) / 2);
			var ratiooo = Math.sin(bx / width * 3.14);
			by = MC.twips(z - Cs.SPHERATIO * ratiooo);
			if (bx < (width * 0.5))
				brot = -(Cs.SPHERANGLE - ratiooo * Cs.SPHERANGLE);
			else
				brot = Cs.SPHERANGLE - ratiooo * Cs.SPHERANGLE;

			if (Seed.randomVfx(2) == 1)
				bxs = (cz * 100);
			else
				bxs = -(cz * 100);

			maskY = Seed.randomVfx(385);

			drawBamboo(bx, by, bxs, brot, maskY, bottom, taupe);
			bamboos.push(bx);
		}
	}

	function initNature() {
		var nb = Math.ceil(width / (100 * cz));

		for (i in 0...nb) {
			var hx = MC.twips(i * 300 * cz);
			var ratiooo = Math.sin(hx / width * 3.14);
			var hy = MC.twips(z - Cs.SPHERATIO * ratiooo + cz * (20));
			var r:Dynamic = KadoKadeoManager.kkm.renderer;
			if (r != null && canvas != null) {
				var b = new Container();
				b.addChild(part("herbes" + gfx, 1, Clip.K * cz));
				draw(b, hx, hy, cz * 100, 0);
			}
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

	public function hittest(x:Float, type:Int):Bool {
		var ret = false;
		// (the background plane has no bamboos: in Flash the loop over undefined does nothing)
		if (bamboos != null)
			for (b in bamboos) {
				var left = mcPlan._x + b - 30 * cz;
				var right = mcPlan._x + b + 30 * cz;
				if (x < right && x > left)
					ret = true;
			}
		#if debug
		if (ret)
			Game.me.stats.bamboo++;
		#end

		if (!ret) {
			for (m in Game.me.monkeys) {
				if ((m.pl == nbPl) && !m.protected) {
					var w = m.width();
					var left = mcPlan._x + m.x - w * 0.5;
					var right = mcPlan._x + m.x + w * 0.5;
					if (x < right && x > left)
						ret = true;
					if (ret) {
						m.ouch(type);
						return ret;
					}
				}
			}
		}

		return ret;
	}

	public function dispose() {
		if (canvas != null)
			canvas.destroy(true);
		canvas = null;
	}
}
