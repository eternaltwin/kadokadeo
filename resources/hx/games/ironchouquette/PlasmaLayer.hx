package ironchouquette;

import common_haxe_avm1.display.ASprite;
import pixi.core.Pixi.BlendModes;
import pixi.core.Pixi.ScaleModes;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.graphics.Graphics;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

/**
	One layer of the plasma of the original game: a small bitmap where things are stamped (BitmapData.draw) and which is
	blurred (BlurFilter), colour transformed (ColorTransform) then scrolled at every step, shown scaled up behind the game.

	Whatever the number of stamps, a step costs at most two renders into a texture:
	- `flush()`: every stamp of the step at once. A stamp is a copy of the sprites (and graphics) of the clip as they are
	  when it is stamped, taken from a pool, so PIXI batches them all in a few draw calls. No filter.
	- `step()`: one pass of a shader that does blur + colour transform + scroll together, from one texture into the other.
	When nothing was stamped for long enough to be faded out completely, the layer is cleared and costs nothing.
**/
class PlasmaLayer {
	static var programs:Map<Int, Dynamic> = new Map();

	public var view(default, null):Sprite;

	var w:Int;
	var h:Int;
	var k:Int;
	var tex:Array<RenderTexture>;
	var cur = 0;
	var pass:Dynamic;
	var uniforms:Dynamic;
	var batch = new Container();
	var target:Container;
	var sprites:Array<Sprite> = [];
	var used = 0;
	var graphics:Array<Graphics> = [];
	var matrices:Array<Matrix> = [];
	var offWraps:Array<Container> = [];
	var offFilters:Array<Dynamic> = [];
	var offUsed = 0;
	var additive:Bool;
	var idle = 0;
	var idleMax = 0;
	var blank = true;

	/**
		`maxBlur`: largest blur (BlurFilter blurX/blurY, in pixels of the layer) `step` will be asked for. `additive`: the
		layer is shown with the ADD blend mode (else NORMAL).
	**/
	public function new(w:Int, h:Int, maxBlur:Float, additive:Bool) {
		this.w = w;
		this.h = h;
		this.additive = additive;
		target = batch;
		k = Std.int(Math.max(0, Math.ceil(maxBlur / 2 - 0.5)));
		// NEAREST: the original attached the BitmapData without smoothing, the x4 upscale shows the texels as blocks
		// (the blur taps of `step` all land on texel centers, so the sampled side is unchanged)
		tex = [for (i in 0...2) (cast RenderTexture : Dynamic).create({width: w, height: h, scaleMode: ScaleModes.NEAREST})];
		view = new Sprite(tex[0]);
		if (additive)
			view.blendMode = BlendModes.ADD;

		var P:Dynamic = untyped PIXI;
		var geometry:Dynamic = js.Syntax.construct(P.Geometry);
		geometry.addAttribute("aVertexPosition", [0, 0, w, 0, w, h, 0, h], 2);
		geometry.addAttribute("aTextureCoord", [0, 0, 1, 0, 1, 1, 0, 1], 2);
		geometry.addIndex([0, 1, 2, 0, 2, 3]);
		var base:Dynamic = tex[0].baseTexture;
		uniforms = {
			uSrc: tex[0],
			uTexel: new js.lib.Float32Array([1 / base.realWidth, 1 / base.realHeight]),
			uScroll: 0.0,
			uMult: new js.lib.Float32Array([1, 1, 1, 1]),
			uOff: new js.lib.Float32Array([0, 0, 0, 0]),
			uBias: new js.lib.Float32Array([0, 0, 0, 0]),
		};
		for (i in 0...k + 1)
			Reflect.setField(uniforms, "uW" + i, 0.0);
		pass = js.Syntax.construct(P.Mesh, geometry, js.Syntax.construct(P.Shader, program(k), uniforms));
		// compiles the shaders now (at the start of the game) rather than at the first explosion or the first
		// fading stamp (tens of ms): the alpha offset filter on a 1 px rectangle, then the blur pass, whose
		// clear also wipes what the filter warm-up left in tex[1]
		var warmWrap = offWrap(-0.5, BlendModes.NORMAL);
		var warmG = new Graphics();
		warmG.beginFill(0xFFFFFF, 1);
		warmG.drawRect(0, 0, 1, 1);
		warmG.endFill();
		warmWrap.addChild(warmG);
		render(warmWrap, tex[1], true);
		warmWrap.removeChildren();
		warmG.destroy();
		offUsed = 0;
		render(pass, tex[1], true);
	}

