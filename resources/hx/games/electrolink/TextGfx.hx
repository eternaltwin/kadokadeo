package electrolink;

import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.lib.Float32Array;
import pixi.core.textures.Texture;

// premultiplied RGBA picture at 2 pixels per Flash pixel; (x0, y0): its top left corner in Flash pixels
typedef Rgba = {
	x0:Float,
	y0:Float,
	w:Int,
	h:Int,
	r:Float32Array,
	g:Float32Array,
	b:Float32Array,
	a:Float32Array
};

// The texts of the scoring popup, drawn like the Flash player: the glyphs of the TexasLED font embedded in the SWF
// (pictures of the sheet) laid out like a text field (2 px gutter, first baseline at the ascent, right or left
// aligned), then the filters of the field (GlowFilter, DropShadowFilter: box blurs repeated `passes` times, strength,
// clamping), the "PTS" text (baked with its filters) and the second field over them; the BlurFilter of _t blurs the
// whole picture. Only for the eye: nothing here touches the game.
class TextGfx {
	static inline var K = 2;
	// room for the filters around the fields (Flash pixels)
	static inline var MARGIN = 14.0;

	static var canvas:CanvasElement;
	static var ctx:CanvasRenderingContext2D;

	static function context(w:Int, h:Int):CanvasRenderingContext2D {
		if (canvas == null) {
			canvas = Browser.document.createCanvasElement();
			// (read back often: kept on the CPU)
			ctx = cast canvas.getContext("2d", {willReadFrequently: true});
		}
		if (canvas.width < w || canvas.height < h) {
			canvas.width = Std.int(Math.max(canvas.width, w));
			canvas.height = Std.int(Math.max(canvas.height, h));
		}
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		return ctx;
	}

	static function empty(x0:Float, y0:Float, w:Int, h:Int):Rgba {
		return {
			x0: x0,
			y0: y0,
			w: w,
			h: h,
			r: new Float32Array(w * h),
			g: new Float32Array(w * h),
			b: new Float32Array(w * h),
			a: new Float32Array(w * h)
		};
	}

	// a picture of the sheet drawn at (x, y) pixels of the canvas, its pivot there
	static function drawTex(c:CanvasRenderingContext2D, t:Texture, x:Float, y:Float):Void {
		var src:Dynamic = untyped t.baseTexture.resource.source;
		var fr = t.frame;
		var ox = x - t.defaultAnchor.x * t.orig.width;
		var oy = y - t.defaultAnchor.y * t.orig.height;
		if (t.trim != null) {
			ox += t.trim.x;
			oy += t.trim.y;
		}
		c.drawImage(src, fr.x, fr.y, fr.width, fr.height, Math.round(ox), Math.round(oy), fr.width, fr.height);
	}

	static function readAlpha(c:CanvasRenderingContext2D, w:Int, h:Int):Float32Array {
		var d = c.getImageData(0, 0, w, h).data;
		var a = new Float32Array(w * h);
		for (i in 0...w * h)
			a[i] = d[i * 4 + 3] / 255;
		return a;
	}

	// a text field: glyph alpha, its colour, then its GlowFilter and DropShadowFilter (on the field and the room of
	// its filters only)
	static function field(f:{x:Float, y:Float, w:Float, right:Bool, color:Int}, text:String):Rgba {
		var x0 = Math.floor((f.x - MARGIN) * K) / K;
		var y0 = Math.floor((f.y - MARGIN) * K) / K;
		var w = Math.ceil((f.w + 2 * MARGIN) * K);
		var h = Math.ceil((Data.GLYPH_ASCENT + 14 + 2 * MARGIN) * K);
		var c = context(w, h);
		var glyphs = Tex.get("glyph");
		var width = 0.0;
		for (i in 0...text.length)
			width += Data.GLYPH_ADV[Data.GLYPHS.indexOf(text.charAt(i))];
		var pen = f.right ? f.x + f.w - 2 - width : f.x + 2;
		var base = Math.round((f.y + 2 + Data.GLYPH_ASCENT - y0) * K);
		for (i in 0...text.length) {
			var g = Data.GLYPHS.indexOf(text.charAt(i));
			if (g < 0)
				continue;
			drawTex(c, glyphs[g], Math.round((pen - x0) * K), base);
			pen += Data.GLYPH_ADV[g];
		}
		var a = readAlpha(c, w, h);
		var l = empty(x0, y0, w, h);
		var col = rgb(f.color);
		for (i in 0...w * h) {
			l.r[i] = col[0] * a[i];
			l.g[i] = col[1] * a[i];
			l.b[i] = col[2] * a[i];
			l.a[i] = a[i];
		}
		outerGlow(l, Data.FIELD_GLOW);
		outerGlow(l, Data.FIELD_SHADOW);
		return l;
	}

