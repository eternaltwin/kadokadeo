package ktrain;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * Flash 8 BlurFilter (quality 1) at run time, in stage pixels (Flash filters are not scaled by the clip: the root at x2
 * and the page's own scale only): a box of blurX x blurY pixels (the box of swfrender.box_blur: taps -w/2 .. w/2 - 1).
 *
 * Several blurs on one clip: Filt.blur (Phys fadeType 4) pushes a new BlurFilter on the clip's list every frame of the
 * fade, Flash then blurs the clip once per filter. Their sum is drawn as one gaussian of the same variance (the sum of
 * the boxes' variances): up to 13 boxes of up to 32 screen pixels would need 13 passes per clip.
 */
class FlashBlur extends Filter {
	static inline var MAXT = 96;

	var bx:Array<Float>;
	var by:Array<Float>;

	public function new(bx:Array<Float>, by:Array<Float>) {
		super(null, FRAG, {
			uTexel: [0.0, 0.0],
			uDir: [1.0, 0.0],
			uFrom: 0.0,
			uTo: 0.0,
			uSigma: 0.0,
		});
		this.bx = bx;
		this.by = by;
		padding = Math.ceil(Math.max(extent(bx), extent(by)) * scale()) + 2;
	}

	// half width of the blur (stage pixels)
	static function extent(l:Array<Float>):Float {
		if (l.length == 1)
			return l[0] / 2 + 1;
		var s = 0.0;
		for (w in l)
			s += w;
		return Math.min(MAXT, Math.sqrt(variance(l, 1)) * 3);
	}

	static function variance(l:Array<Float>, k:Float):Float {
		var v = 0.0;
		for (w in l) {
			var n = Math.round(w * k);
			if (n >= 2)
				v += (n * n - 1) / 12;
		}
		return v;
	}

	// screen pixels per Flash stage pixel
	static function scale():Float {
		var r = Game.me_ != null ? Game.me_.stageRoot() : null;
		var a = r != null ? Math.abs(r.worldTransform.a) : 0;
		return a > 0 ? a : Clip.K;
	}

	// one pass along an axis: false when that axis is not blurred
	function setAxis(l:Array<Float>, k:Float):Bool {
		var w = 0;
		var any = false;
		for (b in l)
			if (Math.round(b * k) >= 2)
				any = true;
		if (!any)
			return false;
		if (l.length == 1) {
			var n = Math.round(l[0] * k);
			var lo = Std.int(n / 2);
			uniforms.uFrom = -lo;
			uniforms.uTo = n - lo - 1;
			uniforms.uSigma = 0.0;
		} else {
			var s = Math.sqrt(variance(l, k));
			var r = Math.min(MAXT, Math.ceil(s * 3));
			uniforms.uFrom = -r;
			uniforms.uTo = r;
			uniforms.uSigma = s;
		}
		return true;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var k = scale() * input.baseTexture.resolution;
		uniforms.uTexel = [1 / input.baseTexture.realWidth, 1 / input.baseTexture.realHeight];
		padding = Math.ceil(Math.max(extent(bx), extent(by)) * scale()) + 2;
		var doX = setAxis(bx, k);
		var fx = [uniforms.uFrom, uniforms.uTo, uniforms.uSigma];
		var doY = setAxis(by, k);
		if (doX && doY) {
			var tmp = filterManager.getFilterTexture(input);
			var fy = [uniforms.uFrom, uniforms.uTo, uniforms.uSigma];
			uniforms.uFrom = fx[0];
			uniforms.uTo = fx[1];
			uniforms.uSigma = fx[2];
			uniforms.uDir = [1.0, 0.0];
			filterManager.applyFilter(this, input, tmp, true);
			uniforms.uFrom = fy[0];
			uniforms.uTo = fy[1];
			uniforms.uSigma = fy[2];
			uniforms.uDir = [0.0, 1.0];
			filterManager.applyFilter(this, tmp, output, clear);
			filterManager.returnFilterTexture(tmp);
			return;
		}
		if (doX) {
			uniforms.uFrom = fx[0];
			uniforms.uTo = fx[1];
			uniforms.uSigma = fx[2];
			uniforms.uDir = [1.0, 0.0];
		} else if (doY) {
			uniforms.uDir = [0.0, 1.0];
		} else {
			uniforms.uFrom = 0.0;
			uniforms.uTo = 0.0;
			uniforms.uSigma = 0.0;
		}
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 uTexel;
uniform vec4 inputClamp;
uniform vec2 uDir;
uniform float uFrom;
uniform float uTo;
uniform float uSigma;

void main(void) {
	vec4 sum = vec4(0.0);
	float wsum = 0.0;
	for (int i = -96; i <= 96; i++) {
		float t = float(i);
		if (t < uFrom) continue;
		if (t > uTo) break;
		float w = uSigma > 0.0 ? exp(-t * t / (2.0 * uSigma * uSigma)) : 1.0;
		vec2 uv = clamp(vTextureCoord + uDir * t * uTexel, inputClamp.xy, inputClamp.zw);
		sum += texture2D(uSampler, uv) * w;
		wsum += w;
	}
	gl_FragColor = sum / wsum;
}
";
}
