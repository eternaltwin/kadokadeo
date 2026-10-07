package happyptitank;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;
import pixi.core.sprites.Sprite as PSprite;

/**
 * A mask of a timeline (clipDepth: the rotating half disc and the arc of Rainbow1): the children it masks, drawn
 * through the alpha of the mask's picture. Each pixel of the group goes through the inverse of the world matrix of
 * the mask's picture to its texture (frame and trim of the sheet), outside of it the group is hidden. (The mask's
 * picture itself is not drawn: renderable false, its transform still updated with the tree.)
 */
class MaskFilter extends Filter {
	var mask:PSprite;

	public function new(mask:PSprite) {
		super(null, FRAG, {
			uMask: mask.texture,
			uRow0: [1.0, 0.0, 0.0],
			uRow1: [0.0, 1.0, 0.0],
			uFrame: [0.0, 0.0, 1.0, 1.0],
			uAlpha: 1.0,
		});
		this.mask = mask;
		mask.renderable = false;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var t = mask.texture;
		var bt = t.baseTexture;
		var w = mask.worldTransform;
		// world -> local of the picture (a x + c y + tx)
		var det = w.a * w.d - w.b * w.c;
		var ia = w.d / det;
		var ib = -w.b / det;
		var ic = -w.c / det;
		var id = w.a / det;
		var itx = -(ia * w.tx + ic * w.ty);
		var ity = -(ib * w.tx + id * w.ty);
		// local -> pixel of the untrimmed picture (anchor), then of the sheet (trim, frame), normalised
		var ox = mask.anchor.x * t.orig.width - (t.trim != null ? t.trim.x : 0) + t.frame.x;
		var oy = mask.anchor.y * t.orig.height - (t.trim != null ? t.trim.y : 0) + t.frame.y;
		var bw = bt.width;
		var bh = bt.height;
		uniforms.uRow0 = [ia / bw, ic / bw, (itx + ox) / bw];
		uniforms.uRow1 = [ib / bh, id / bh, (ity + oy) / bh];
		uniforms.uFrame = [t.frame.x / bw, t.frame.y / bh, (t.frame.x + t.frame.width) / bw, (t.frame.y + t.frame.height) / bh];
		uniforms.uMask = t;
		uniforms.uAlpha = mask.worldAlpha;
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform sampler2D uMask;
uniform highp vec4 inputSize;
uniform highp vec4 outputFrame;
uniform highp vec3 uRow0;
uniform highp vec3 uRow1;
uniform vec4 uFrame;
uniform float uAlpha;

void main(void) {
	highp vec3 p = vec3(vTextureCoord * inputSize.xy + outputFrame.xy, 1.0);
	highp vec2 uv = vec2(dot(uRow0, p), dot(uRow1, p));
	float a = 0.0;
	if (uv.x >= uFrame.x && uv.y >= uFrame.y && uv.x <= uFrame.z && uv.y <= uFrame.w)
		a = texture2D(uMask, uv).a * uAlpha;
	gl_FragColor = texture2D(uSampler, vTextureCoord) * a;
}
";
}
