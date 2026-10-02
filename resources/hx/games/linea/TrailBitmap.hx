package linea;

import js.Browser;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.lib.Uint8ClampedArray;
import js.lib.Uint32Array;
import pixi.core.math.shapes.Rectangle;
import pixi.core.textures.BaseTexture;
import pixi.core.textures.Texture;

/**
 * The flash.display.BitmapData Dotter draws the lines in (1 pixel per Flash pixel, shown x2 without smoothing
 * like attachBitmap(plane, 0, "Never", false)). Pixels are kept on the CPU (the gameplay never reads them) and
 * uploaded once per displayed picture when they changed.
 *
 * Display: the bitmap content moves by `scroll` pixels per Flash frame while the head of the lines stays put. To
 * show it one Flash frame late like the clips (MC), the bitmap is shifted right by the part of a frame not yet
 * shown, and cut at the head, interpolated between its last two positions: without the cut the newest segment
 * would stick out ahead of the head.
 */
class TrailBitmap {
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var sprite(default, null):TrailSprite;

	var texture:Texture;
	var context:CanvasRenderingContext2D;
	var image:ImageData;
	var pixels:Uint8ClampedArray;
	var words:Uint32Array;
	var dirty = true;

	// this Flash frame: content moved by `moved` px, rightmost pixel drawn; the edge after the previous frame
	var moved = 0;
	var drawnMax = -1;
	var edge:Float;
	var prevEdge:Float;
	// sum of the moves since the last display, last shift shown
	var movedSinceShown = 0;
	var shown:Float = 0;

	public function new(width:Int, height:Int) {
		this.width = width;
		this.height = height;
		var canvas = Browser.document.createCanvasElement();
		canvas.width = width;
		canvas.height = height;
		context = canvas.getContext2d();
		image = context.createImageData(width, height);
		pixels = image.data;
		words = new Uint32Array(pixels.buffer);
		var base = BaseTexture.from(canvas);
		untyped base.scaleMode = PIXI.SCALE_MODES.NEAREST;
		texture = new Texture(base, new Rectangle(0, 0, width, height));
		sprite = new TrailSprite(this, texture);
		edge = prevEdge = width;
	}

	// ---------------------------------------------------------------- BitmapData
	// scroll(dx, 0): the uncovered columns keep their pixels, like Flash
	public function scroll(dx:Int):Void {
		moved -= dx;
		edge += dx;
		if (dx == 0 || dx <= -width || dx >= width)
			return;
		var src = dx < 0 ? -dx : 0;
		var dst = dx < 0 ? 0 : dx;
		var n = width - (dx < 0 ? -dx : dx);
		for (y in 0...height) {
			var row = y * width;
			words.copyWithin(row + dst, row + src, row + src + n);
		}
		dirty = true;
	}

	// colorTransform(rect, ct) with the same multiplier on red, green and blue and an alpha offset. Fully
	// transparent pixels stay transparent: the screenshots of the original show the background through the plane
	public function colorTransform(mult:Float, alphaOffset:Int):Void {
		// on 32-bit words (little endian: alpha in the high byte): most pixels are empty and skipped in one test
		var w = words;
		for (i in 0...w.length) {
			var c = w[i];
			if (c >>> 24 == 0)
				continue;
			var a = (c >>> 24) + alphaOffset;
			if (a > 255)
				a = 255;
			var r = Std.int((c & 0xFF) * mult);
			var g = Std.int(((c >>> 8) & 0xFF) * mult);
			var b = Std.int(((c >>> 16) & 0xFF) * mult);
			w[i] = (a << 24) | (b << 16) | (g << 8) | r;
		}
		dirty = true;
	}

	public function setPixel32(x:Int, y:Int, argb:Int):Void {
		if (x < 0 || x >= width || y < 0 || y >= height)
			return;
		var i = (y * width + x) << 2;
		pixels[i] = (argb >>> 16) & 0xFF;
		pixels[i + 1] = (argb >>> 8) & 0xFF;
		pixels[i + 2] = argb & 0xFF;
		pixels[i + 3] = argb >>> 24;
		if (x > drawnMax)
			drawnMax = x;
		dirty = true;
	}

	// ---------------------------------------------------------------- display
	public function frameStart():Void {
		prevEdge = edge;
		moved = 0;
		drawnMax = -1;
	}

	public function frameEnd():Void {
		if (drawnMax >= 0)
			edge = drawnMax + 1;
		movedSinceShown += moved;
	}

	// f: part of the last Flash frame shown (see MC)
	public function display(f:Float):Void {
		var shift = (1 - f) * moved;
		var cut = moved == 0 ? width : prevEdge + (edge - prevEdge) * f;
		sprite.setShift(shown + movedSinceShown, shift, cut);
		shown = shift;
		movedSinceShown = 0;
	}

	public function upload():Void {
		if (!dirty)
			return;
		dirty = false;
		context.putImageData(image, 0, 0);
		texture.baseTexture.update();
	}

	public function destroy():Void {
		texture.destroy(true);
	}
}

class TrailSprite extends ASprite {
	var bmp:TrailBitmap;
	var frame:Rectangle;
	var prevCut:Float;
	var cut:Float;

	public function new(bmp:TrailBitmap, texture:Texture) {
		super();
		this.bmp = bmp;
		this.texture = texture;
		frame = new Rectangle(0, 0, bmp.width, bmp.height);
		prevCut = cut = bmp.width;
		updateState();
	}

	// the content shown at the previous step was `prev` px to the right of where it is now
	public function setShift(prev:Float, cur:Float, cut:Float):Void {
		if (_prevState == null)
			updateState();
		_prevState.x = prev;
		_curState.x = cur;
		prevCut = this.cut;
		this.cut = cut;
	}

	override public function update():Void {
		_prevState.copyFrom(_curState);
	}

	override public function updateGraphics(a:Float):Void {
		super.updateGraphics(a);
		bmp.upload();
		var w = prevCut + (cut - prevCut) * a - position.x;
		w = w < 0 ? 0 : w > bmp.width ? bmp.width : w;
		if (w != frame.width) {
			frame.width = w;
			texture.frame = frame;
		}
		visible = w > 0;
	}
}
