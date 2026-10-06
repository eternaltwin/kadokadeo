package klinkersurprise;

import pixi.core.Pixi.BlendModes;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

private enum PlasmaOp {
	// fillRect(rect, argb): the pixels replaced
	Fill(x:Int, y:Int, w:Int, h:Int, argb:Int);
	// draw(mcExplo, matrix (scale sc, translate x y), ColorTransform(0, 0, 0, 1, r, g, b, 0), "add")
	Explo(sc:Float, x:Float, y:Float, r:Int, g:Int, b:Int);
}

private typedef PlasmaFrame = {ops:Array<PlasmaOp>, sx:Int, sy:Int};

/**
 * The plasma of the original (mt.bumdum.Plasma, Game.initPlasma): a 300 x 300 bitmap over the map where the code
 * paints the cells it lights (fillRect, white) and the explosions of the freed cells (draw "add"); every Flash frame
 * Game.updateScroll scrolls it with the map (BitmapData.scroll: whole pixels, the uncovered edges keep their pixels),
 * then Plasma.update applies its ColorTransform (x1.1 - 10 on the colours, -16 on the alpha) and its BlurFilter
 * (2 x 2, quality 1): a white trail that fades in about 16 frames.
 *
 * On the GPU (the Plasma layer of Iron Chouquette): two textures, the drawings of a frame batched into one, then one
 * shader pass does scroll + colour transform + blur into the other. A picture only: nothing of the game reads it. The
 * frames are queued and drawn just before the screen is (flush, from the ticker of the page): a replay seek or the
 * catch up of a hidden tab, which simulate many frames without drawing them, draw only the last 16, and what is older
 * has faded out completely by then (the alpha loses 16 per frame, the blur cannot raise it): the picture is the same.
 */
class Plasma {
	static inline var LIFE = 16;
	static var program:Dynamic;

	// the bitmap's clip (Bmp.root, at DP_PLASMA) and the holder of its picture (moved with the map display, see
	// Game.placePlasma)
	public var root:MC;
	public var holder:ASprite;

	var w:Int;
	var h:Int;
	var tex:Array<RenderTexture>;
	var cur = 0;
	var view:PixiSprite;
	var pass:Dynamic;
	var uniforms:Dynamic;
	var batch = new Container();
	var sprites:Array<PixiSprite> = [];
	var used = 0;
	var queue:Array<PlasmaFrame> = [];
	var frame:PlasmaFrame;
	var dropped = false;
	var blank = true;
	var idle = 0;

	public function new(mc:MC, w:Int, h:Int) {
		root = mc;
		this.w = w;
		this.h = h;
		frame = {ops: [], sx: 0, sy: 0};
		tex = [RenderTexture.create(w, h), RenderTexture.create(w, h)];
		holder = new ASprite();
		view = new PixiSprite(tex[0]);
		holder.addChild(view);
		root.spr.addChild(holder);

		var P:Dynamic = untyped PIXI;
		var geometry:Dynamic = js.Syntax.construct(P.Geometry);
		geometry.addAttribute("aVertexPosition", [0, 0, w, 0, w, h, 0, h], 2);
		geometry.addAttribute("aTextureCoord", [0, 0, 1, 0, 1, 1, 0, 1], 2);
		geometry.addIndex([0, 1, 2, 0, 2, 3]);
		var base:Dynamic = tex[0].baseTexture;
		uniforms = {
			uSrc: tex[0],
			uTexel: new js.lib.Float32Array([1 / base.realWidth, 1 / base.realHeight]),
			uScroll: new js.lib.Float32Array([0, 0]),
		};
		if (program == null)
			program = P.Program.from(VERT, FRAG, "kkKlinkerPlasma");
		pass = js.Syntax.construct(P.Mesh, geometry, js.Syntax.construct(P.Shader, program, uniforms));
		// compiles the shader now (at the start of the game) rather than at the first painted cell
		render(pass, tex[1], true);
		render(new Container(), tex[1], true);
	}

	public function setPos(x:Float, y:Float):Void {
		root._x = x;
		root._y = y;
	}

	public function fillRect(x:Int, y:Int, w:Int, h:Int, argb:Int):Void {
		frame.ops.push(Fill(x, y, w, h, argb));
	}

	public function drawExplo(sc:Float, x:Float, y:Float, r:Int, g:Int, b:Int):Void {
		frame.ops.push(Explo(sc, x, y, r, g, b));
	}

	// BitmapData.scroll(x, y) (a number that is not one, NaN: no scroll)
	public function scroll(dx:Float, dy:Float):Void {
		frame.sx += Math.isNaN(dx) ? 0 : Std.int(dx);
		frame.sy += Math.isNaN(dy) ? 0 : Std.int(dy);
	}

	// Plasma.update: colorTransform then the BlurFilter, the end of the Flash frame
	public function update():Void {
		queue.push(frame);
		frame = {ops: [], sx: 0, sy: 0};
		if (queue.length > LIFE) {
			queue.shift();
			dropped = true;
		}
	}

