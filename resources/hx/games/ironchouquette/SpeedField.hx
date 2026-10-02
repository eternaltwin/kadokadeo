package ironchouquette;

import js.lib.Float32Array;
import js.lib.Uint8ClampedArray;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite;
import pixi.core.textures.Texture;

/**
	CPU copy of the plasma layer 0 for the SPEED weapon: a bad standing in a red part of the layer takes damage (Bads
	"SPEED COLOR", getPixel32 of the original). Reading the GPU texture back stalled the graphics card, and its pixels
	may differ from one graphics card to another while replays must give the same game everywhere: this layer is
	computed here like the BitmapData of the original, with the same stamps (the speed blobs, and the missile trails
	that whiten them), the same blur (box), ColorTransform and scroll, at the resolution of the GPU layer, in 8 bits with
	premultiplied alpha like a BitmapData: that rounding makes the faint edges of the trail lose their green first, which
	is part of where bads get hurt.
	It only runs while the hero has the SPEED weapon, on the part of the grid where there is something.
**/
class SpeedField {
	// mcSpeed frames: plain colour, alpha 255 * (1 - r / 31) (r: distance to the centre, in pixels of the 60x60 picture)
	static var SPEED_COLORS = [[148, 18, 69], [175, 14, 116], [202, 9, 162], [228, 5, 209], [255, 0, 255]];
	// mcQueueStandard: white, alpha across its 12 rows (the same along its length)
	static var QUEUE_ALPHA = [51, 51, 50, 70, 236, 255, 255, 236, 70, 50, 51, 51];

	public var active(default, null) = false;

	var w:Int;
	var h:Int;
	// premultiplied, 8 bits (blue is never read)
	var r:Uint8ClampedArray;
	var g:Uint8ClampedArray;
	var a:Uint8ClampedArray;
	var line:Float32Array;
	// part of the grid that can hold something (x1, y1 excluded)
	var x0 = 0;
	var x1 = 0;
	var y0 = 0;
	var y1 = 0;
	var speedTex:Array<Texture>;
	var queueTex:Texture;

	public function new(w:Int, h:Int) {
		this.w = w;
		this.h = h;
		r = new Uint8ClampedArray(w * h);
		g = new Uint8ClampedArray(w * h);
		a = new Uint8ClampedArray(w * h);
		line = new Float32Array(Std.int(Math.max(w, h)) + 16);
		var cache:Dynamic = untyped PIXI.utils.TextureCache;
		speedTex = [for (i in 1...6) Reflect.field(cache, 'mcSpeed/$i.png')];
		queueTex = Reflect.field(cache, "mcQueueStandard.png");
	}

	/** Called at the start of each step, before the stamps: `on` while the hero has the SPEED weapon. **/
	public function step(on:Bool, blur:Float, scroll:Int) {
		if (!on) {
			if (active)
				clear();
			active = false;
			return;
		}
		active = true;
		if (x1 > x0 && y1 > y0)
			process(blur, scroll);
	}

