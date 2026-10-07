package ktrain;

import pixi.core.textures.Texture;

/**
 * The vertical BlurFilter of the smoke (Loco.makeSmoke: blurY = the speed, on every second puff) without a filter: up
 * to 40 puffs blurred each frame, a filter each (a render texture pass) took 5 ms per picture. A box blur commutes with
 * the scale of the clip, so the box of blurY stage pixels is the box of blurY / (vertical scale of a texel) texels of
 * the puff's own picture: drawn by a mesh in place of the picture, its shader averages the texture vertically over that
 * box (weights of a continuous box, outside the picture's frame in the atlas: transparent), the quad grown by half the
 * box above and below. Exact for one blurred clip, at the cost of one draw call.
 */
class VBlur {
	static var program:Dynamic = null;
	static var bases:Map<Int, Texture> = new Map();
	static var nextId = 0;

	var mesh:Dynamic;
	var geom:Dynamic;
	var shown:Texture = null;

	// box width in texels of the picture
	public var width(default, null):Float;

	public function new(parent:common_haxe_avm1.display.ASprite, width:Float) {
		this.width = width;
		if (program == null)
			program = js.Syntax.code("PIXI.Program.from({0}, {1})", VERT, FRAG);
		geom = js.Syntax.code("new PIXI.MeshGeometry(new Float32Array(8), new Float32Array(8), new Uint16Array([0, 1, 2, 0, 2, 3]))");
		mesh = null;
		this.parent = parent;
	}

	var parent:common_haxe_avm1.display.ASprite;

	// the picture of the clip (its texture in the sheet, trimmed, with its anchor)
	public function show(t:Texture) {
		if (t == shown)
			return;
		shown = t;
		var tt:Dynamic = t;
		if (t == null || tt.baseTexture == null || tt.frame.width <= 0) {
			if (mesh != null)
				mesh.visible = false;
			return;
		}
		var base:Dynamic = tt.baseTexture;
		var bw:Float = base.width, bh:Float = base.height;
		var fr:Dynamic = tt.frame;
		var orig:Dynamic = tt.orig;
		var trim:Dynamic = tt.trim;
		var anchor:Dynamic = tt.defaultAnchor;
		var ox:Float = trim != null ? trim.x : 0, oy:Float = trim != null ? trim.y : 0;
		var x0 = -anchor.x * orig.width + ox, y0 = -anchor.y * orig.height + oy;
		var x1 = x0 + fr.width, y1 = y0 + fr.height;
		var e = width / 2 + 1;
		var u0 = fr.x / bw, u1 = (fr.x + fr.width) / bw;
		var v0 = fr.y / bh, v1 = (fr.y + fr.height) / bh;
		var ev = e / bh;
		var pos:Dynamic = geom.getBuffer("aVertexPosition");
		var uv:Dynamic = geom.getBuffer("aTextureCoord");
		var p:Dynamic = pos.data, q:Dynamic = uv.data;
		p[0] = x0; p[1] = y0 - e; p[2] = x1; p[3] = y0 - e; p[4] = x1; p[5] = y1 + e; p[6] = x0; p[7] = y1 + e;
		q[0] = u0; q[1] = v0 - ev; q[2] = u1; q[3] = v0 - ev; q[4] = u1; q[5] = v1 + ev; q[6] = u0; q[7] = v1 + ev;
		pos.update();
		uv.update();
		if (mesh == null) {
			var key:Int = untyped base.__vbId != null ? base.__vbId : (base.__vbId = nextId++);
			var full = bases.get(key);
			if (full == null) {
				full = new Texture(base);
				bases.set(key, full);
			}
			var mat:Dynamic = js.Syntax.code("new PIXI.MeshMaterial({0}, {program: {1}, uniforms: {uFrame: new Float32Array(4), uTexelY: 0, uHalf: 0}})",
				full, program);
			mesh = js.Syntax.code("new PIXI.Mesh({0}, {1})", geom, mat);
			parent.addChild(mesh);
		}
		mesh.visible = true;
		var u:Dynamic = mesh.shader.uniforms;
		u.uFrame[0] = u0;
		u.uFrame[1] = v0;
		u.uFrame[2] = u1;
		u.uFrame[3] = v1;
		u.uTexelY = 1 / bh;
		u.uHalf = width / 2;
	}

	public function destroy() {
		if (mesh != null) {
			if (mesh.parent != null)
				mesh.parent.removeChild(mesh);
			mesh.destroy();
			mesh = null;
		}
	}

	static var VERT = "attribute vec2 aVertexPosition;
attribute vec2 aTextureCoord;
uniform mat3 projectionMatrix;
uniform mat3 translationMatrix;
varying vec2 vTextureCoord;
void main(void) {
	gl_Position = vec4((projectionMatrix * translationMatrix * vec3(aVertexPosition, 1.0)).xy, 0.0, 1.0);
	vTextureCoord = aTextureCoord;
}
";

	static var FRAG = "varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform vec4 uColor;
uniform vec4 uFrame;
uniform float uTexelY;
uniform float uHalf;
void main(void) {
	vec4 sum = vec4(0.0);
	float wsum = 0.0;
	for (int i = -12; i <= 12; i++) {
		float t = float(i);
		float w = clamp(uHalf + 0.5 - abs(t), 0.0, 1.0);
		if (w <= 0.0) continue;
		vec2 uv = vTextureCoord + vec2(0.0, t * uTexelY);
		wsum += w;
		if (uv.x < uFrame.x || uv.x > uFrame.z || uv.y < uFrame.y || uv.y > uFrame.w) continue;
		sum += texture2D(uSampler, uv) * w;
	}
	gl_FragColor = sum / max(wsum, 1e-6) * uColor;
}
";
}