	// the frames queued, on the GPU (before the screen is drawn)
	public function flush():Void {
		if (queue.length == 0)
			return;
		if (dropped) {
			// what the frames before the queue drew has faded out
			clearAll();
			dropped = false;
		}
		for (f in queue) {
			if (f.ops.length > 0) {
				drawOps(f.ops);
				blank = false;
				idle = 0;
			}
			if (blank)
				continue;
			uniforms.uSrc = tex[cur];
			var us:js.lib.Float32Array = uniforms.uScroll;
			us[0] = f.sx / w;
			us[1] = f.sy / h;
			cur = 1 - cur;
			render(pass, tex[cur], true);
			if (++idle >= LIFE) {
				// faded out completely: nothing to do until the next drawing
				clearAll();
			}
		}
		queue = [];
		view.texture = tex[cur];
	}

	function drawOps(ops:Array<PlasmaOp>):Void {
		for (op in ops) {
			switch (op) {
				case Fill(x, y, fw, fh, argb):
					var s = sprite(Texture.WHITE);
					s.anchor.set(0, 0);
					s.position.set(x, y);
					s.scale.set(fw / Texture.WHITE.width, fh / Texture.WHITE.height);
					s.tint = argb & 0xFFFFFF;
					s.alpha = (argb >>> 24) / 255;
					// no blending: the pixels are replaced, like fillRect
					s.blendMode = BlendModes.NONE;
				case Explo(sc, x, y, r, g, b):
					// the smallest picture at least as big as drawn (1, 2 or 4 pixels per pixel of the clip)
					var res = sc <= 1 ? 1 : sc <= 2 ? 2 : 4;
					var t = Tex.get("explo" + res)[0];
					var s = sprite(t);
					s.anchor.copyFrom(t.defaultAnchor);
					s.position.set(x, y);
					s.scale.set(sc / res, sc / res);
					// ColorTransform(0, 0, 0, 1, r, g, b, 0): the offsets (clamped to 255) on a white silhouette
					s.tint = (clamp(r) << 16) | (clamp(g) << 8) | clamp(b);
					s.alpha = 1;
					s.blendMode = BlendModes.ADD;
			}
		}
		render(batch, tex[cur], false);
		batch.removeChildren();
		used = 0;
	}

	static inline function clamp(v:Int):Int {
		return v < 0 ? 0 : v > 255 ? 255 : v;
	}

	function sprite(t:Texture):PixiSprite {
		if (used == sprites.length)
			sprites.push(new PixiSprite(t));
		var s = sprites[used++];
		s.texture = t;
		batch.addChild(s);
		return s;
	}

	function clearAll():Void {
		var empty = new Container();
		render(empty, tex[0], true);
		render(empty, tex[1], true);
		blank = true;
		idle = 0;
	}

	public function destroy():Void {
		batch.removeChildren();
		for (s in sprites)
			s.destroy();
		sprites = [];
		pass.destroy();
		view.destroy();
		for (t in tex)
			t.destroy(true);
		queue = [];
	}

	inline function render(o:DisplayObject, target:RenderTexture, clear:Bool) {
		KadoKadeoManager.kkm.renderer.render(o, cast {renderTexture: target, clear: clear});
	}

	static var VERT = "precision highp float;
attribute vec2 aVertexPosition;
attribute vec2 aTextureCoord;
uniform mat3 projectionMatrix;
uniform mat3 translationMatrix;
varying vec2 vUv;
void main(void) {
	vUv = aTextureCoord;
	gl_Position = vec4((projectionMatrix * translationMatrix * vec3(aVertexPosition, 1.0)).xy, 0.0, 1.0);
}";

	// one Flash frame of the bitmap: scroll (uScroll, in texture coordinates: a pixel moves by it, the pixels it does
	// not cover keep theirs), colorTransform (on the colours without premultiplied alpha: x1.1 - 10, alpha - 16), then
	// BlurFilter 2 x 2 quality 1 (a box of 2 pixels centred: weights 1/4 1/2 1/4 on each axis, outside is transparent)
	static var FRAG = "#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
varying vec2 vUv;
uniform sampler2D uSrc;
uniform vec2 uTexel;
uniform vec2 uScroll;
vec4 tap(vec2 p) {
	vec2 inside = step(vec2(0.0), p) * step(p, vec2(1.0));
	if (inside.x * inside.y < 0.5) return vec4(0.0);
	vec2 q = p - uScroll;
	vec2 qin = step(vec2(0.0), q) * step(q, vec2(1.0));
	vec4 s = texture2D(uSrc, qin.x * qin.y > 0.5 ? q : p);
	vec3 c = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
	c = clamp(c * 1.1 - 10.0 / 255.0, 0.0, 1.0);
	float a = clamp(s.a - 16.0 / 255.0, 0.0, 1.0);
	return vec4(c * a, a);
}
void main(void) {
	vec2 dx = vec2(uTexel.x, 0.0);
	vec2 dy = vec2(0.0, uTexel.y);
	vec4 r0 = tap(vUv - dx - dy) * 0.25 + tap(vUv - dy) * 0.5 + tap(vUv + dx - dy) * 0.25;
	vec4 r1 = tap(vUv - dx) * 0.25 + tap(vUv) * 0.5 + tap(vUv + dx) * 0.25;
	vec4 r2 = tap(vUv - dx + dy) * 0.25 + tap(vUv + dy) * 0.5 + tap(vUv + dx + dy) * 0.25;
	gl_FragColor = r0 * 0.25 + r1 * 0.5 + r2 * 0.25;
}";
}
