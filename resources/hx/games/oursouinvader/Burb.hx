package oursouinvader;

import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;

private typedef BurbFrame = {bubbles:Array<Float>};

/**
 * One bitmap of the bubble generator of the original (Game.initBurbulisseur / updateBurbulisseur, "burb"): a transparent
 * BitmapData of 300 x h at the bottom of the screen, attached to an empty clip of the background plane. Every Flash
 * frame the code may draw mcSmallBubble into it (BitmapData.draw, scale sc, at a random x and h - 20), then lowers its
 * alpha (colorTransform: alpha offset -(3 + i)) and scrolls it up by i + 1 pixels (BitmapData.scroll: the uncovered
 * rows keep their pixels): bubbles that rise and fade.
 *
 * On the GPU at its own resolution, 1 pixel per Flash pixel, shown x2 like the other bitmaps of the game (the
 * bubbles drawn into it keep the thin outlines of the original): two textures, the bubbles of a frame drawn into one,
 * then one shader pass does colour transform + scroll into the other (Klinker Surprise's Plasma). A picture
 * only: nothing of the game reads it. The frames are queued and drawn just before the screen is (flush, from the
 * ticker of the page): a replay seek, which simulates many frames without drawing them, draws only the last LIFE
 * frames, and what is older has faded out completely by then (the alpha loses at least 3 per frame).
 */
class Burb {
	static inline var LIFE = 90;
	static var program:Dynamic;

	// the clip of the bitmap (dm.empty(0)) and its height
	public var mc:MC;
	public var h:Int;

	var index:Int;
	var w:Int;
	var th:Int;
	var tex:Array<RenderTexture>;
	var cur = 0;
	var view:PixiSprite;
	var pass:Dynamic;
	var uniforms:Dynamic;
	var batch = new Container();
	var sprites:Array<PixiSprite> = [];
	var used = 0;
	var queue:Array<BurbFrame> = [];
	var frame:BurbFrame;
	var dropped = false;
	var blank = true;
	var idle = 0;

	public function new(mc:MC, i:Int, h:Int) {
		this.mc = mc;
		this.index = i;
		this.h = h;
		w = Cs.mcw;
		th = h;
		frame = {bubbles: []};
		tex = [RenderTexture.create(w, th), RenderTexture.create(w, th)];
		// (the children of an empty clip are in Flash pixels)
		view = new PixiSprite(tex[0]);
		mc.clip.addChild(view);

		var P:Dynamic = untyped PIXI;
		var geometry:Dynamic = js.Syntax.construct(P.Geometry);
		geometry.addAttribute("aVertexPosition", [0, 0, w, 0, w, th, 0, th], 2);
		geometry.addAttribute("aTextureCoord", [0, 0, 1, 0, 1, 1, 0, 1], 2);
		geometry.addIndex([0, 1, 2, 0, 2, 3]);
		uniforms = {
			uSrc: tex[0],
			uScroll: 0.0,
			uAlpha: 0.0,
		};
		if (program == null)
			program = P.Program.from(VERT, FRAG, "kkOursouBurb");
		pass = js.Syntax.construct(P.Mesh, geometry, js.Syntax.construct(P.Shader, program, uniforms));
		// compiles the shader now (at the start of the game) rather than at the first bubble
		render(pass, tex[1], true);
		render(new Container(), tex[1], true);
	}

	// mc.bmp.draw(bubble, Matrix(scale sc, translate x y)): mcSmallBubble drawn into the bitmap
	public function draw(sc:Float, x:Float, y:Float):Void {
		frame.bubbles.push(sc);
		frame.bubbles.push(x);
		frame.bubbles.push(y);
	}

	// colorTransform(alpha - (3 + i)) and scroll(0, -(i + 1)): the end of the Flash frame of this bitmap
	public function endFrame():Void {
		queue.push(frame);
		frame = {bubbles: []};
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
			if (f.bubbles.length > 0) {
				drawBubbles(f.bubbles);
				blank = false;
				idle = 0;
			}
			if (blank)
				continue;
			uniforms.uSrc = tex[cur];
			uniforms.uScroll = (index + 1) / th;
			uniforms.uAlpha = (3 + index) / 255;
			cur = 1 - cur;
			render(pass, tex[cur], true);
			if (++idle >= LIFE) {
				// faded out completely: nothing to do until the next bubble
				clearAll();
			}
		}
		queue = [];
		view.texture = tex[cur];
	}

	function drawBubbles(b:Array<Float>):Void {
		var t = Tex.get(Clip.getDef("mcSmallBubble1").layers[0].a)[0];
		// texture pixels per Flash pixel of mcSmallBubble1 (1)
		var tr = Clip.K * Clip.getDef("mcSmallBubble1").r;
		var i = 0;
		while (i < b.length) {
			if (used == sprites.length)
				sprites.push(new PixiSprite(t));
			var s = sprites[used++];
			s.texture = t;
			s.anchor.copyFrom(t.defaultAnchor);
			var k = b[i] / tr;
			s.scale.set(k, k);
			s.position.set(b[i + 1], b[i + 2]);
			batch.addChild(s);
			i += 3;
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

	// mc.bmp.dispose(); mc.removeMovieClip() (Game.updateGfxMode)
	public function dispose():Void {
		batch.removeChildren();
		for (s in sprites)
			s.destroy();
		sprites = [];
		pass.destroy();
		view.destroy();
		for (t in tex)
			t.destroy(true);
		queue = [];
		mc.removeMovieClip();
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

	// one Flash frame of the bitmap: colorTransform (alpha offset -uAlpha on the colours without premultiplied alpha:
	// the colours stay, the alpha drops), then scroll up by uScroll (texture coordinates; the rows it does not cover
	// keep theirs)
	static var FRAG = "#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
varying vec2 vUv;
uniform sampler2D uSrc;
uniform float uScroll;
uniform float uAlpha;
void main(void) {
	vec2 q = vec2(vUv.x, vUv.y + uScroll);
	vec4 s = texture2D(uSrc, q.y <= 1.0 ? q : vUv);
	vec3 c = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
	float a = clamp(s.a - uAlpha, 0.0, 1.0);
	gl_FragColor = vec4(c * a, a);
}";
}
