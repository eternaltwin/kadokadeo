package hexile;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

/**
 * The `bg` BitmapData of the original (300 x 300, attached at DP_BG), drawn once by Game.terraforming:
 *   - filled with the sea colour;
 *   - bg.draw(ground) with Filt.glow(ground, 100, 16, 0x5188BF) on the ground: the light blue around the island;
 *   - brushSeaside drawn with the blend mode "lighten" on every side of a hex facing the sea (the foam).
 * Composed here on a canvas (x2: 2 pixels per Flash pixel, like every picture of the port) from the pictures of the
 * sheet, then shown as one texture. A picture only: nothing of the game reads it.
 */
class SeaBitmap {
	var canvas:CanvasElement;
	var ctx:CanvasRenderingContext2D;
	var texture:Texture;

	public var sprite(default, null):PixiSprite;

	public function new(col:Int) {
		canvas = js.Browser.document.createCanvasElement();
		canvas.width = Cs.mcw * Game.K;
		canvas.height = Cs.mch * Game.K;
		ctx = canvas.getContext2d();
		ctx.fillStyle = css(col);
		ctx.fillRect(0, 0, canvas.width, canvas.height);
	}

	static function css(col:Int):String {
		return "#" + StringTools.hex(col, 6);
	}

	// a picture of the sheet with its pivot at (x, y) Flash pixels
	static function drawPicture(c:CanvasRenderingContext2D, anim:String, frame:Int, x:Float, y:Float) {
		var t = Tex.get(anim)[frame - 1];
		var src:Dynamic = untyped t.baseTexture.resource.source;
		var fr = t.frame;
		var ox = t.trim != null ? t.trim.x : 0;
		var oy = t.trim != null ? t.trim.y : 0;
		var dx = x * Game.K - t.defaultAnchor.x * t.orig.width + ox;
		var dy = y * Game.K - t.defaultAnchor.y * t.orig.height + oy;
		c.drawImage(src, fr.x, fr.y, fr.width, fr.height, dx, dy, fr.width, fr.height);
	}

	// bg.draw(ground) with the GlowFilter of the ground (blur, strength, colour; quality 1: one box blur): the glow
	// under the hexes
	public function drawGround(hexes:Array<Socle>, blur:Float, strength:Float, col:Int) {
		var w = canvas.width;
		var h = canvas.height;
		var island = js.Browser.document.createCanvasElement();
		island.width = w;
		island.height = h;
		var ic = island.getContext2d();
		for (s in hexes)
			drawHex(ic, s);
		var a = ic.getImageData(0, 0, w, h).data;
		var al = new js.lib.Float32Array(w * h);
		for (i in 0...w * h)
			al[i] = a[i * 4 + 3] / 255;
		var bw = Math.round(blur * Game.K);
		boxBlur(al, w, h, bw, true);
		boxBlur(al, w, h, bw, false);
		var img = ctx.getImageData(0, 0, w, h);
		var d = img.data;
		var r = (col >> 16) & 0xFF;
		var g = (col >> 8) & 0xFF;
		var b = col & 0xFF;
		for (i in 0...w * h) {
			var k = al[i] * strength;
			if (k <= 0)
				continue;
			if (k > 1)
				k = 1;
			var j = i * 4;
			d[j] = Math.round(d[j] + (r - d[j]) * k);
			d[j + 1] = Math.round(d[j + 1] + (g - d[j + 1]) * k);
			d[j + 2] = Math.round(d[j + 2] + (b - d[j + 2]) * k);
		}
		ctx.putImageData(img, 0, 0);
		// then the ground itself, over its glow
		ctx.drawImage(island, 0, 0);
	}

	static function drawHex(c:CanvasRenderingContext2D, s:Socle) {
		var p = s.picture();
		drawPicture(c, p.anim, p.frame, s.root._x, s.root._y);
	}

	// Flash box blur of total width bw (swfrender.box_blur): out[i] = mean of in[i - bw / 2 .. i - bw / 2 + bw - 1]
	static function boxBlur(a:js.lib.Float32Array, w:Int, h:Int, bw:Int, horizontal:Bool) {
		if (bw < 2)
			return;
		var lo = bw >> 1;
		var n = horizontal ? w : h;
		var lines = horizontal ? h : w;
		var step = horizontal ? 1 : w;
		var line = new js.lib.Float32Array(n);
		for (l in 0...lines) {
			var start = horizontal ? l * w : l;
			for (i in 0...n)
				line[i] = a[start + i * step];
			var sum = 0.0;
			// window of out[0]: -lo .. bw - lo - 1
			for (k in 0...bw - lo)
				if (k < n)
					sum += line[k];
			for (i in 0...n) {
				a[start + i * step] = sum / bw;
				var add = i + bw - lo;
				var sub = i - lo;
				if (add < n)
					sum += line[add];
				if (sub >= 0)
					sum -= line[sub];
			}
		}
	}

	// bg.draw(brush, m, null, "lighten")
	public function drawBrush(anim:String, frame:Int, x:Float, y:Float) {
		ctx.globalCompositeOperation = "lighten";
		drawPicture(ctx, anim, frame, x, y);
		ctx.globalCompositeOperation = "source-over";
	}

	// the bitmap attached in its plane (x2 pixels in the Flash pixels of the plane)
	public function attachTo(plan:MC) {
		texture = Texture.from(canvas);
		sprite = new PixiSprite(texture);
		sprite.scale.set(1 / Game.K, 1 / Game.K);
		plan.spr.addChildAt(sprite, 0);
	}

	public function destroy() {
		if (sprite != null) {
			if (sprite.parent != null)
				sprite.parent.removeChild(sprite);
			sprite.destroy();
		}
		if (texture != null)
			texture.destroy(true);
		sprite = null;
		texture = null;
		canvas = null;
	}
}
