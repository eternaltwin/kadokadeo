package cyclopean;

import js.lib.Uint8Array;
import js.lib.Int32Array;
import pixi.core.textures.Texture;

typedef Anchor = {
	x:Float,
	y:Float,
	rot:Float,
	// matrix a b c d of the anchor in the piece
	m:Array<Float>
}

typedef Piece = {
	// bounds of the shape: xmin, xmax, ymin, ymax
	r:Array<Float>,
	// fill paths (each even-odd, united), contours as flat x, y lists in px
	paths:Array<Array<Array<Float>>>,
	// the anchors Std.getVar finds ($a0, $a1... until one is missing)
	anchors:Array<Anchor>,
	// every anchor child (getBounds and hitTest see them, visible or not)
	all:Array<Anchor>
}

// a matrix of the Flash player: x' = a x + c y + tx, y' = b x + d y + ty
typedef Mat = {
	a:Float,
	b:Float,
	c:Float,
	d:Float,
	tx:Float,
	ty:Float
}

/**
 * The level bitmap of the original (Game.lvl, a 1600 x 1600 BitmapData filled with opaque white) for the gameplay:
 * only its alpha channel, read by the collisions (Game.isFree: alpha <= TOLERANCE is a hole) and written by the
 * pieces Game.tryBranche draws with the ERASE blend mode. The Flash player rasterized them with its anti-aliasing;
 * here the same polygons (the shapes of the SWF, Data.PIECES) are sampled 4 x 4 times per pixel, like Flash's high
 * quality, with exact integer counts: the same bitmap in every browser. The bitmap shown (the texture of mcText
 * under this alpha) is built from it once the level is done (texture).
 */
class Level {
	public static inline var SIDE = Cs.LEVEL_SIDE;
	static inline var SUB = 4;

	public static var first:Piece;
	public static var bases:Array<Piece>;
	static var anchorShape:Piece;

	public var alpha:Uint8Array;

	var cnt:Int32Array;
	var mark:Int32Array;
	var stamp:Int = 0;

	public function new() {
		parse();
		alpha = new Uint8Array(SIDE * SIDE);
		alpha.fill(255);
		cnt = new Int32Array(SIDE);
		mark = new Int32Array(SIDE * SUB);
	}

	static function parse():Void {
		if (first != null)
			return;
		var d:Dynamic = haxe.Json.parse(Data.PIECES);
		first = piece(d.first);
		bases = [for (b in (d.bases : Array<Dynamic>)) piece(b)];
		anchorShape = piece(d.anchor);
	}

	static function piece(o:Dynamic):Piece {
		var paths = [];
		for (path in (o.p : Array<Array<Array<Int>>>)) {
			var cs = [];
			for (c in path) {
				var out = [];
				var x = 0, y = 0;
				var i = 0;
				while (i < c.length) {
					x += c[i];
					y += c[i + 1];
					out.push(x / 64);
					out.push(y / 64);
					i += 2;
				}
				cs.push(out);
			}
			paths.push(cs);
		}
		function anchors(l:Array<Array<Float>>):Array<Anchor> {
			return l == null ? [] : [for (a in l) {x: a[0], y: a[1], rot: a[2], m: [a[3], a[4], a[5], a[6]]}];
		}
		var al = anchors(o.a);
		return {r: o.r, paths: paths, anchors: al, all: al.concat(anchors(o.o))};
	}

	// ---------------------------------------------------------------- the bitmap
	// lvl.getPixel32(int(x), int(y)) alpha: 0 outside the bitmap
	public inline function getAlpha(x:Float, y:Float):Int {
		var ix = Std.int(x);
		var iy = Std.int(y);
		return (ix < 0 || iy < 0 || ix >= SIDE || iy >= SIDE) ? 0 : alpha[iy * SIDE + ix];
	}

