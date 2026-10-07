package kanjigaiden;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * Flash 8 GlowFilter (outer) at run time: the alpha of the clip blurred by `passes` boxes of blurX x blurY stage pixels
 * (the quality of the filter), multiplied by the strength, in the glow colour, drawn under the clip. Flash filters are
 * in stage pixels (not scaled by the clip): the box is blurX x the stage scale of the game (the root at x2, and the
 * page's own scale). (cosmocrash.FlashGlow, with the passes: n boxes in a row are one kernel, the B-spline of degree
 * n - 1 over n boxes, sampled at most 16 x 16 times.) Kanji Gaiden: the brown outline of the monkeys (2 x 2, quality 3),
 * around the monkey and the banana it holds.
 */
class FlashGlow extends Filter {
	static inline var MAXN = 16;

	var blurX:Float;
	var blurY:Float;
	var passes:Int;

	public function new(blurX:Float, blurY:Float, strength:Float, color:Int, alpha:Float = 1, passes:Int = 1) {
		super(null, FRAG, {
			uBox: [0.0, 0.0],
			uTexel: [0.0, 0.0],
			uN: [1.0, 1.0],
			uPasses: 1.0,
			uStrength: strength,
			uColor: [((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255, alpha],
		});
		this.blurX = blurX;
		this.blurY = blurY;
		this.passes = passes < 1 ? 1 : (passes > 3 ? 3 : passes);
		padding = pad();
	}

	inline function pad():Int {
		return Math.ceil(Math.max(blurX, blurY) * passes * scale() / 2) + 2;
	}

	// screen pixels per Flash stage pixel
	public static function scale():Float {
		var r = Game.me != null ? Game.me.stageRoot() : null;
		var a = r != null ? Math.abs(r.worldTransform.a) : 0;
		return a > 0 ? a : Clip.K;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var k = scale() * input.baseTexture.resolution;
		var bx = blurX * k;
		var by = blurY * k;
		uniforms.uBox = [bx, by];
		uniforms.uPasses = passes;
		// (not inputSize: highp in PIXI's vertex shader, a uniform shared with this mediump shader would not link)
		uniforms.uTexel = [1 / input.baseTexture.realWidth, 1 / input.baseTexture.realHeight];
		uniforms.uN = [
			Math.min(MAXN, Math.max(1, Math.ceil(bx * passes))),
			Math.min(MAXN, Math.max(1, Math.ceil(by * passes)))
		];
		padding = pad();
		filterManager.applyFilter(this, input, output, clear);
	}

	// the kernel of n boxes of width 1, at t (box widths from its centre)
	public static var BSPLINE = "float bspline(float t, float n) {
	t = abs(t);
	if (n < 1.5) return t < 0.5 ? 1.0 : 0.0;
	if (n < 2.5) return max(0.0, 1.0 - t);
	if (t < 0.5) return 0.75 - t * t;
	if (t < 1.5) return 0.5 * (1.5 - t) * (1.5 - t);
	return 0.0;
}
";

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 uTexel;
uniform vec4 inputClamp;
uniform vec2 uBox;
uniform vec2 uN;
uniform float uPasses;
uniform float uStrength;
uniform vec4 uColor;
" + BSPLINE + "
void main(void) {
	vec4 src = texture2D(uSampler, vTextureCoord);
	float sum = 0.0;
	float wsum = 0.0;
	vec2 span = uBox * uPasses;
	for (int j = 0; j < 16; j++) {
		if (float(j) >= uN.y) break;
		float oy = (float(j) + 0.5) * span.y / uN.y - span.y * 0.5;
		float wy = uBox.y > 0.0 ? bspline(oy / uBox.y, uPasses) : 1.0;
		for (int i = 0; i < 16; i++) {
			if (float(i) >= uN.x) break;
			float ox = (float(i) + 0.5) * span.x / uN.x - span.x * 0.5;
			float w = wy * (uBox.x > 0.0 ? bspline(ox / uBox.x, uPasses) : 1.0);
			vec2 uv = clamp(vTextureCoord + vec2(ox, oy) * uTexel, inputClamp.xy, inputClamp.zw);
			sum += texture2D(uSampler, uv).a * w;
			wsum += w;
		}
	}
	float g = clamp(sum / max(wsum, 1e-6) * uStrength, 0.0, 1.0) * uColor.a;
	gl_FragColor = src + vec4(uColor.rgb * g, g) * (1.0 - src.a);
}
";
}