	static function rgb(c:Int):Array<Float> {
		return [((c >> 16) & 255) / 255, ((c >> 8) & 255) / 255, (c & 255) / 255];
	}

	// GlowFilter / DropShadowFilter at distance 0 (outer, not knocked out): the glow drawn under the picture
	static function outerGlow(l:Rgba, f:{blur:Float, strength:Float, passes:Int, color:Int}):Void {
		var n = l.w * l.h;
		var g = new Float32Array(n);
		for (i in 0...n)
			g[i] = l.a[i];
		g = boxBlur(g, l.w, l.h, f.blur * K, f.blur * K, f.passes);
		var col = rgb(f.color);
		for (i in 0...n) {
			var v = g[i] * f.strength;
			v = v > 1 ? 1 : v;
			var k = v * (1 - l.a[i]);
			l.r[i] += col[0] * k;
			l.g[i] += col[1] * k;
			l.b[i] += col[2] * k;
			l.a[i] += k;
		}
	}

	// Flash-like box blur (swfrender.box_blur): widths rx, ry in pixels, `passes` times
	public static function boxBlur(src:Float32Array, w:Int, h:Int, rx:Float, ry:Float, passes:Int):Float32Array {
		var out = src;
		for (p in 0...(passes < 1 ? 1 : passes)) {
			var bw = Math.round(rx);
			if (bw >= 2)
				out = blurAxis(out, w, h, bw, true);
			var bh = Math.round(ry);
			if (bh >= 2)
				out = blurAxis(out, w, h, bh, false);
		}
		return out;
	}

	// out[i] = sum(in[i - lo .. i + hi - 1]) / bw, lo = bw / 2, hi = bw - lo (zero outside)
	static function blurAxis(src:Float32Array, w:Int, h:Int, bw:Int, horizontal:Bool):Float32Array {
		var out = new Float32Array(w * h);
		var lo = bw >> 1;
		var hi = bw - lo;
		var n = horizontal ? w : h;
		var lines = horizontal ? h : w;
		var step = horizontal ? 1 : w;
		for (l in 0...lines) {
			var start = horizontal ? l * w : l;
			var sum = 0.0;
			// window of index 0: [-lo, hi - 1]
			for (j in 0...hi)
				if (j < n)
					sum += src[start + j * step];
			for (i in 0...n) {
				out[start + i * step] = sum / bw;
				var add = i + hi;
				var rem = i - lo;
				if (add < n)
					sum += src[start + add * step];
				if (rem >= 0)
					sum -= src[start + rem * step];
			}
		}
		return out;
	}

	// src drawn over dst (src inside dst, both on the same pixel grid)
	static function over(dst:Rgba, src:Rgba):Void {
		var ox = Math.round((src.x0 - dst.x0) * K);
		var oy = Math.round((src.y0 - dst.y0) * K);
		for (y in 0...src.h) {
			var dy = y + oy;
			if (dy < 0 || dy >= dst.h)
				continue;
			for (x in 0...src.w) {
				var dx = x + ox;
				if (dx < 0 || dx >= dst.w)
					continue;
				var i = y * src.w + x;
				var j = dy * dst.w + dx;
				var k = 1 - src.a[i];
				dst.r[j] = src.r[i] + dst.r[j] * k;
				dst.g[j] = src.g[i] + dst.g[j] * k;
				dst.b[j] = src.b[i] + dst.b[j] * k;
				dst.a[j] = src.a[i] + dst.a[j] * k;
			}
		}
	}

