package cyclopean;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * What Game.main puts on mcInter in the last 400 frames: a Flash 8 GlowFilter (white, blurX = blurY = inc, strength
 * 2, quality 1) and Cs.setPercentColor(mcInter, inc * 4, 0xFFFFFF) (multipliers int(100 - prc) %, offsets
 * int(prc / 100 * 255)), one shader. The glow is the alpha of the clip blurred by a box of blur x blur stage pixels
 * (Flash filters are in stage pixels: x the scale of the game on the screen), averaged with at most 16 x 16 samples,
 * drawn under the clip (the FlashGlow of the Schizo Fuzz port).
 */
class InterGlow extends Filter {
	static inline var MAXN = 16;

	public var blur:Float = 0;

	public function new() {
		super(null, FRAG, {
			uBox: [0.0, 0.0],
			uTexel: [0.0, 0.0],
			uN: [1.0, 1.0],
			uStrength: 2.0,
			uWhite: [1.0, 0.0],
		});
		padding = 24;
	}

	// Cs.setPercentColor(mc, prc, 0xFFFFFF)
	public function setPercent(prc:Float):Void {
		var m = Std.int(100 - prc) / 100;
		var o = Std.int(prc / 100 * 255) / 255;
		uniforms.uWhite = [m, o];
	}

	// screen pixels per Flash stage pixel
	static function scale():Float {
		var r = Game.me != null ? Game.me.root.spr : null;
		var a = r != null ? Math.abs(r.worldTransform.a) : 0;
		return a > 0 ? a : Game.K;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var k = scale() * input.baseTexture.resolution;
		var b = blur * k;
		uniforms.uBox = [b, b];
		uniforms.uTexel = [1 / input.baseTexture.realWidth, 1 / input.baseTexture.realHeight];
		var n = Math.min(MAXN, Math.max(1, Math.ceil(b)));
		uniforms.uN = [n, n];
		padding = Math.ceil(10 * scale() / 2) + 2;
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 uTexel;
uniform vec4 inputClamp;
uniform vec2 uBox;
uniform vec2 uN;
uniform float uStrength;
uniform vec2 uWhite;

void main(void) {
	vec4 src = texture2D(uSampler, vTextureCoord);
	// colour transform on the premultiplied colour: c * m + o * a
	src.rgb = src.rgb * uWhite.x + uWhite.y * src.a;
	float sum = 0.0;
	for (int j = 0; j < 16; j++) {
		if (float(j) >= uN.y) break;
		float oy = (float(j) + 0.5) * uBox.y / uN.y - uBox.y * 0.5;
		for (int i = 0; i < 16; i++) {
			if (float(i) >= uN.x) break;
			float ox = (float(i) + 0.5) * uBox.x / uN.x - uBox.x * 0.5;
			vec2 uv = clamp(vTextureCoord + vec2(ox, oy) * uTexel, inputClamp.xy, inputClamp.zw);
			sum += texture2D(uSampler, uv).a;
		}
	}
	float g = clamp(sum / (uN.x * uN.y) * uStrength, 0.0, 1.0);
	gl_FragColor = src + vec4(g, g, g, g) * (1.0 - src.a);
}
";
}