	// Cs.drawMC(lvl, mc) with mc.blendMode = ERASE: the alpha of the bitmap times 1 - the alpha of the piece
	public function erase(p:Piece, m:Mat):Void {
		// the edges in bitmap pixels, per path
		var paths = [];
		var minX = Math.POSITIVE_INFINITY, maxX = Math.NEGATIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY;
		for (path in p.paths) {
			var e = [];
			for (c in path) {
				var n = c.length >> 1;
				for (i in 0...n) {
					var j = (i + 1) % n;
					var x0 = m.a * c[i * 2] + m.c * c[i * 2 + 1] + m.tx;
					var y0 = m.b * c[i * 2] + m.d * c[i * 2 + 1] + m.ty;
					var x1 = m.a * c[j * 2] + m.c * c[j * 2 + 1] + m.tx;
					var y1 = m.b * c[j * 2] + m.d * c[j * 2 + 1] + m.ty;
					if (y0 == y1)
						continue;
					e.push(x0);
					e.push(y0);
					e.push(x1);
					e.push(y1);
					minX = Math.min(minX, Math.min(x0, x1));
					maxX = Math.max(maxX, Math.max(x0, x1));
					minY = Math.min(minY, Math.min(y0, y1));
					maxY = Math.max(maxY, Math.max(y0, y1));
				}
			}
			paths.push(e);
		}
		if (!(minX <= maxX))
			return;
		var px0 = Std.int(Math.max(0, Math.floor(minX)));
		var px1 = Std.int(Math.min(SIDE, Math.ceil(maxX) + 1));
		var py0 = Std.int(Math.max(0, Math.floor(minY)));
		var py1 = Std.int(Math.min(SIDE, Math.ceil(maxY) + 1));
		if (px0 >= px1 || py0 >= py1)
			return;
		var w = px1 - px0;
		var cols = w * SUB;
		var xs:Array<Float> = [];
		for (y in py0...py1) {
			for (i in 0...w)
				cnt[i] = 0;
			for (j in 0...SUB) {
				var sy = y + (j + 0.5) / SUB;
				// a sample covered by several paths counts once (the paths are united)
				stamp++;
				for (e in paths) {
					xs.resize(0);
					var k = 0;
					while (k < e.length) {
						var y0 = e[k + 1];
						var y1 = e[k + 3];
						if ((y0 <= sy) != (y1 <= sy))
							xs.push(e[k] + (sy - y0) * (e[k + 2] - e[k]) / (y1 - y0));
						k += 4;
					}
					sortFloats(xs);
					var s = 0;
					while (s + 1 < xs.length) {
						// sample columns c of this row: x = px0 + (c + 0.5) / SUB, inside [xa, xb)
						var c0 = Math.ceil((xs[s] - px0) * SUB - 0.5);
						var c1 = Math.ceil((xs[s + 1] - px0) * SUB - 0.5);
						if (c0 < 0)
							c0 = 0;
						if (c1 > cols)
							c1 = cols;
						for (c in c0...c1) {
							if (mark[c] != stamp) {
								mark[c] = stamp;
								cnt[c >> 2]++;
							}
						}
						s += 2;
					}
				}
			}
			var row = y * SIDE + px0;
			for (i in 0...w) {
				var n = cnt[i];
				if (n == 0)
					continue;
				var src = Std.int((n * 255 + 8) / 16);
				var a = alpha[row + i];
				alpha[row + i] = Std.int((a * (255 - src) + 127) / 255);
			}
		}
	}

	static function sortFloats(a:Array<Float>):Void {
		for (i in 1...a.length) {
			var v = a[i];
			var j = i - 1;
			while (j >= 0 && a[j] > v) {
				a[j + 1] = a[j];
				j--;
			}
			a[j + 1] = v;
		}
	}

	// ---------------------------------------------------------------- the piece as a MovieClip
	// mc.hitTest(x, y, true) (the clip in the map, at the origin of the stage while the level is made): the shape or
	// one of the anchors (hidden clips still count) under the point
	public static function hitTest(p:Piece, m:Mat, x:Float, y:Float):Bool {
		if (inside(p, m, x, y))
			return true;
		for (an in p.all)
			if (inside(anchorShape, mul(m, an), x, y))
				return true;
		return false;
	}

	static function inside(p:Piece, m:Mat, x:Float, y:Float):Bool {
		var det = m.a * m.d - m.b * m.c;
		var dx = x - m.tx;
		var dy = y - m.ty;
		var lx = (m.d * dx - m.c * dy) / det;
		var ly = (-m.b * dx + m.a * dy) / det;
		var r = p.r;
		if (!(lx >= r[0] && lx <= r[1] && ly >= r[2] && ly <= r[3]))
			return false;
		for (path in p.paths) {
			var odd = false;
			for (c in path) {
				var n = c.length >> 1;
				var j = n - 1;
				for (i in 0...n) {
					var xi = c[i * 2], yi = c[i * 2 + 1];
					var xj = c[j * 2], yj = c[j * 2 + 1];
					if ((yi > ly) != (yj > ly) && lx < xj + (ly - yj) * (xi - xj) / (yi - yj))
						odd = !odd;
					j = i;
				}
			}
			if (odd)
				return true;
		}
		return false;
	}

	// mc.getBounds(map): the bounds of each child (its shape's rectangle through its matrix), united, in twips
	public static function getBounds(p:Piece, m:Mat):{xMin:Float, xMax:Float, yMin:Float, yMax:Float} {
		var b = {xMin: Math.POSITIVE_INFINITY, xMax: Math.NEGATIVE_INFINITY, yMin: Math.POSITIVE_INFINITY, yMax: Math.NEGATIVE_INFINITY};
		function add(r:Array<Float>, m:Mat) {
			for (k in 0...4) {
				var x = r[k & 1];
				var y = r[2 + (k >> 1)];
				var gx = m.a * x + m.c * y + m.tx;
				var gy = m.b * x + m.d * y + m.ty;
				b.xMin = Math.min(b.xMin, gx);
				b.xMax = Math.max(b.xMax, gx);
				b.yMin = Math.min(b.yMin, gy);
				b.yMax = Math.max(b.yMax, gy);
			}
		}
		add(p.r, m);
		for (an in p.all)
			add(anchorShape.r, mul(m, an));
		b.xMin = Math.floor(b.xMin * 20) / 20;
		b.yMin = Math.floor(b.yMin * 20) / 20;
		b.xMax = Math.ceil(b.xMax * 20) / 20;
		b.yMax = Math.ceil(b.yMax * 20) / 20;
		return b;
	}