	/**
		Stamps `mc` (its picture and its children, as they are now) with the matrix `m` into the layer at the next `flush()`,
		like BitmapData.draw(mc, m, ColorTransform(alpha), blend): the own transform, colour and filters of `mc` are ignored,
		its children keep theirs. Alpha is applied like Flash's stamp, as an offset (per pixel A' = max(A - 255*(1-alpha), 0):
		a fading stamp loses its soft edges first and shrinks to its bright core). A child with no blend mode of its own
		takes `blend`.
	**/
	public function draw(mc:DisplayObject, m:Matrix, alpha:Float, blend:BlendModes) {
		if (mc == null || !mc.visible || alpha <= 0)
			return;
		if (alpha < 1) {
			// one filter pass over this stamp alone: the offset is applied to the composited stamp, then the
			// filter's own draw composites it with `blend` (Flash cascades the offset to each leaf instead:
			// identical for the single-picture clips that are ever stamped with alpha here)
			var wrap = offWrap(Math.max(alpha, 0) - 1, blend);
			batch.addChild(wrap);
			target = wrap;
			add(mc, m, 1, BlendModes.NORMAL, 0, true);
			target = batch;
		} else
			add(mc, m, 1, blend, 0, true);
	}

	/** A pooled container carrying the alpha offset filter of one stamp (`aoff` in -1..0, `blend` for its final draw). **/
	function offWrap(aoff:Float, blend:BlendModes):Container {
		if (offUsed == offWraps.length) {
			var f:Dynamic = js.Syntax.construct((untyped PIXI).Filter, null, FRAG_OFF, {uAOff: 0.0});
			f.padding = 0;
			var c = new Container();
			c.filters = [f];
			offWraps.push(c);
			offFilters.push(f);
		}
		var f = offFilters[offUsed];
		f.uniforms.uAOff = aoff;
		f.blendMode = blend;
		return offWraps[offUsed++];
	}