	// once at the start of a game: the first composition (canvas, compiled code) is much slower than the next ones
	public static function warm():Void {
		compose("0", "x0");
	}

	// the area of _t drawn (Flash pixels): the fields and the room of their filters
	static function area():{x0:Float, y0:Float, w:Int, h:Int} {
		var p = Data.FIELD_PTS;
		var m = Data.FIELD_MULT;
		var x0 = Math.floor((p.x - MARGIN) * K) / K;
		var y0 = Math.floor((p.y - MARGIN) * K) / K;
		var x1 = m.x + m.w + MARGIN;
		var y1 = p.y + Data.GLYPH_ASCENT + 14 + MARGIN;
		return {x0: x0, y0: y0, w: Math.ceil((x1 - x0) * K), h: Math.ceil((y1 - y0) * K)};
	}

	// top left corner of the picture of _t for a blur (hblur widens it)
	public static function origin(blurX:Float):{x:Float, y:Float} {
		var a = area();
		var bw = Math.round(blurX * K);
		return {x: a.x0 - (bw < 2 ? 0 : bw) / K, y: a.y0};
	}

	// _t without its BlurFilter: _pts (depth 1), "PTS" (2), _mult (3)
	public static function compose(pts:String, mult:String):Rgba {
		var ar = area();
		var x0 = ar.x0;
		var y0 = ar.y0;
		var w = ar.w;
		var h = ar.h;
		var p = Data.FIELD_PTS;
		var m = Data.FIELD_MULT;
		var out = empty(x0, y0, w, h);
		over(out, field(p, pts));
		var c = context(w, h);
		drawTex(c, Tex.get("ptsLabel")[0], -x0 * K, -y0 * K);
		var d = c.getImageData(0, 0, w, h).data;
		var l = empty(x0, y0, w, h);
		for (i in 0...w * h) {
			var a = d[i * 4 + 3] / 255;
			l.r[i] = d[i * 4] / 255 * a;
			l.g[i] = d[i * 4 + 1] / 255 * a;
			l.b[i] = d[i * 4 + 2] / 255 * a;
			l.a[i] = a;
		}
		over(out, l);
		over(out, field(m, mult));
		return out;
	}

	// BlurFilter(blurX, 0) (quality 1) of _t, on a picture widened by the spread
	public static function hblur(src:Rgba, blurX:Float):Rgba {
		var bw = Math.round(blurX * K);
		if (bw < 2)
			return src;
		var pad = bw;
		var w = src.w + 2 * pad;
		var h = src.h;
		var out = empty(src.x0 - pad / K, src.y0, w, h);
		for (y in 0...h)
			for (x in 0...src.w) {
				var i = y * src.w + x;
				var j = y * w + x + pad;
				out.r[j] = src.r[i];
				out.g[j] = src.g[i];
				out.b[j] = src.b[i];
				out.a[j] = src.a[i];
			}
		out.r = boxBlur(out.r, w, h, bw, 0, 1);
		out.g = boxBlur(out.g, w, h, bw, 0, 1);
		out.b = boxBlur(out.b, w, h, bw, 0, 1);
		out.a = boxBlur(out.a, w, h, bw, 0, 1);
		return out;
	}

	public static function texture(src:Rgba):Texture {
		return Texture.from(canvasOf(src));
	}

	public static function canvasOf(src:Rgba):CanvasElement {
		var cv = Browser.document.createCanvasElement();
		cv.width = src.w;
		cv.height = src.h;
		var c = cv.getContext2d();
		var img = c.createImageData(src.w, src.h);
		var d = img.data;
		for (i in 0...src.w * src.h) {
			var a = src.a[i];
			if (a <= 0)
				continue;
			var k = 255 / (a > 1 ? 1 : a);
			d[i * 4] = Math.round(src.r[i] * k);
			d[i * 4 + 1] = Math.round(src.g[i] * k);
			d[i * 4 + 2] = Math.round(src.b[i] * k);
			d[i * 4 + 3] = Math.round(a * 255);
		}
		c.putImageData(img, 0, 0);
		return cv;
	}
}
