package kanjigaiden;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * Flash 8 BlurFilter at run time: `passes` boxes of blurX x blurY stage pixels (the quality of the filter) on the colour
 * and the alpha, in stage pixels (not scaled by the clip: blurX x the stage scale of the game). One pass per axis, the n
 * boxes as one kernel (FlashGlow.BSPLINE), sampled at most 32 times with the linear filtering of the texture.
 * Kanji Gaiden tweens blurs on its timelines: the throw of the hero's arm (up to 44 pixels), the rising score, the
 * banana flying off a dead monkey (Clip `bf`).
 */
class FlashBlur extends Filter {
	static inline var MAXN = 32;

	var blurX:Float;
	var blurY:Float;
	var passes:Int;

	// in the filters of its clip (Clip.setBlur)
	public var on:Bool = false;

	public function new(blurX:Float, blurY:Float, passes:Int = 1) {
		super(null, FRAG, {
			uDir: [1.0, 0.0],
			uBox: 0.0,
			uN: 1.0,
			uPasses: 1.0,
			uTexel: [0.0, 0.0],
		});
		set(blurX, blurY, passes);
	}

	public function set(blurX:Float, blurY:Float, passes:Int) {
		this.blurX = blurX;
		this.blurY = blurY;
		this.passes = passes < 1 ? 1 : (passes > 3 ? 3 : passes);
		padding = pad();
	}

	inline function pad():Int {
		return Math.ceil(Math.max(blurX, blurY) * passes * FlashGlow.scale() / 2) + 2;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var k = FlashGlow.scale() * input.baseTexture.resolution;
		var bx = blurX * k;
		var by = blurY * k;
		padding = pad();
		uniforms.uPasses = passes;
		uniforms.uTexel = [1 / input.baseTexture.realWidth, 1 / input.baseTexture.realHeight];
		// (a box narrower than a pixel does nothing: Flash rounds the box to whole pixels)
		var doX = bx >= 1.5;
		var doY = by >= 1.5;
		if (doX && doY) {
			var tmp = filterManager.getFilterTexture();
			axis(1, 0, bx);
			filterManager.applyFilter(this, input, tmp, cast 1); // CLEAR_MODES.CLEAR
			axis(0, 1, by);
			filterManager.applyFilter(this, tmp, output, clear);
			filterManager.returnFilterTexture(tmp);
		} else if (doX || doY) {
			if (doX)
				axis(1, 0, bx);
			else
				axis(0, 1, by);
			filterManager.applyFilter(this, input, output, clear);
		} else {
			axis(1, 0, 0);
			filterManager.applyFilter(this, input, output, clear);
		}
	}

	inline function axis(dx:Float, dy:Float, box:Float) {
		uniforms.uDir = [dx, dy];
		uniforms.uBox = box;
		uniforms.uN = Math.min(MAXN, Math.max(1, Math.ceil(box * passes)));
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 uTexel;
uniform vec4 inputClamp;
uniform vec2 uDir;
uniform float uBox;
uniform float uN;
uniform float uPasses;
" + FlashGlow.BSPLINE + "
void main(void) {
	if (uBox <= 0.0) {
		gl_FragColor = texture2D(uSampler, vTextureCoord);
		return;
	}
	vec4 sum = vec4(0.0);
	float wsum = 0.0;
	float span = uBox * uPasses;
	for (int i = 0; i < 32; i++) {
		if (float(i) >= uN) break;
		float o = (float(i) + 0.5) * span / uN - span * 0.5;
		float w = bspline(o / uBox, uPasses);
		vec2 uv = clamp(vTextureCoord + uDir * o * uTexel, inputClamp.xy, inputClamp.zw);
		sum += texture2D(uSampler, uv) * w;
		wsum += w;
	}
	gl_FragColor = sum / max(wsum, 1e-6);
}
";
}