	// the matrix of an anchor in the map
	static function mul(m:Mat, an:Anchor):Mat {
		var a = an.m;
		return {
			a: m.a * a[0] + m.c * a[1],
			b: m.b * a[0] + m.d * a[1],
			c: m.a * a[2] + m.c * a[3],
			d: m.b * a[2] + m.d * a[3],
			tx: m.a * an.x + m.c * an.y + m.tx,
			ty: m.b * an.x + m.d * an.y + m.ty
		};
	}

	// Tools.localToGlobal(mc, x, y): the point in twips
	public static function localToGlobal(m:Mat, x:Float, y:Float):{x:Float, y:Float} {
		return {
			x: Math.round((m.a * x + m.c * y + m.tx) * 20) / 20,
			y: Math.round((m.b * x + m.d * y + m.ty) * 20) / 20
		};
	}

	// ---------------------------------------------------------------- pictures
	// Cs.texturize(bmp, link, 128): the 128 x 128 texture of the clip tiled from (0, 0) under the alpha of bmp
	// (the clip is opaque: the alpha stays the one of bmp); alpha null: opaque
	static function texturize(w:Int, h:Int, tile:String, alpha:Uint8Array):js.html.CanvasElement {
		var t = new js.lib.Uint32Array(tilePixels(tile).buffer);
		var cv = js.Browser.document.createCanvasElement();
		cv.width = w;
		cv.height = h;
		var ctx = cv.getContext2d();
		var img = ctx.createImageData(w, h);
		// RGBA bytes as little-endian words: alpha in the high byte
		var d = new js.lib.Uint32Array(img.data.buffer);
		var o = 0;
		for (y in 0...h) {
			var ty = (y & 127) * 128;
			for (x in 0...w) {
				var c = t[ty + (x & 127)] & 0xFFFFFF;
				d[o] = alpha == null ? c | 0xFF000000 : c | (alpha[o] << 24);
				o++;
			}
		}
		ctx.putImageData(img, 0, 0);
		return cv;
	}

	// the pixels of a 128 x 128 texture of the sheet (read once, in Game.new: decoding the sheet picture for the CPU
	// takes long; the GPU reads them back in a few ms, the pictures only)
	static var tiles:Map<String, js.lib.Uint8Array> = new Map();

	public static function readTiles():Void {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		for (name in ["tileText", "tileBg"]) {
			if (tiles.exists(name))
				continue;
			var s = new pixi.core.sprites.Sprite(Tex.get(name)[0]);
			s.anchor.set(0, 0);
			var rt:Dynamic = (cast pixi.core.textures.RenderTexture : Dynamic).create({width: 128, height: 128, resolution: 1});
			renderer.render(s, {renderTexture: rt, clear: true});
			tiles.set(name, renderer.extract.pixels(rt));
			rt.destroy(true);
			s.destroy();
		}
	}

	static function tilePixels(name:String):js.lib.Uint8Array {
		readTiles();
		return tiles.get(name);
	}

	// the level shown: mcText under the alpha of the level
	public function texture():Texture {
		return Texture.from(texturize(SIDE, SIDE, "tileText", alpha));
	}

	// the minimap (the level at 10 %, white, see Game.initMiniMap): 2 pixels per Flash pixel, each the mean alpha
	// of the 5 x 5 level pixels it covers (Flash sampled one of them: a picture that sparkles while it turns)
	public function miniTexture():Texture {
		var n = Std.int(SIDE / 5);
		var cv = js.Browser.document.createCanvasElement();
		cv.width = n;
		cv.height = n;
		var ctx = cv.getContext2d();
		var img = ctx.createImageData(n, n);
		var d = img.data;
		for (y in 0...n)
			for (x in 0...n) {
				var s = 0;
				for (j in 0...5)
					for (i in 0...5)
						s += alpha[(y * 5 + j) * SIDE + x * 5 + i];
				var o = (y * n + x) * 4;
				d[o] = d[o + 1] = d[o + 2] = 255;
				d[o + 3] = Math.round(s / 25);
			}
		ctx.putImageData(img, 0, 0);
		return Texture.from(cv);
	}

	// the background: Cs.texturize of an opaque 640 x 640 bitmap with mcBgText
	public static function bgTexture(side:Int):Texture {
		return Texture.from(texturize(side, side, "tileBg", null));
	}
}
