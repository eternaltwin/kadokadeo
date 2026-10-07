package opalusfactory;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * Flash 8 inner GlowFilter (quality 1) at run time: Filt.glow(hole, 40, strength, 0xFFFFFF, true) of Game.updateGlow,
 * the holes lit when coins fall in. The alpha of the clip blurred by a box of blur x blur stage pixels; the glow colour
 * at alpha clamp((1 - blurred alpha) * strength) is drawn on the clip where it is opaque. Flash filters are in stage
 * pixels (not scaled by the clip): the box is blur x the stage scale of the game (the root at x2, and the page's own
 * scale), averaged with at most 16 x 16 samples (bilinear: an even spread over the box). (cosmocrash.FlashGlow, inner)
 */
class FlashGlow extends Filter {
	static inline var MAXN = 16;

	var blur:Float;

	public function new(blur:Float, strength:Float, color:Int) {
		super(null, FRAG, {
			uBox: [0.0, 0.0],
			uTexel: [0.0, 0.0],
			uN: [1.0, 1.0],
			uStrength: strength,
			uColor: [((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255],
		});
		this.blur = blur;
		// (an inner glow draws nothing outside the clip; the box reads transparent pixels around it)
		padding = Math.ceil(blur * scale() / 2) + 2;
	}

	public function setStrength(s:Float) {
		uniforms.uStrength = s;
	}

	// screen pixels per Flash stage pixel
	static function scale():Float {
		var r = Game.me != null ? Game.me.stageRoot() : null;
		var a = r != null ? Math.abs(r.worldTransform.a) : 0;
		return a > 0 ? a : Clip.K;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var k = scale() * input.baseTexture.resolution;
		var b = blur * k;
		uniforms.uBox = [b, b];
		// (not inputSize: highp in PIXI's vertex shader, a uniform shared with this mediump shader would not link)
		uniforms.uTexel = [1 / input.baseTexture.realWidth, 1 / input.baseTexture.realHeight];
		var n = Math.min(MAXN, Math.max(1, Math.ceil(b)));
		uniforms.uN = [n, n];
		padding = Math.ceil(blur * scale() / 2) + 2;
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 uTexel;
uniform vec4 inputClamp;
uniform vec2 uBox;
uniform vec2 uN;
uniform float uStrength;
uniform vec3 uColor;

void main(void) {
	vec4 src = texture2D(uSampler, vTextureCoord);
	if (src.a <= 0.0) {
		gl_FragColor = src;
		return;
	}
	float sum = 0.0;
	for (int j = 0; j < 16; j++) {
		if (float(j) >= uN.y) break;
		float oy = (float(j) + 0.5) * uBox.y / uN.y - uBox.y * 0.5;
		for (int i = 0; i < 16; i++) {
			if (float(i) >= uN.x) break;
			float ox = (float(i) + 0.5) * uBox.x / uN.x - uBox.x * 0.5;
			vec2 uv = vTextureCoord + vec2(ox, oy) * uTexel;
			// (outside the clip: transparent)
			float a = (uv.x < inputClamp.x || uv.y < inputClamp.y || uv.x > inputClamp.z || uv.y > inputClamp.w) ? 0.0 : texture2D(uSampler, uv).a;
			sum += a;
		}
	}
	float g = clamp((1.0 - sum / (uN.x * uN.y)) * uStrength, 0.0, 1.0);
	gl_FragColor = vec4(src.rgb * (1.0 - g) + uColor * g * src.a, src.a);
}
";
}