	function add(o:DisplayObject, m:Matrix, alpha:Float, blend:BlendModes, depth:Int, top:Bool) {
		var own:BlendModes = untyped o.blendMode;
		var mode = (top || own == null || own == BlendModes.NORMAL) ? blend : own;
		if (Std.isOfType(o, Graphics)) {
			var src:Graphics = cast o;
			var g:Graphics = js.Syntax.construct(Graphics, src.geometry);
			g.tint = src.tint;
			setup(g, m, alpha, mode);
			graphics.push(g);
		} else if (Std.isOfType(o, Sprite)) {
			var src:Sprite = cast o;
			var t = src.texture;
			if (t != null && t != Texture.EMPTY && t.valid) {
				if (used == sprites.length)
					sprites.push(new Sprite(t));
				var s = sprites[used++];
				s.texture = t;
				s.anchor.copyFrom(src.anchor);
				s.tint = top ? 0xFFFFFF : src.tint;
				setup(s, m, alpha, mode);
			}
		}
		var children:Array<DisplayObject> = untyped o.children;
		if (children == null || children.length == 0)
			return;
		if (matrices.length <= depth)
			matrices.push(new Matrix());
		var cm = matrices[depth];
		for (c in children) {
			if (!c.visible)
				continue;
			var a = c.alpha;
			if (Std.isOfType(c, ASprite)) {
				// logic state, not the interpolated picture of the last frame
				var s:ASprite = cast c;
				var st = s._curState;
				var cos = Math.cos(st.rotation), sin = Math.sin(st.rotation);
				cm.a = cos * st.xscale;
				cm.b = sin * st.xscale;
				cm.c = -sin * st.yscale;
				cm.d = cos * st.yscale;
				cm.tx = st.x - (s.pivot.x * cm.a + s.pivot.y * cm.c);
				cm.ty = st.y - (s.pivot.x * cm.b + s.pivot.y * cm.d);
				a = st.alpha;
			} else {
				c.transform.updateLocalTransform();
				var l = c.transform.localTransform;
				cm.a = l.a;
				cm.b = l.b;
				cm.c = l.c;
				cm.d = l.d;
				cm.tx = l.tx;
				cm.ty = l.ty;
			}
			if (a <= 0)
				continue;
			// world = m * local, into the matrix of the next depth (cm is reused by the children of c)
			var wm = depth + 1 < matrices.length ? matrices[depth + 1] : null;
			if (wm == null) {
				wm = new Matrix();
				matrices.push(wm);
			}
			var la = cm.a, lb = cm.b, lc = cm.c, ld = cm.d, ltx = cm.tx, lty = cm.ty;
			wm.a = m.a * la + m.c * lb;
			wm.b = m.b * la + m.d * lb;
			wm.c = m.a * lc + m.c * ld;
			wm.d = m.b * lc + m.d * ld;
			wm.tx = m.a * ltx + m.c * lty + m.tx;
			wm.ty = m.b * ltx + m.d * lty + m.ty;
			add(c, wm, alpha * a, mode, depth + 2, false);
		}
	}

	function setup(o:DisplayObject, m:Matrix, alpha:Float, blend:BlendModes) {
		o.transform.setFromMatrix(m);
		o.alpha = alpha;
		untyped o.blendMode = blend;
		target.addChild(o);
	}

	/** Draws every stamp waiting into the layer (one render). **/
	public function flush() {
		if (batch.children.length == 0)
			return;
		render(batch, tex[cur], false);
		batch.removeChildren();
		for (i in 0...offUsed)
			offWraps[i].removeChildren();
		offUsed = 0;
		used = 0;
		for (g in graphics)
			g.destroy();
		graphics = [];
		blank = false;
		idle = 0;
	}

	/**
		Blur of `blur` pixels (box, like BlurFilter quality 1), then ColorTransform `mult` * colour + `off` (offsets in 0..255
		like Flash, on the colours without premultiplied alpha), then scroll of `scroll` pixels down (rows uncovered at the
		top are left as they are, like BitmapData.scroll). Waiting stamps are drawn first.
	**/
	public function step(blur:Float, mult:Array<Float>, off:Array<Float>, scroll:Int) {
		flush();
		if (blank)
			return;
		if (idleMax == 0) {
			// steps after which the decay has brought what is seen to nothing: the colours when added, else the alpha
			// (a multiplier alone takes at least 1 off each step, see uBias)
			idleMax = 0;
			for (i in (additive ? [0, 1, 2] : [3])) {
				var dec = Math.max(-off[i], mult[i] < 1 ? 1 : 0);
				idleMax = dec > 0 ? Std.int(Math.max(idleMax, Math.ceil(256 / dec) + 8)) : 1 << 30;
				if (dec <= 0)
					break;
			}
		}
		if (++idle > idleMax) {
			clear();
			return;
		}
		var bw = Math.max(blur, 1e-3);
		for (i in 0...k + 1)
			Reflect.setField(uniforms, "uW" + i, Math.min(1, Math.max(0, bw / 2 + 0.5 - i)) / bw);
		var um:js.lib.Float32Array = uniforms.uMult, uo:js.lib.Float32Array = uniforms.uOff, ub:js.lib.Float32Array = uniforms.uBias;
		for (i in 0...4) {
			um[i] = mult[i];
			uo[i] = off[i] / 255;
			// a channel that fades rounds down instead of to the nearest: faint pixels fade out too (8 bits)
			ub[i] = (off[i] < 0 || mult[i] < 1) ? 0.49 / 255 : 0;
		}
		uniforms.uScroll = scroll / h;
		uniforms.uSrc = tex[cur];
		cur = 1 - cur;
		render(pass, tex[cur], true);
		view.texture = tex[cur];
	}

