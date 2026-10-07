package chakrebouddha;

import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

private typedef PlasmaDraw = {frame:Int, x:Float, y:Float};

/**
 * The plasma of the original (mt.bumdum.Plasma, Game.new): new Plasma(dm.empty(DP_CHAKRAS), 300, 300, 0.4), a bitmap
 * of 120 x 120 pixels shown at 250 % (attachBitmap without smoothing: big pixels) over the chakras. The chakras that
 * move draw themselves into it (Chakra.update: plasma.drawMc(mc), at 0.4 pixel per Flash pixel), then every Flash
 * frame Plasma.update applies its ColorTransform (alpha - 25) and its BlurFilter (4 x 4, quality 3): a blurred trail
 * that fades in about 10 frames. (blendMode "ligthen": not a blend mode, Flash draws it normally.)
 *
 * On the GPU (the Plasma of Klinker Surprise): two textures, the drawings of a frame batched into one, then two shader
 * passes (colour transform + horizontal blur, vertical blur). A picture only: nothing of the game reads it. The frames
 * are queued and drawn just before the screen is (flush, from the ticker of the page), all but the last one: like the
 * clips (MC), the picture shown is one Flash frame late. A replay seek or the catch up of a hidden tab, which simulate
 * many frames without drawing them, draw only the last LIFE, and what is older has faded out completely by then (the
 * alpha loses 25 per frame, the blur cannot raise it): the picture is the same.
 */
class Plasma {
	static inline var LIFE = 12;
	static inline var TAPS = 13;
	static var program:Dynamic;
	static var weights:js.lib.Float32Array;

	// bitmap pixels per Flash pixel
	public var pq:Float;
	// the bitmap's clip (Bmp.root)
	public var root:MC;

	var w:Int;
	var h:Int;
	var tex:Array<RenderTexture>;
	var tmp:RenderTexture;
	var cur = 0;
	var view:PixiSprite;
	var passH:Dynamic;
	var passV:Dynamic;
	var batch = new Container();
	var sprites:Array<PixiSprite> = [];
	var used = 0;
	var queue:Array<Array<PlasmaDraw>> = [];
	var frame:Array<PlasmaDraw> = [];
	var dropped = false;
	var blank = true;
	var idle = 0;

	public function new(mc:MC, w:Int, h:Int, q:Float) {
		root = mc;
		pq = q;
		this.w = Std.int(w * pq);
		this.h = Std.int(h * pq);
		root._xscale = 100 / pq;
		root._yscale = 100 / pq;
		var nearest:Dynamic = untyped PIXI.SCALE_MODES.NEAREST;
		inline function rt()
			return (cast RenderTexture : Dynamic).create({width: this.w, height: this.h, scaleMode: nearest});
		tex = [rt(), rt()];
		tmp = rt();
		view = new PixiSprite(tex[0]);
		root.spr.addChild(view);

		if (weights == null) {
			// the box of a BlurFilter of 4 pixels (weights 1/2 at its ends), three times
			var box = [0.125, 0.25, 0.25, 0.25, 0.125];
			var k = [1.0];
			for (_ in 0...3) {
				var n = [for (_ in 0...k.length + 4) 0.0];
				for (i in 0...k.length)
					for (j in 0...5)
						n[i + j] += k[i] * box[j];
				k = n;
			}
			weights = new js.lib.Float32Array(k);
		}
		var P:Dynamic = untyped PIXI;
		if (program == null)
			program = P.Program.from(VERT, FRAG, "kkChakraPlasma");
		passH = mesh(true);
		passV = mesh(false);
		// compiles the shader now (at the start of the game) rather than at the first move
		render(passH, tex[1], true);
		render(new Container(), tex[1], true);
	}

	function mesh(horizontal:Bool):Dynamic {
		var P:Dynamic = untyped PIXI;
		var geometry:Dynamic = js.Syntax.construct(P.Geometry);
		geometry.addAttribute("aVertexPosition", [0, 0, w, 0, w, h, 0, h], 2);
		geometry.addAttribute("aTextureCoord", [0, 0, 1, 0, 1, 1, 0, 1], 2);
		geometry.addIndex([0, 1, 2, 0, 2, 3]);
		var u = {
			uSrc: tex[0],
			uStep: new js.lib.Float32Array(horizontal ? [1 / w, 0] : [0, 1 / h]),
			uCt: horizontal ? 1.0 : 0.0,
			uW: weights,
		};
		return js.Syntax.construct(P.Mesh, geometry, js.Syntax.construct(P.Shader, program, u));
	}

	// Bmp.drawMc(mc): the clip at its place, its scale and rotation, times pq (the chakras: scale 100, no rotation)
	public function drawMc(mc:MC):Void {
		frame.push({frame: mc._currentframe, x: mc._x * pq, y: mc._y * pq});
	}

	// Plasma.update: colorTransform then the BlurFilter, the end of the Flash frame
	public function update():Void {
		queue.push(frame);
		frame = [];
		if (queue.length > LIFE + 1) {
			queue.shift();
			dropped = true;
		}
	}

	// the frames queued but the last one, on the GPU (before the screen is drawn)
	public function flush():Void {
		if (queue.length < 2)
			return;
		if (dropped) {
			// what the frames before the queue drew has faded out
			clearAll();
			dropped = false;
		}
		var last = queue.pop();
		for (f in queue) {
			if (f.length > 0) {
				drawOps(f);
				blank = false;
				idle = 0;
			}
			if (blank)
				continue;
			passH.shader.uniforms.uSrc = tex[cur];
			render(passH, tmp, true);
			passV.shader.uniforms.uSrc = tmp;
			cur = 1 - cur;
			render(passV, tex[cur], true);
			if (++idle >= LIFE) {
				// faded out completely: nothing to do until the next drawing
				clearAll();
			}
		}
		queue = [last];
		view.texture = tex[cur];
	}

	function drawOps(ops:Array<PlasmaDraw>):Void {
		var frames = Tex.get("chakrap");
		for (op in ops) {
			var t = frames[op.frame - 1];
			if (used == sprites.length)
				sprites.push(new PixiSprite(t));
			var s = sprites[used++];
			s.texture = t;
			s.anchor.copyFrom(t.defaultAnchor);
			s.position.set(op.x, op.y);
			batch.addChild(s);
		}
		render(batch, tex[cur], false);
		batch.removeChildren();
		used = 0;
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
		passH.destroy();
		passV.destroy();
		view.destroy();
		for (t in tex)
			t.destroy(true);
		tmp.destroy(true);
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

	// one axis of the blur (13 samples: a box of 4 pixels three times), outside the bitmap transparent; on the
	// horizontal pass, the ColorTransform first (alpha - 25 on the colours without premultiplied alpha)
	static var FRAG = "#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
varying vec2 vUv;
uniform sampler2D uSrc;
uniform vec2 uStep;
uniform float uCt;
uniform float uW[13];
vec4 tap(vec2 p) {
	if (p.x < 0.0 || p.y < 0.0 || p.x > 1.0 || p.y > 1.0) return vec4(0.0);
	vec4 s = texture2D(uSrc, p);
	if (uCt > 0.5) {
		vec3 c = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
		float a = clamp(s.a - 25.0 / 255.0, 0.0, 1.0);
		s = vec4(c * a, a);
	}
	return s;
}
void main(void) {
	vec4 sum = vec4(0.0);
	for (int i = 0; i < 13; i++)
		sum += tap(vUv + uStep * float(i - 6)) * uW[i];
	gl_FragColor = sum;
}";
}
