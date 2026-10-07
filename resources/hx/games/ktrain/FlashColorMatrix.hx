package ktrain;

import pixi.core.renderers.webgl.filters.Filter;

/**
 * Flash 8 ColorMatrixFilter: a 4 x 5 matrix on the colours before premultiplication, offsets in 0..255
 * (CoalAnim: the driver carrying the coal, brightened; Loco: the train behind, red).
 */
class FlashColorMatrix extends Filter {
	public function new(m:Array<Float>) {
		super(null, FRAG, {
			uM: [m[0], m[5], m[10], m[15], m[1], m[6], m[11], m[16], m[2], m[7], m[12], m[17], m[3], m[8], m[13], m[18]],
			uOff: [m[4] / 255, m[9] / 255, m[14] / 255, m[19] / 255],
		});
	}

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform mat4 uM;
uniform vec4 uOff;

void main(void) {
	vec4 c = texture2D(uSampler, vTextureCoord);
	if (c.a > 0.0) c.rgb /= c.a;
	vec4 r = clamp(uM * c + uOff, 0.0, 1.0);
	gl_FragColor = vec4(r.rgb * r.a, r.a);
}
";
}
