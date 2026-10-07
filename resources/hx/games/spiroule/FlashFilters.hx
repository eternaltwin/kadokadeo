package spiroule;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * The Flash 8 filters the code of Spiroule sets, at run time (chakrebouddha.FlashFilters): the drop shadow of the balls
 * (mcBalls), the glow of a flashing ball (its blur and strength follow the flash), the glows of the lightning between
 * two chains (mcMagnet) and of the combo multiplier (mcMulti).
 * Flash filters are in stage pixels (not scaled by the clip): a blur of b is b x the stage scale of the game (the root
 * at x2, and the page's own scale) on the screen. A BlurFilter of quality q is q box blurs in a row: a B-spline of
 * degree q - 1 over q x b pixels, sampled here in one pass per axis (at most 31 samples, bilinear).
 */
class FlashFilters {
	// CLEAR_MODES.CLEAR / BLEND of PixiJS (compared with ===: not a Bool)
	public static inline var CLEAR = 1;
	public static inline var BLEND = 0;

	static var pool:Map<String, Array<Filter>> = new Map();

	public static function take(cl:Class<Filter>):Filter {
		var a = pool.get(Type.getClassName(cl));
		if (a != null && a.length > 0)
			return a.pop();
		return Type.createInstance(cl, []);
	}

	public static function release(f:Filter):Void {
		var n = Type.getClassName(Type.getClass(f));
		var a = pool.get(n);
		if (a == null)
			pool.set(n, a = []);
		if (a.indexOf(f) < 0)
			a.push(f);
	}

	public static function clear():Void {
		for (a in pool)
			for (f in a)
				(f : Dynamic).destroy();
		pool = new Map();
	}

	// screen pixels per Flash stage pixel
	public static function scale():Float {
		var r = Game.me != null ? Game.me.root : null;
		var a = r != null ? Math.abs(r.worldTransform.a) : 0;
		return a > 0 ? a : Clip.K;
	}

	// a box of b pixels blurred q times: the weight at x (pixels from the centre)
	static function spline(x:Float, b:Float, q:Int):Float {
		var u = Math.abs(x / b);
		return switch (q) {
			case 1: u <= 0.5 ? 1 : 0;
			case 2: u < 1 ? 1 - u : 0;
			default: u < 0.5 ? 0.75 - u * u : u < 1.5 ? 0.5 * (1.5 - u) * (1.5 - u) : 0;
		}
	}

	// samples of a kernel over `support` pixels: offsets (pixels) and weights (sum 1) into the uniforms of a pass
	public static function kernel(u:Dynamic, support:Float, w:Float->Float):Void {
		var off:js.lib.Float32Array = u.uOff;
		var wt:js.lib.Float32Array = u.uWt;
		var n = Std.int(Math.min(31, Math.max(1, Math.ceil(support))));
		var sum = 0.0;
		for (i in 0...n) {
			var x = (i + 0.5) * support / n - support * 0.5;
			off[i] = x;
			wt[i] = w(x);
			sum += wt[i];
		}
		for (i in 0...n)
			wt[i] = sum > 0 ? wt[i] / sum : 0;
		u.uN = n;
	}

	public static function boxKernel(u:Dynamic, b:Float, q:Int):Void {
		if (b <= 0.01) {
			kernel(u, 0, x -> 1);
			return;
		}
		kernel(u, b * q, x -> spline(x, b, q));
	}

	public static function gaussKernel(u:Dynamic, sigma:Float):Void {
		if (sigma <= 0.01) {
			kernel(u, 0, x -> 1);
			return;
		}
		kernel(u, sigma * 6, x -> Math.exp(-x * x / (2 * sigma * sigma)));
	}

	public static function passUniforms():Dynamic {
		return {
			uOff: new js.lib.Float32Array(32),
			uWt: new js.lib.Float32Array(32),
			uN: 1.0,
			uDir: new js.lib.Float32Array([0, 0]),
		};
	}

	// the texel along one axis of a filter texture
	public static function dir(u:Dynamic, input:RenderTexture, horizontal:Bool):Void {
		var d:js.lib.Float32Array = u.uDir;
		d[0] = horizontal ? 1 / input.baseTexture.realWidth : 0;
		d[1] = horizontal ? 0 : 1 / input.baseTexture.realHeight;
	}

	// the sum of the samples of a kernel along uDir (outside the input: transparent)
	public static var SUM = "
uniform float uOff[32];
uniform float uWt[32];
uniform float uN;
uniform vec2 uDir;
vec4 blurSum(sampler2D tex, vec2 at, vec4 clampRect) {
	vec4 sum = vec4(0.0);
	for (int i = 0; i < 31; i++) {
		if (float(i) >= uN) break;
		vec2 uv = at + uDir * uOff[i];
		if (uv.x < clampRect.x || uv.y < clampRect.y || uv.x > clampRect.z || uv.y > clampRect.w) continue;
		sum += texture2D(tex, uv) * uWt[i];
	}
	return sum;
}
";
}

// one axis of a blur: the picture (premultiplied) summed along uDir
class BlurPass extends Filter {
	public function new() {
		super(null, "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputClamp;
" + FlashFilters.SUM + "
void main(void) {
	gl_FragColor = blurSum(uSampler, vTextureCoord, inputClamp);
}
", FlashFilters.passUniforms());
	}
}

/**
 * GlowFilter (outer, not knockout) / GradientGlowFilter with the same colour at both ends of a linear alpha ramp /
 * DropShadowFilter at distance 0: the alpha of the clip blurred (quality q), times the strength, clamped, in the
 * colour, drawn under the clip.
 */
class FlashGlow extends Filter {
	var blur:Float = 0;
	var quality:Int = 1;
	var h:BlurPass;

	static var copy:Filter;

	public function new() {
		var u = FlashFilters.passUniforms();
		u.uStrength = 1.0;
		u.uColor = new js.lib.Float32Array([1, 1, 1]);
		// the vertical pass: the glow alone (the clip is drawn over it after, see apply)
		super(null, "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputClamp;
uniform float uStrength;
uniform vec3 uColor;
" + FlashFilters.SUM + "
void main(void) {
	float g = clamp(blurSum(uSampler, vTextureCoord, inputClamp).a * uStrength, 0.0, 1.0);
	gl_FragColor = vec4(uColor * g, g);
}
", u);
		h = new BlurPass();
		if (copy == null)
			copy = new Filter();
	}

	public function set(blur:Float, strength:Float, color:Int, quality:Int):Void {
		this.blur = blur;
		this.quality = quality;
		uniforms.uStrength = strength;
		var c:js.lib.Float32Array = uniforms.uColor;
		c[0] = ((color >> 16) & 0xFF) / 255;
		c[1] = ((color >> 8) & 0xFF) / 255;
		c[2] = (color & 0xFF) / 255;
		padding = Math.ceil(blur * quality * FlashFilters.scale() / 2) + 2;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		padding = Math.ceil(blur * quality * FlashFilters.scale() / 2) + 2;
		if (uniforms.uStrength <= 0) {
			// (no glow: the picture as it is)
			filterManager.applyFilter(FlashCx.copy(), input, output, clear);
			return;
		}
		var b = blur * FlashFilters.scale() * input.baseTexture.resolution;
		FlashFilters.boxKernel(h.uniforms, b, quality);
		FlashFilters.dir(h.uniforms, input, true);
		var tmp = filterManager.getFilterTexture();
		filterManager.applyFilter(h, input, tmp, cast FlashFilters.CLEAR);
		FlashFilters.boxKernel(uniforms, b, quality);
		// (the texel of the texture sampled: a pooled texture is not always the size of the input)
		FlashFilters.dir(uniforms, tmp, false);
		filterManager.applyFilter(this, tmp, output, clear);
		filterManager.returnFilterTexture(tmp);
		// the clip over its glow (normal blending: src + glow * (1 - src.a), Flash's outer glow)
		filterManager.applyFilter(copy, input, output, cast FlashFilters.BLEND);
	}
}

/**
 * DropShadowFilter (not inner, not knockout, not hideObject): the alpha of the clip blurred (quality q), times the
 * strength, clamped, times the alpha of the shadow, in its colour, moved by `distance` stage pixels at `angle` degrees,
 * drawn under the clip. (mcBalls: DropShadowFilter(4, 135, 0, 0.5, 4, 4) of Game.new)
 */
class FlashShadow extends Filter {
	var blur:Float = 0;
	var quality:Int = 1;
	var dx:Float = 0;
	var dy:Float = 0;
	var h:BlurPass;

	static var copy:Filter;

	public function new() {
		var u = FlashFilters.passUniforms();
		u.uStrength = 1.0;
		u.uAlpha = 1.0;
		u.uColor = new js.lib.Float32Array([0, 0, 0]);
		u.uShift = new js.lib.Float32Array([0, 0]);
		// the vertical pass: the shadow alone, sampled `uShift` (texture coordinates) before (the clip is drawn over it after)
		super(null, "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputClamp;
uniform float uStrength;
uniform float uAlpha;
uniform vec3 uColor;
uniform vec2 uShift;
" + FlashFilters.SUM + "
void main(void) {
	float g = clamp(blurSum(uSampler, vTextureCoord - uShift, inputClamp).a * uStrength, 0.0, 1.0) * uAlpha;
	gl_FragColor = vec4(uColor * g, g);
}
", u);
		h = new BlurPass();
		if (copy == null)
			copy = new Filter();
	}

	public function set(distance:Float, angle:Float, color:Int, alpha:Float, blur:Float, strength:Float, quality:Int):Void {
		this.blur = blur;
		this.quality = quality;
		var a = angle * Math.PI / 180;
		dx = Math.cos(a) * distance;
		dy = Math.sin(a) * distance;
		uniforms.uStrength = strength;
		uniforms.uAlpha = alpha;
		var c:js.lib.Float32Array = uniforms.uColor;
		c[0] = ((color >> 16) & 0xFF) / 255;
		c[1] = ((color >> 8) & 0xFF) / 255;
		c[2] = (color & 0xFF) / 255;
		pad();
	}

	function pad() {
		var k = FlashFilters.scale();
		padding = Math.ceil((blur * quality / 2 + Math.max(Math.abs(dx), Math.abs(dy))) * k) + 2;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		pad();
		var k = FlashFilters.scale() * input.baseTexture.resolution;
		var b = blur * k;
		FlashFilters.boxKernel(h.uniforms, b, quality);
		FlashFilters.dir(h.uniforms, input, true);
		var tmp = filterManager.getFilterTexture();
		filterManager.applyFilter(h, input, tmp, cast FlashFilters.CLEAR);
		FlashFilters.boxKernel(uniforms, b, quality);
		FlashFilters.dir(uniforms, tmp, false);
		var sh:js.lib.Float32Array = uniforms.uShift;
		sh[0] = dx * k / tmp.baseTexture.realWidth;
		sh[1] = dy * k / tmp.baseTexture.realHeight;
		filterManager.applyFilter(this, tmp, output, clear);
		filterManager.returnFilterTexture(tmp);
		// the clip over its shadow
		filterManager.applyFilter(copy, input, output, cast FlashFilters.BLEND);
	}
}

// BlurFilter (quality q: q boxes of blur x blur stage pixels), on both axes
class FlashBoxBlur extends Filter {
	var blur:Float = 0;
	var quality:Int = 1;
	var h:BlurPass;

	public function new() {
		super(null, "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputClamp;
" + FlashFilters.SUM + "
void main(void) {
	gl_FragColor = blurSum(uSampler, vTextureCoord, inputClamp);
}
", FlashFilters.passUniforms());
		h = new BlurPass();
	}

	public function set(blur:Float, quality:Int):Void {
		this.blur = blur;
		this.quality = quality;
		padding = Math.ceil(blur * quality * FlashFilters.scale() / 2) + 2;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		padding = Math.ceil(blur * quality * FlashFilters.scale() / 2) + 2;
		var b = blur * FlashFilters.scale() * input.baseTexture.resolution;
		FlashFilters.boxKernel(h.uniforms, b, quality);
		FlashFilters.dir(h.uniforms, input, true);
		var tmp = filterManager.getFilterTexture();
		filterManager.applyFilter(h, input, tmp, cast FlashFilters.CLEAR);
		FlashFilters.boxKernel(uniforms, b, quality);
		FlashFilters.dir(uniforms, tmp, false);
		filterManager.applyFilter(this, tmp, output, clear);
		filterManager.returnFilterTexture(tmp);
	}
}

// flash.geom.ColorTransform on red, green, blue (multipliers, offsets 0..255), on the colours without the alpha
class FlashCx extends Filter {
	static var plain:FlashCx;

	// a colour transform that changes nothing (a filter of strength 0)
	public static function copy():FlashCx {
		if (plain == null) {
			plain = new FlashCx();
			plain.set([1, 1, 1, 0, 0, 0]);
		}
		return plain;
	}

	public function new() {
		super(null, "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec3 uMult;
uniform vec3 uAdd;
void main(void) {
	vec4 c = texture2D(uSampler, vTextureCoord);
	if (c.a > 0.0) {
		vec3 rgb = clamp(c.rgb / c.a * uMult + uAdd, 0.0, 1.0);
		c.rgb = rgb * c.a;
	}
	gl_FragColor = c;
}
", {uMult: new js.lib.Float32Array([1, 1, 1]), uAdd: new js.lib.Float32Array([0, 0, 0])});
	}

	// [rMult, gMult, bMult, rOffset, gOffset, bOffset]
	public function set(cx:Array<Float>):Void {
		var m:js.lib.Float32Array = uniforms.uMult;
		var a:js.lib.Float32Array = uniforms.uAdd;
		for (i in 0...3) {
			m[i] = cx[i];
			a[i] = cx[i + 3] / 255;
		}
	}
}
