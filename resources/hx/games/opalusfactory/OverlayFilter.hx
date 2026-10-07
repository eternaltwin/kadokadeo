package opalusfactory;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

/**
 * wallUp's tapi: a grey gradient placed with BlurFilter(29, 2) and blendMode "overlay" over everything under DP_INTER
 * (the roll, the holes, the hero): Flash's overlay (multiply where the picture under it is darker than 50 % grey,
 * screen where it is lighter), premultiplied (W3C separable blend: Cs (1 - ab) + Cb (1 - as) + as ab B(cb, cs)). The
 * planes under DP_INTER are drawn together, then this filter blends the tapi picture (blurred by the asset pipeline)
 * over them.
 */
class OverlayFilter extends Filter {
	var tex:Texture;

	public function new() {
		tex = Tex.get("tapi")[0];
		super(null, FRAG, {
			uTapi: tex,
			uMap: [0.0, 0.0, 0.0, 0.0],
			uOrig: [1.0, 1.0],
			uTrim: [0.0, 0.0, 1.0, 1.0],
			uFrame: [0.0, 0.0],
			uBase: [1.0, 1.0],
		});
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var r = Game.me != null ? Game.me.stageRoot() : null;
		if (r != null) {
			// screen (CSS pixels) -> Flash pixels -> the tapi picture (0..1)
			var wt = r.worldTransform;
			var t = Data.TAPI;
			var sx = 1 / (wt.a * t[2]);
			var sy = 1 / (wt.d * t[3]);
			uniforms.uMap = [sx, sy, -wt.tx * sx - t[0] / t[2], -wt.ty * sy - t[1] / t[3]];
		}
		var o = tex.orig;
		var tr:Dynamic = tex.trim;
		uniforms.uOrig = [o.width, o.height];
		uniforms.uTrim = tr != null ? [tr.x, tr.y, tr.width, tr.height] : [0.0, 0.0, o.width, o.height];
		uniforms.uFrame = [tex.frame.x, tex.frame.y];
		uniforms.uBase = [tex.baseTexture.width, tex.baseTexture.height];
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "precision highp float;
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform sampler2D uTapi;
uniform vec4 inputSize;
uniform vec4 outputFrame;
uniform vec4 uMap;
uniform vec2 uOrig;
uniform vec4 uTrim;
uniform vec2 uFrame;
uniform vec2 uBase;

void main(void) {
	vec4 b = texture2D(uSampler, vTextureCoord);
	vec2 screen = vTextureCoord * inputSize.xy + outputFrame.xy;
	vec2 t = screen * uMap.xy + uMap.zw;
	vec2 q = t * uOrig - uTrim.xy;
	if (t.x < 0.0 || t.y < 0.0 || t.x > 1.0 || t.y > 1.0 || q.x < 0.0 || q.y < 0.0 || q.x > uTrim.z || q.y > uTrim.w) {
		gl_FragColor = b;
		return;
	}
	vec4 s = texture2D(uTapi, (uFrame + q) / uBase);
	float as = s.a;
	float ab = b.a;
	vec3 cs = as > 0.0 ? s.rgb / as : vec3(0.0);
	vec3 cb = ab > 0.0 ? b.rgb / ab : vec3(0.0);
	vec3 mul = 2.0 * cs * cb;
	vec3 scr = 1.0 - 2.0 * (1.0 - cs) * (1.0 - cb);
	vec3 bl = mix(mul, scr, step(0.5000001, cb));
	gl_FragColor = vec4(s.rgb * (1.0 - ab) + b.rgb * (1.0 - as) + as * ab * bl, as + ab * (1.0 - as));
}
";
}
