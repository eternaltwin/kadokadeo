package happyptitank;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * The filters of the timelines of the end animations (TheEnd, YouDie): Flash's BlurFilter and GlowFilter (outer).
 * Flash blurs by boxes of blurX x blurY stage pixels (not scaled by the clip), `passes` times (the quality); here a
 * box is two passes (horizontal then vertical) of at most 16 bilinear samples spread over it. The glow is the alpha
 * blurred the same way, multiplied by the strength, in the glow colour, under the picture.
 */
#if debug
@:expose('HptFlashFilter')
#end
class FlashFilter extends Filter {
	static inline var MAXN = 16;
	static var copy:Filter = null;

	var blurX:Float;
	var blurY:Float;
	var passes:Int;
	var glow:Bool;
	var finalPass:Filter;

	public function new(blurX:Float, blurY:Float, passes:Int, glow:Bool, color:Int = 0, strength:Float = 1) {
		super(null, BOX, {uStep: [0.0, 0.0], uN: 1.0});
		this.blurX = blurX;
		this.blurY = blurY;
		this.passes = passes < 1 ? 1 : passes;
		this.glow = glow;
		if (glow)
			finalPass = new Filter(null, GLOW, {
				uOrig: null,
				uStrength: strength,
				uColor: [((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255, 1.0],
			});
		padding = pad();
	}

	public function set(blurX:Float, blurY:Float, passes:Int, color:Int, strength:Float) {
		this.blurX = blurX;
		this.blurY = blurY;
		this.passes = passes < 1 ? 1 : passes;
		if (finalPass != null) {
			finalPass.uniforms.uStrength = strength;
			finalPass.uniforms.uColor = [((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255, 1.0];
		}
		padding = pad();
	}

	function pad():Int {
		return Math.ceil(Math.max(blurX, blurY) * scale() * passes / 2) + 2;
	}

	// screen pixels per Flash stage pixel
	static function scale():Float {
		var r = Game.instance != null ? Game.instance.stageView() : null;
		var a = r != null ? Math.abs(r.worldTransform.a) : 0;
		return a > 0 ? a : Game.K;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var k = scale() * input.baseTexture.resolution;
		var bx = blurX * k;
		var by = blurY * k;
		var tw = 1 / input.baseTexture.realWidth;
		var th = 1 / input.baseTexture.realHeight;
		var src = input;
		var tmp = filterManager.getFilterTexture();
		var tmp2 = filterManager.getFilterTexture();
		var steps:Array<{w:Float, sx:Float, sy:Float}> = [];
		for (p in 0...passes) {
			if (bx >= 2)
				steps.push({w: bx, sx: tw, sy: 0});
			if (by >= 2)
				steps.push({w: by, sx: 0, sy: th});
		}
		var last:RenderTexture = input;
		var i = 0;
		for (s in steps) {
			var n = Math.min(MAXN, Math.ceil(s.w));
			uniforms.uN = n;
			// the n samples spread over the box of w texels: offsets (j + 0.5) * w / n - w / 2
			uniforms.uStep = [s.sx * s.w / n, s.sy * s.w / n];
			var dst = (i % 2 == 0) ? tmp : tmp2;
			var isLast = i == steps.length - 1 && !glow;
			// (PIXI 6 takes a CLEAR_MODES value: 1 = clear the pooled texture, which keeps its old pixels otherwise)
			filterManager.applyFilter(this, last, isLast ? output : dst, isLast ? clear : untyped 1);
			last = dst;
			i++;
		}
		if (steps.length == 0 && !glow) {
			if (copy == null)
				copy = new Filter();
			filterManager.applyFilter(copy, input, output, clear);
		}
		if (glow) {
			finalPass.uniforms.uOrig = input;
			filterManager.applyFilter(finalPass, last, output, clear);
		}
		filterManager.returnFilterTexture(tmp);
		filterManager.returnFilterTexture(tmp2);
	}

	static var BOX = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputClamp;
uniform vec2 uStep;
uniform float uN;

void main(void) {
	vec4 sum = vec4(0.0);
	for (int j = 0; j < 16; j++) {
		if (float(j) >= uN) break;
		vec2 uv = clamp(vTextureCoord + uStep * (float(j) + 0.5 - uN * 0.5), inputClamp.xy, inputClamp.zw);
		sum += texture2D(uSampler, uv);
	}
	gl_FragColor = sum / uN;
}
";

	static var GLOW = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform sampler2D uOrig;
uniform float uStrength;
uniform vec4 uColor;

void main(void) {
	vec4 src = texture2D(uOrig, vTextureCoord);
	float g = clamp(texture2D(uSampler, vTextureCoord).a * uStrength, 0.0, 1.0) * uColor.a;
	gl_FragColor = src + vec4(uColor.rgb * g, g) * (1.0 - src.a);
}
";
}
