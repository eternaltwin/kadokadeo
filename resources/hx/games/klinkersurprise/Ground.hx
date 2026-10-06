package klinkersurprise;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

/**
 * The two bitmaps of a zone (zw x zh), attached to each of the 9 tiles of the map (Game.initMap):
 *   - ground (Game.initGround): mcSquare (scale size %) drawn on every cell that is not a wall, its smc darkened by
 *     Col.setColor(smc, random colour, -20) (an offset of -20..-1 on each channel: not a tint, see FRAG) and a random
 *     frame (the marks on the tile), in the order of the original (the tile below covers the bottom of the one above).
 *     Drawn once into a texture at x2 (2 pixels per Flash pixel, like every picture of the port), in one pass: a mesh
 *     of every picture, each with the offset of its tile; a picture only (Seed.randomVfx);
 *   - spectre: the painted cells, fillRect(cell, colour with alpha 120), cleared when the cell is freed: drawn from
 *     the grid into a texture when it changed, just before the screen is drawn (Game.flushBitmaps).
 */
class Ground {
	static var program:Dynamic;

	public var texture(default, null):RenderTexture;
	public var spectre(default, null):RenderTexture;
	public var spectreDirty:Bool = true;

	var batch = new Container();
	var cells:Array<PixiSprite> = [];

	public function new(grid:Array<Array<Int>>, xmax:Int, ymax:Int, size:Int) {
		var K = Game.K;
		var w = xmax * size * K, h = ymax * size * K;
		texture = RenderTexture.create(w, h);
		spectre = RenderTexture.create(w, h);

		// the smc of mcSquare, then the frame without it, on each tile: quads of the sheet with the offset of the smc
		var smc = Tex.get("sq" + size)[0];
		var over = Tex.get("sqo" + size);
		var pos:Array<Float> = [], uv:Array<Float> = [], off:Array<Float> = [], idx:Array<Int> = [];
		function quad(t:Texture, x:Float, y:Float, r:Float, g:Float, b:Float) {
			var px = x * K + offsetX(t), py = y * K + offsetY(t);
			var fr = t.frame, bw = t.baseTexture.width, bh = t.baseTexture.height;
			var n = Std.int(pos.length / 2);
			pos.push(px); pos.push(py);
			pos.push(px + fr.width); pos.push(py);
			pos.push(px + fr.width); pos.push(py + fr.height);
			pos.push(px); pos.push(py + fr.height);
			uv.push(fr.x / bw); uv.push(fr.y / bh);
			uv.push((fr.x + fr.width) / bw); uv.push(fr.y / bh);
			uv.push((fr.x + fr.width) / bw); uv.push((fr.y + fr.height) / bh);
			uv.push(fr.x / bw); uv.push((fr.y + fr.height) / bh);
			for (i in 0...4) {
				off.push(r / 255);
				off.push(g / 255);
				off.push(b / 255);
			}
			for (i in [0, 1, 2, 0, 2, 3])
				idx.push(n + i);
		}
		for (x in 0...xmax) {
			for (y in 0...ymax) {
				if (grid[x][y] == Game.WALL)
					continue;
				// Col.setColor(mc.smc, objToCol({r: random(20), g: random(20), b: random(20)}), -20)
				var r = Seed.randomVfx(20) - 20;
				var g = Seed.randomVfx(20) - 20;
				var b = Seed.randomVfx(20) - 20;
				// mc.gotoAndStop(random(_totalframes) + 1)
				var f = Seed.randomVfx(7) + 1;
				quad(smc, x * size, y * size, r, g, b);
				quad(over[f - 1], x * size, y * size, 0, 0, 0);
			}
		}
		if (idx.length == 0)
			return;
		var P:Dynamic = untyped PIXI;
		var geometry:Dynamic = js.Syntax.construct(P.Geometry);
		geometry.addAttribute("aVertexPosition", pos, 2);
		geometry.addAttribute("aTextureCoord", uv, 2);
		geometry.addAttribute("aOffset", off, 3);
		geometry.addIndex(new js.lib.Uint16Array(idx));
		if (program == null)
			program = P.Program.from(VERT, FRAG, "kkKlinkerGround");
		var mesh:Dynamic = js.Syntax.construct(P.Mesh, geometry, js.Syntax.construct(P.Shader, program, {uSampler: smc.baseTexture}));
		KadoKadeoManager.kkm.renderer.render(mesh, cast {renderTexture: texture, clear: true});
		mesh.destroy();
		geometry.destroy();
	}

	// from the origin of its clip to the top left of a trimmed picture of the sheet, in texture pixels (the origins
	// of the pictures are on whole pixels, see klinkersurprise_assets.py)
	static function offsetX(t:Texture):Int {
		return Math.round(-t.defaultAnchor.x * t.orig.width + (t.trim != null ? t.trim.x : 0));
	}

	static function offsetY(t:Texture):Int {
		return Math.round(-t.defaultAnchor.y * t.orig.height + (t.trim != null ? t.trim.y : 0));
	}