	public function clear() {
		batch.removeChildren();
		for (i in 0...offUsed)
			offWraps[i].removeChildren();
		offUsed = 0;
		used = 0;
		for (g in graphics)
			g.destroy();
		graphics = [];
		var empty = new Container();
		render(empty, tex[0], true);
		render(empty, tex[1], true);
		blank = true;
		idle = 0;
	}

	public function destroy() {
		batch.removeChildren();
		for (g in graphics)
			g.destroy();
		for (s in sprites)
			s.destroy();
		for (c in offWraps)
			c.destroy();
		offWraps = [];
		offFilters = [];
		sprites = [];
		graphics = [];
		pass.destroy();
		view.destroy();
		for (t in tex)
			t.destroy(true);
	}

	inline function render(o:DisplayObject, target:RenderTexture, clear:Bool) {
		KadoKadeoManager.kkm.renderer.render(o, cast {renderTexture: target, clear: clear});
	}

	/** Fragment of the alpha offset filter: Flash's stamp ColorTransform(1,1,1,1, 0,0,0, -255*(1-alpha)). **/
	static var FRAG_OFF = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform float uAOff;
void main(void) {
	vec4 c = texture2D(uSampler, vTextureCoord);
	vec3 rgb = c.a > 0.0 ? c.rgb / c.a : vec3(0.0);
	float a = max(c.a + uAOff, 0.0);
	gl_FragColor = vec4(rgb * a, a);
}";

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

	/** Shader of `step` for a blur of at most 2k+1 pixels: (2k+1)² taps, unrolled. **/
	static function program(k:Int):Dynamic {
		var p = programs.get(k);
		if (p != null)
			return p;
		var b = new StringBuf();
		b.add("#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif\n");
		b.add("varying vec2 vUv;\nuniform sampler2D uSrc;\nuniform vec2 uTexel;\nuniform float uScroll;\n");
		b.add("uniform vec4 uMult;\nuniform vec4 uOff;\nuniform vec4 uBias;\n");
		for (i in 0...k + 1)
			b.add('uniform float uW$i;\n');
		// outside the bitmap is transparent (no clamp to edge)
		b.add("vec4 tap(vec2 p) {\n\tvec2 q = step(vec2(0.0), p) * step(p, vec2(1.0));\n\treturn texture2D(uSrc, p) * (q.x * q.y);\n}\n");
		b.add("void main(void) {\n\tvec2 uv = vUv;\n\tif (uv.y - uScroll >= 0.0) uv.y -= uScroll;\n\tvec4 s = vec4(0.0);\n");
		for (j in -k...k + 1)
			for (i in -k...k + 1)
				b.add('\ts += tap(uv + vec2(${i}.0, ${j}.0) * uTexel) * (uW${i < 0 ? -i : i} * uW${j < 0 ? -j : j});\n');
		b.add("\tvec3 c = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);\n");
		b.add("\tc = clamp(c * uMult.rgb + uOff.rgb, 0.0, 1.0);\n");
		b.add("\tfloat a = clamp(s.a * uMult.a + uOff.a, 0.0, 1.0);\n");
		b.add("\tgl_FragColor = max(vec4(c * a, a) - uBias, 0.0);\n}\n");
		p = (untyped PIXI).Program.from(VERT, b.toString(), "kkPlasma" + k);
		programs.set(k, p);
		return p;
	}
}
