package oursouinvader;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * Flash 8 BlurFilter(blurX, 0) quality 1 at run time: a horizontal box of blurX stage pixels (the "VAGUE n" title,
 * Game.initStep / main: from 100 down to 0 as it comes in, then up to 200 as it goes). Flash filters are in stage
 * pixels: the box is blurX x the stage scale of the game (the root at x2, and the page's own scale), up to 340 screen
 * pixels; it is averaged with up to 256 bilinear samples evenly spread over the box (at most 1.5 pixels apart).
 */
class BoxBlurX extends Filter {
	static inline var MAXN = 256;

	public var blurX:Float;

	public function new(blurX:Float) {
		super(null, FRAG, {
			uBox: 0.0,
			uTexel: 0.0,
			uN: 1.0,
		});
		this.blurX = blurX;
		padding = Math.ceil(blurX * FlashGlow.scale() / 2) + 2;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var bx = blurX * FlashGlow.scale() * input.baseTexture.resolution;
		// (Flash: a box narrower than 2 pixels does nothing)
		if (bx < 2)
			bx = 0;
		uniforms.uBox = bx;
		uniforms.uTexel = 1 / input.baseTexture.realWidth;
		uniforms.uN = Math.min(MAXN, Math.max(1, Math.ceil(bx / 1.5)));
		padding = Math.ceil(blurX * FlashGlow.scale() / 2) + 2;
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 inputClamp;
uniform float uTexel;
uniform float uBox;
uniform float uN;

void main(void) {
	vec4 sum = vec4(0.0);
	for (int i = 0; i < 256; i++) {
		if (float(i) >= uN) break;
		float ox = (float(i) + 0.5) * uBox / uN - uBox * 0.5;
		vec2 uv = vTextureCoord + vec2(ox * uTexel, 0.0);
		// outside the picture is transparent
		float inside = step(inputClamp.x, uv.x) * step(uv.x, inputClamp.z);
		sum += texture2D(uSampler, clamp(uv, inputClamp.xy, inputClamp.zw)) * inside;
	}
	gl_FragColor = sum / uN;
}
";
}