	static var VERT = "precision highp float;
attribute vec2 aVertexPosition;
attribute vec2 aTextureCoord;
attribute vec3 aOffset;
uniform mat3 projectionMatrix;
uniform mat3 translationMatrix;
varying vec2 vUv;
varying vec3 vOffset;
void main(void) {
	vUv = aTextureCoord;
	vOffset = aOffset;
	gl_Position = vec4((projectionMatrix * translationMatrix * vec3(aVertexPosition, 1.0)).xy, 0.0, 1.0);
}";

	// a Flash colour transform with offsets only: on the colours without premultiplied alpha, clamped
	static var FRAG = "precision mediump float;
varying vec2 vUv;
varying vec3 vOffset;
uniform sampler2D uSampler;
void main(void) {
	vec4 s = texture2D(uSampler, vUv);
	vec3 c = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
	c = clamp(c + vOffset, 0.0, 1.0);
	gl_FragColor = vec4(c * s.a, s.a);
}";

	// a picture of the sheet with its clip origin at (x, y) Flash pixels, on a x2 canvas
	public static function drawPicture(c:CanvasRenderingContext2D, t:Texture, x:Float, y:Float, k:Float = 1) {
		var src:Dynamic = untyped t.baseTexture.resource.source;
		var fr = t.frame;
		var ox = t.trim != null ? t.trim.x : 0;
		var oy = t.trim != null ? t.trim.y : 0;
		var dx = x * Game.K + (-t.defaultAnchor.x * t.orig.width + ox) * k;
		var dy = y * Game.K + (-t.defaultAnchor.y * t.orig.height + oy) * k;
		c.drawImage(src, fr.x, fr.y, fr.width, fr.height, dx, dy, fr.width * k, fr.height * k);
	}

	// the painted cells (grid >= PAINT), when they changed
	public function drawSpectre(grid:Array<Array<Int>>, size:Int):Void {
		if (!spectreDirty)
			return;
		spectreDirty = false;
		var K = Game.K;
		var used = 0;
		for (x in 0...grid.length) {
			for (y in 0...grid[x].length) {
				var t = grid[x][y];
				if (t < Game.PAINT)
					continue;
				if (used == cells.length)
					cells.push(new PixiSprite(Texture.WHITE));
				var s = cells[used++];
				s.position.set(x * size * K, y * size * K);
				s.scale.set(size * K / Texture.WHITE.width, size * K / Texture.WHITE.height);
				s.tint = Game.COLOR[t - Game.PAINT];
				s.alpha = 120 / 255;
				batch.addChild(s);
			}
		}
		KadoKadeoManager.kkm.renderer.render(batch, cast {renderTexture: spectre, clear: true});
		batch.removeChildren();
	}

	public function destroy():Void {
		batch.removeChildren();
		for (s in cells)
			s.destroy();
		cells = [];
		if (texture != null)
			texture.destroy(true);
		if (spectre != null)
			spectre.destroy(true);
		texture = null;
		spectre = null;
	}
}

/**
 * A background plane of Game.initBg: a 300 x 300 bitmap filled with a colour where mcLight is drawn "add" at random
 * places and scales (Math.random: a picture only), shown 2 x 2 times. Composed once on a x2 canvas; the light is
 * taken from the smallest of its pictures at least as big as drawn (light0..3) and scaled down by the canvas.
 */
class LightBitmap {
	public var texture(default, null):Texture;

	var canvas:CanvasElement;

	public function new(col:Int, c:Float, count:Int) {
		var K = Game.K;
		canvas = js.Browser.document.createCanvasElement();
		canvas.width = Game.mcw * K;
		canvas.height = Game.mch * K;
		var ctx = canvas.getContext2d();
		var a = (col >>> 24) & 0xFF;
		if (a > 0) {
			ctx.fillStyle = 'rgba(${(col >> 16) & 0xFF},${(col >> 8) & 0xFF},${col & 0xFF},${a / 255})';
			ctx.fillRect(0, 0, canvas.width, canvas.height);
		}
		ctx.globalCompositeOperation = "lighter";
		untyped ctx.imageSmoothingQuality = "high";
		for (i in 0...count) {
			var ma = 3;
			var x = ma + (Seed.randVfx() * Game.mcw - 2 * ma);
			var y = ma + (Seed.randVfx() * Game.mch - 2 * ma);
			var sc = (0.1 + Seed.randVfx() * 0.2) * c;
			// texture pixels per Flash pixel of the clip needed on the x2 canvas
			var need = sc * K;
			var k = Data.LIGHT_RES.length - 1;
			for (j in 0...Data.LIGHT_RES.length)
				if (Data.LIGHT_RES[j] >= need) {
					k = j;
					break;
				}
			Ground.drawPicture(ctx, Tex.get("light" + k)[0], x, y, need / Data.LIGHT_RES[k]);
		}
		texture = Texture.from(canvas);
	}

	public function destroy():Void {
		if (texture != null)
			texture.destroy(true);
		texture = null;
		canvas = null;
	}
}