	/** Same stamp as `PlasmaLayer.draw` (BitmapData.draw(mc, m, alpha offset)), for the pictures that matter here. **/
	public function draw(mc:Sprite, m:Matrix, alpha:Float) {
		if (!active || mc == null || !mc.visible)
			return;
		var t = mc.texture;
		var kind = -1;
		for (i in 0...speedTex.length)
			if (t == speedTex[i])
				kind = i;
		if (kind < 0 && (t == null || t != queueTex))
			return;
		var tw = t.orig.width, th = t.orig.height;
		var lx0 = -mc.anchor.x * tw, ly0 = -mc.anchor.y * th;

		// bounding box in the grid
		var bx0 = 1e9, by0 = 1e9, bx1 = -1e9, by1 = -1e9;
		for (c in 0...4) {
			var lx = lx0 + (c & 1) * tw, ly = ly0 + (c >> 1) * th;
			var gx = m.a * lx + m.c * ly + m.tx, gy = m.b * lx + m.d * ly + m.ty;
			bx0 = Math.min(bx0, gx);
			bx1 = Math.max(bx1, gx);
			by0 = Math.min(by0, gy);
			by1 = Math.max(by1, gy);
		}
		var gx0 = Std.int(Math.max(0, Math.floor(bx0))), gx1 = Std.int(Math.min(w, Math.ceil(bx1)));
		var gy0 = Std.int(Math.max(0, Math.floor(by0))), gy1 = Std.int(Math.min(h, Math.ceil(by1)));
		if (gx1 <= gx0 || gy1 <= gy0)
			return;
		var det = m.a * m.d - m.b * m.c;
		if (Math.abs(det) < 1e-9)
			return;
		var ia = m.d / det, ib = -m.b / det, ic = -m.c / det, id = m.a / det;
		var itx = -(ia * m.tx + ic * m.ty), ity = -(ib * m.tx + id * m.ty);
		// ColorTransform of plasmaDraw: alpha offset -255 + _alpha * 2.55
		var aoff = (alpha - 1) * 255;
		var cr = 255.0, cg = 255.0;
		if (kind >= 0) {
			cr = SPEED_COLORS[kind][0];
			cg = SPEED_COLORS[kind][1];
		}
		var drawn = false;
		for (y in gy0...gy1) {
			var py = y + 0.5;
			// position in the picture of the centre of the pixel
			var lx = ia * (gx0 + 0.5) + ic * py + itx - lx0;
			var ly = ib * (gx0 + 0.5) + id * py + ity - ly0;
			for (x in gx0...gx1) {
				// nearest pixel of the picture (no smoothing)
				var tx = Math.floor(lx), ty = Math.floor(ly);
				lx += ia;
				ly += ib;
				if (tx < 0 || ty < 0 || tx >= tw || ty >= th)
					continue;
				var sa:Float;
				if (kind >= 0) {
					var dx = tx + 0.5 - tw / 2, dy = ty + 0.5 - th / 2;
					sa = 255 * (1 - Math.sqrt(dx * dx + dy * dy) / 31);
				} else {
					sa = QUEUE_ALPHA[Std.int(ty * QUEUE_ALPHA.length / th)];
				}
				sa += aoff;
				if (sa <= 0)
					continue;
				var f = sa / 255, k = 1 - f, i = y * w + x;
				put(r, i, cr * f + r[i] * k);
				put(g, i, cg * f + g[i] * k);
				put(a, i, sa + a[i] * k);
				drawn = true;
			}
		}
		if (!drawn)
			return;
		if (x1 <= x0 || y1 <= y0) {
			x0 = gx0;
			x1 = gx1;
			y0 = gy0;
			y1 = gy1;
		} else {
			x0 = Std.int(Math.min(x0, gx0));
			x1 = Std.int(Math.max(x1, gx1));
			y0 = Std.int(Math.min(y0, gy0));
			y1 = Std.int(Math.max(y1, gy1));
		}
	}

	/** Colour at a pixel of the grid like getPixel32 (0xRRGGBB, blue left at 0), 0 where there is nothing. **/
	public function getPixel(x:Int, y:Int):Int {
		if (!active || x < x0 || y < y0 || x >= x1 || y >= y1)
			return 0;
		var i = y * w + x;
		var al = a[i];
		if (al == 0)
			return 0;
		var cr = Std.int(Math.min(255, Math.round(r[i] * 255 / al)));
		var cg = Std.int(Math.min(255, Math.round(g[i] * 255 / al)));
		return (cr << 16) | (cg << 8);
	}

	// blur (box of `blur` pixels, outside the grid is transparent), ColorTransform -2 on the colours, scroll
	function process(blur:Float, scroll:Int) {
		var k = Std.int(Math.max(0, Math.ceil(blur / 2 - 0.5)));
		var wk = [for (i in 0...k + 1) Math.min(1, Math.max(0, blur / 2 + 0.5 - i)) / blur];
		var nx0 = Std.int(Math.max(0, x0 - k)), nx1 = Std.int(Math.min(w, x1 + k));
		var ny0 = Std.int(Math.max(0, y0 - k)), ny1 = Std.int(Math.min(h, y1 + k));

		if (k == 1) {
			// the usual case (blur 1.5): two sweeps, the vertical one does the ColorTransform and the bounds
			blur3(wk[0], wk[1], nx0, nx1, ny0, ny1, scroll);
			return;
		}
		for (ch in [r, g, a]) {
			// rows of the region, horizontally
			for (y in y0...y1) {
				var row = y * w;
				for (x in nx0 - k...nx1 + k)
					line[x - nx0 + k] = (x >= x0 && x < x1) ? ch[row + x] : 0;
				for (x in nx0...nx1) {
					var s = line[x - nx0 + k] * wk[0];
					for (j in 1...k + 1)
						s += (line[x - nx0 + k - j] + line[x - nx0 + k + j]) * wk[j];
					put(ch, row + x, s);
				}
			}
			// columns of the widened region, vertically
			for (x in nx0...nx1) {
				for (y in ny0 - k...ny1 + k)
					line[y - ny0 + k] = (y >= y0 && y < y1) ? ch[y * w + x] : 0;
				for (y in ny0...ny1) {
					var s = line[y - ny0 + k] * wk[0];
					for (j in 1...k + 1)
						s += (line[y - ny0 + k - j] + line[y - ny0 + k + j]) * wk[j];
					put(ch, y * w + x, s);
				}
			}
		}

		// ColorTransform(1, 1, 1, 1, -2, -2, -2, 0) on the colours without premultiplied alpha, bounds of what is left
		var tx0 = w, tx1 = 0, ty0 = h, ty1 = 0;
		for (y in ny0...ny1) {
			for (x in nx0...nx1) {
				var i = y * w + x;
				var al = a[i];
				if (al == 0) {
					r[i] = 0;
					g[i] = 0;
					a[i] = 0;
					continue;
				}
				put(r, i, Math.max(0, r[i] * 255 / al - 2) * al / 255);
				put(g, i, Math.max(0, g[i] * 255 / al - 2) * al / 255);
				if (x < tx0)
					tx0 = x;
				if (x >= tx1)
					tx1 = x + 1;
				if (y < ty0)
					ty0 = y;
				if (y >= ty1)
					ty1 = y + 1;
			}
		}
		finish(tx0, tx1, ty0, ty1, scroll);
	}

