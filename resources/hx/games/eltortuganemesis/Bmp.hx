package eltortuganemesis;

import js.lib.Int32Array;
import js.lib.Uint8Array;
import pixi.core.textures.Texture;

// flash.display.BitmapData of the game logic, in memory (ARGB, signed 32 bits): the same results on every computer
// (the original reads its pixels: getPixel32, floodFill, hitTest)
class Bmp {
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var data(default, null):Int32Array;

	public function new(w:Int, h:Int, ?color:Int = 0) {
		width = w;
		height = h;
		data = new Int32Array(w * h);
		if (color != 0)
			data.fill(color);
	}

	public inline function get(x:Int, y:Int):Int {
		return (x < 0 || y < 0 || x >= width || y >= height) ? 0 : data[y * width + x];
	}

	public inline function set(x:Int, y:Int, c:Int) {
		if (x >= 0 && y >= 0 && x < width && y < height)
			data[y * width + x] = c;
	}

	public function fill(c:Int) {
		data.fill(c);
	}

	public function fillRect(x:Int, y:Int, w:Int, h:Int, c:Int) {
		var x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
		var x1 = x + w > width ? width : x + w, y1 = y + h > height ? height : y + h;
		for (yy in y0...y1) {
			var o = yy * width;
			for (xx in x0...x1)
				data[o + xx] = c;
		}
	}

	public function clone():Bmp {
		var b = new Bmp(width, height);
		b.data.set(data);
		return b;
	}

	// copyPixels(src, rect, 0, mergeAlpha): the opaque pixels of src (the others are fully transparent)
	public function mergeOpaque(src:Bmp) {
		var s = src.data;
		for (i in 0...data.length) {
			var c = s[i];
			if ((c >>> 24) == 255)
				data[i] = c;
		}
	}

	// floodFill: the 4-connected area of the colour of (x, y)
	public function floodFill(x:Int, y:Int, c:Int) {
		if (x < 0 || y < 0 || x >= width || y >= height)
			return;
		var w = width;
		var target = data[y * w + x];
		if (target == c)
			return;
		var stack = [x, y];
		while (stack.length > 0) {
			var sy = stack.pop();
			var sx = stack.pop();
			var o = sy * w;
			if (data[o + sx] != target)
				continue;
			var lx = sx;
			while (lx > 0 && data[o + lx - 1] == target)
				lx--;
			var rx = sx;
			while (rx < w - 1 && data[o + rx + 1] == target)
				rx++;
			var upOn = false, downOn = false;
			for (xx in lx...rx + 1) {
				data[o + xx] = c;
				if (sy > 0) {
					var t = data[o - w + xx] == target;
					if (t && !upOn) {
						stack.push(xx);
						stack.push(sy - 1);
					}
					upOn = t;
				}
				if (sy < height - 1) {
					var t = data[o + w + xx] == target;
					if (t && !downOn) {
						stack.push(xx);
						stack.push(sy + 1);
					}
					downOn = t;
				}
			}
		}
	}
}

// a transparent RGBA bitmap with partial alpha (lazers): non premultiplied 0-255
class ABmp {
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var rgba(default, null):Uint8Array;

	public function new(w:Int, h:Int) {
		width = w;
		height = h;
		rgba = new Uint8Array(w * h * 4);
	}

	public function clear() {
		rgba.fill(0);
	}

	public inline function alpha(x:Int, y:Int):Int {
		return (x < 0 || y < 0 || x >= width || y >= height) ? 0 : rgba[(y * width + x) * 4 + 3];
	}

	// applyFilter(src, ColorMatrixFilter alpha -20) into this bitmap
	public function fadeFrom(src:ABmp, dec:Int) {
		var s = src.rgba, d = rgba;
		var i = 0;
		var n = d.length;
		while (i < n) {
			var a = s[i + 3] - dec;
			if (a <= 0) {
				d[i] = d[i + 1] = d[i + 2] = d[i + 3] = 0;
			} else {
				d[i] = s[i];
				d[i + 1] = s[i + 1];
				d[i + 2] = s[i + 2];
				d[i + 3] = a;
			}
			i += 4;
		}
	}

	// a pixel of colour col and coverage cov (0-1) drawn over
	public inline function blend(x:Int, y:Int, col:Int, cov:Float) {
		if (x >= 0 && y >= 0 && x < width && y < height && cov > 0) {
			var i = (y * width + x) * 4;
			var sa = cov;
			var da = rgba[i + 3] / 255;
			var oa = sa + da * (1 - sa);
			var r = (col >> 16) & 255, g = (col >> 8) & 255, b = col & 255;
			if (oa > 0) {
				rgba[i] = Std.int((r * sa + rgba[i] * da * (1 - sa)) / oa + 0.5);
				rgba[i + 1] = Std.int((g * sa + rgba[i + 1] * da * (1 - sa)) / oa + 0.5);
				rgba[i + 2] = Std.int((b * sa + rgba[i + 2] * da * (1 - sa)) / oa + 0.5);
			}
			rgba[i + 3] = Std.int(oa * 255 + 0.5);
		}
	}
}

// a texture updated from memory (premultiplied RGBA), shown with the nearest pixel (the bitmaps of the original are
// shown at 1 px per Flash pixel)
class BufTex {
	public var tex(default, null):Texture;
	public var buf(default, null):Uint8Array;

	var w:Int;
	var h:Int;

	public function new(w:Int, h:Int, ?smooth:Bool = false) {
		this.w = w;
		this.h = h;
		buf = new Uint8Array(w * h * 4);
		var P:Dynamic = untyped PIXI;
		tex = P.Texture.fromBuffer(buf, w, h, {scaleMode: smooth ? P.SCALE_MODES.LINEAR : P.SCALE_MODES.NEAREST, alphaMode: P.ALPHA_MODES.PMA});
	}

	public function upload() {
		var bt:Dynamic = tex.baseTexture;
		if (bt.resource != null)
			bt.resource.update();
		else
			bt.update();
	}

	public function clear() {
		buf.fill(0);
	}

	public inline function setPx(i:Int, r:Int, g:Int, b:Int, a:Int) {
		var j = i * 4;
		buf[j] = Std.int(r * a / 255);
		buf[j + 1] = Std.int(g * a / 255);
		buf[j + 2] = Std.int(b * a / 255);
		buf[j + 3] = a;
	}

	// from a non premultiplied RGBA bitmap
	public function fromABmp(src:ABmp) {
		var s = src.rgba;
		var i = 0, n = s.length;
		while (i < n) {
			var a = s[i + 3];
			buf[i] = Std.int(s[i] * a / 255);
			buf[i + 1] = Std.int(s[i + 1] * a / 255);
			buf[i + 2] = Std.int(s[i + 2] * a / 255);
			buf[i + 3] = a;
			i += 4;
		}
		upload();
	}
}
