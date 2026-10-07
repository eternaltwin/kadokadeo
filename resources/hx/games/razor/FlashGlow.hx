package razor;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * Flash 8 GlowFilter / DropShadowFilter (outer, quality 1) at run time: the alpha of the clip blurred by a box of
 * blurX x blurY stage pixels (a drop shadow: moved by `distance` stage pixels along `angle`), multiplied by the strength,
 * in the colour, drawn under the clip (knockout: the clip itself is not drawn, only the glow outside it). Flash filters
 * are in stage pixels (not scaled by the clip): the box is blurX x the stage scale of the game (the root at x2, and the
 * page's own scale). The box is averaged with at most 16 x 16 samples (bilinear: an even spread over the box).
 * (digestomax.FlashGlow.) Razor: the shadow of the board (a DropShadowFilter of alpha 0.2 and distance 15), the outline
 * of the combo texts (knockout) and the glow of their score.
 */
class FlashGlow extends Filter {
	static inline var MAXN = 16;

	var blurX:Float;
	var blurY:Float;
	var dx:Float;
	var dy:Float;

	public function new(blurX:Float, blurY:Float, strength:Float, color:Int, alpha:Float = 1, knockout:Bool = false,
			distance:Float = 0, angle:Float = 45) {
		super(null, FRAG, {
			uBox: [0.0, 0.0],
			uTexel: [0.0, 0.0],
			uN: [1.0, 1.0],
			uOffset: [0.0, 0.0],
			uStrength: strength,
			uColor: [((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255, alpha],
			uKnock: knockout ? 1.0 : 0.0,
		});
		this.blurX = blurX;
		this.blurY = blurY;
		dx = distance * Math.cos(angle * Math.PI / 180);
		dy = distance * Math.sin(angle * Math.PI / 180);
		padding = pad();
	}

	function pad():Int {
		return Math.ceil((Math.max(blurX, blurY) / 2 + Math.max(Math.abs(dx), Math.abs(dy))) * scale()) + 2;
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
		var bx = blurX * k;
		var by = blurY * k;
		uniforms.uBox = [bx, by];
		// (not inputSize: highp in PIXI's vertex shader, a uniform shared with this mediump shader would not link)
		uniforms.uTexel = [1 / input.baseTexture.realWidth, 1 / input.baseTexture.realHeight];
		uniforms.uN = [Math.min(MAXN, Math.max(1, Math.ceil(bx))), Math.min(MAXN, Math.max(1, Math.ceil(by)))];
		uniforms.uOffset = [dx * k, dy * k];
		padding = pad();
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec2 uTexel;
uniform vec4 inputClamp;
uniform vec2 uBox;
uniform vec2 uN;
uniform vec2 uOffset;
uniform float uStrength;
uniform vec4 uColor;
uniform float uKnock;

void main(void) {
	vec4 src = texture2D(uSampler, vTextureCoord);
	vec2 base = vTextureCoord - uOffset * uTexel;
	float sum = 0.0;
	for (int j = 0; j < 16; j++) {
		if (float(j) >= uN.y) break;
		float oy = (float(j) + 0.5) * uBox.y / uN.y - uBox.y * 0.5;
		for (int i = 0; i < 16; i++) {
			if (float(i) >= uN.x) break;
			float ox = (float(i) + 0.5) * uBox.x / uN.x - uBox.x * 0.5;
			vec2 uv = base + vec2(ox, oy) * uTexel;
			// (outside the input: transparent)
			if (uv.x >= inputClamp.x && uv.y >= inputClamp.y && uv.x <= inputClamp.z && uv.y <= inputClamp.w)
				sum += texture2D(uSampler, uv).a;
		}
	}
	float g = clamp(sum / (uN.x * uN.y) * uStrength, 0.0, 1.0) * uColor.a;
	vec4 glow = vec4(uColor.rgb * g, g) * (1.0 - src.a);
	gl_FragColor = glow + src * (1.0 - uKnock);
}
";
}