	// blur over 3 pixels (weights c, s, c... centre `c`, sides `s`) of the region widened by one pixel, then like `process`
	function blur3(c:Float, s:Float, nx0:Int, nx1:Int, ny0:Int, ny1:Int, scroll:Int) {
		// horizontally, in place, on the rows of the region (outside it everything is 0)
		for (y in y0...y1) {
			var row = y * w;
			var pr = 0.0, pg = 0.0, pa = 0.0;
			var i = row + nx0;
			var cr:Float = r[i], cg:Float = g[i], ca:Float = a[i];
			for (x in nx0...nx1) {
				var nr = 0.0, ng = 0.0, na = 0.0;
				if (x + 1 < w) {
					nr = r[i + 1];
					ng = g[i + 1];
					na = a[i + 1];
				}
				put(r, i, cr * c + (pr + nr) * s);
				put(g, i, cg * c + (pg + ng) * s);
				put(a, i, ca * c + (pa + na) * s);
				pr = cr;
				pg = cg;
				pa = ca;
				cr = nr;
				cg = ng;
				ca = na;
				i++;
			}
		}
		// vertically on the columns, with the ColorTransform and the bounds of what is left
		var tx0 = w, tx1 = 0, ty0 = h, ty1 = 0;
		for (x in nx0...nx1) {
			var pr = 0.0, pg = 0.0, pa = 0.0;
			var i = ny0 * w + x;
			var cr:Float = r[i], cg:Float = g[i], ca:Float = a[i];
			for (y in ny0...ny1) {
				var nr = 0.0, ng = 0.0, na = 0.0;
				if (y + 1 < h) {
					nr = r[i + w];
					ng = g[i + w];
					na = a[i + w];
				}
				// blurred (8 bits), then the ColorTransform
				var al = Math.round(ca * c + (pa + na) * s);
				if (al == 0) {
					r[i] = 0;
					g[i] = 0;
					a[i] = 0;
				} else {
					var k = 255 / al;
					put(r, i, Math.max(0, Math.round(cr * c + (pr + nr) * s) * k - 2) / k);
					put(g, i, Math.max(0, Math.round(cg * c + (pg + ng) * s) * k - 2) / k);
					put(a, i, al);
					if (x < tx0)
						tx0 = x;
					tx1 = x + 1;
					if (y < ty0)
						ty0 = y;
					if (y >= ty1)
						ty1 = y + 1;
				}
				pr = cr;
				pg = cg;
				pa = ca;
				cr = nr;
				cg = ng;
				ca = na;
				i += w;
			}
		}
		finish(tx0, tx1, ty0, ty1, scroll);
	}

	// BitmapData.scroll(0, scroll) of what is left in [tx0, tx1[ x [ty0, ty1[: rows move down, the rows uncovered at the
	// top of the bitmap are left as they are
	function finish(tx0:Int, tx1:Int, ty0:Int, ty1:Int, scroll:Int) {
		if (tx1 <= tx0) {
			x0 = x1 = y0 = y1 = 0;
			return;
		}
		var ey1 = Std.int(Math.min(h, ty1 + scroll));
		if (scroll > 0) {
			var y = ey1 - 1;
			while (y >= scroll && y >= ty0) {
				var src = y - scroll;
				for (x in tx0...tx1) {
					var i = y * w + x;
					if (src >= ty0) {
						var j = src * w + x;
						r[i] = r[j];
						g[i] = g[j];
						a[i] = a[j];
					} else {
						r[i] = 0;
						g[i] = 0;
						a[i] = 0;
					}
				}
				y--;
			}
		}
		x0 = tx0;
		x1 = tx1;
		y0 = ty0 < scroll ? ty0 : ty0 + scroll;
		y1 = ey1;
		if (y1 <= y0)
			x0 = x1 = y0 = y1 = 0;
	}

	// stores a value in a pixel of 8 bits: rounded and clamped (Uint8ClampedArray)
	static inline function put(t:Uint8ClampedArray, i:Int, v:Float) {
		js.Syntax.code("{0}[{1}] = {2}", t, i, v);
	}

	function clear() {
		for (y in y0...y1)
			for (x in x0...x1) {
				var i = y * w + x;
				r[i] = 0;
				g[i] = 0;
				a[i] = 0;
			}
		x0 = x1 = y0 = y1 = 0;
	}
}
