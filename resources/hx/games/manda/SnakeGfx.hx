package manda;

import pixi.core.display.Container;
import pixi.core.textures.Texture;
import js.lib.Float32Array;
import js.lib.Uint16Array;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;

// The body of the snake as drawn by Snake.draw (drawing API of the original): per pass (light shade 4 px lower, dark
// border, body), a curve per piece of tail with its thickness: x0, y0, control x, y, x1, y1, thickness.
class Body {
	public var shade:Array<Float>;
	public var border:Array<Float>;
	public var body:Array<Float>;
	public var borderColor:Int;
	public var bodyColor:Int;

	public function new(shade, border, body, borderColor, bodyColor) {
		this.shade = shade;
		this.border = border;
		this.body = body;
		this.borderColor = borderColor;
		this.bodyColor = bodyColor;
	}
}

// The mcs `shade` and `gfx` of the snake. Each curve is a stroke with round caps and its own thickness, like the
// drawing API of the Flash player: a strip along the curve (4 lines, mitred joins) and a disc at both ends (textured
// quads of an anti-aliased circle), one mesh per pass, in a texture at 4 px per Flash pixel shown at 2 px per Flash
// pixel (anti-aliased edges). The texture is drawn only when the body changed, at display time (not during the seeks
// of a replay).
// The picture shown is the body of the previous step: the head is shown between its positions of the previous and of
// the current step, a body of the current step could stick out in front of it.
class SnakeGfx extends ASprite {
	static inline var SS = 4;
	// the game layer is masked from (5, 5) to (295, 265)
	static inline var X0 = 5;
	static inline var Y0 = 5;
	static inline var W = 290;
	static inline var H = 260;

	// body of the last draw (hitTest of the game)
	public var current:Body;

	var shown:Body;
	var rendered:Body;
	var rt:RenderTexture;
	var holder:Container;
	var passes:Array<Strokes>;
	var disc:Texture;

	public function new() {
		super();
		rt = (cast RenderTexture : Dynamic).create({width: W * SS, height: H * SS});
		addChild(new PixiSprite(rt));
		_x = X0;
		_y = Y0;
		_xscale = 100 / SS;
		_yscale = 100 / SS;
		holder = new Container();
		holder.scale.set(SS, SS);
		holder.position.set(-X0 * SS, -Y0 * SS);
		disc = Strokes.discTexture();
		passes = [for (i in 0...3) new Strokes(disc)];
		for (p in passes)
			holder.addChild(p.mesh);
	}

	// start of a step: the body drawn up to now is the one to show
	public function beginStep() {
		shown = current;
	}

	override public function updateGraphics(a:Float) {
		super.updateGraphics(a);
		if (shown != rendered) {
			rendered = shown;
			paint();
		}
	}

	function paint() {
		var b = rendered;
		passes[0].build(b == null ? [] : b.shade, Cs.COLOR_SNAKE_SHADE);
		passes[1].build(b == null ? [] : b.border, b == null ? 0 : b.borderColor);
		passes[2].build(b == null ? [] : b.body, b == null ? 0 : b.bodyColor);
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		renderer.render(holder, {renderTexture: rt, clear: true});
	}

	// gfx.hitTest(px, py, true): the point is in a stroke of the border (the widest pass of gfx)
	public function hit(px:Float, py:Float):Bool {
		if (current == null)
			return false;
		var s = current.border;
		var i = 0;
		while (i < s.length) {
			var x0 = s[i], y0 = s[i + 1], cx = s[i + 2], cy = s[i + 3], x1 = s[i + 4], y1 = s[i + 5];
			var r = s[i + 6] / 2;
			i += 7;
			if (px < Math.min(x0, Math.min(cx, x1)) - r || px > Math.max(x0, Math.max(cx, x1)) + r)
				continue;
			if (py < Math.min(y0, Math.min(cy, y1)) - r || py > Math.max(y0, Math.max(cy, y1)) + r)
				continue;
			if (x0 == x1 && y0 == y1 && x0 == cx && y0 == cy)
				continue;
			// the curve as 8 lines
			var ax = x0, ay = y0;
			for (k in 1...9) {
				var t = k / 8, u = 1 - k / 8;
				var bx = u * u * x0 + 2 * u * t * cx + t * t * x1;
				var by = u * u * y0 + 2 * u * t * cy + t * t * y1;
				if (segDist2(px, py, ax, ay, bx, by) <= r * r)
					return true;
				ax = bx;
				ay = by;
			}
		}
		return false;
	}

	static inline function segDist2(px:Float, py:Float, ax:Float, ay:Float, bx:Float, by:Float):Float {
		var vx = bx - ax, vy = by - ay;
		var l = vx * vx + vy * vy;
		var t = l > 0 ? ((px - ax) * vx + (py - ay) * vy) / l : 0;
		if (t < 0)
			t = 0
		else if (t > 1)
			t = 1;
		var dx = ax + vx * t - px, dy = ay + vy * t - py;
		return dx * dx + dy * dy;
	}

	public function dispose() {
		for (p in passes)
			p.dispose();
		holder.destroy();
		disc.destroy(true);
		rt.destroy(true);
	}
}

// The strokes of a pass: a mesh (MeshGeometry: positions, uvs, indices) rebuilt from the curves, drawn in one call
class Strokes {
	// the circle of the disc texture: radius 62 px in a 128 px square
	static inline var DISC = 128;
	static inline var DISC_R = 62;

	public var mesh:Dynamic;

	var geom:Dynamic;
	var pos:Float32Array;
	var uv:Float32Array;
	var idx:Uint16Array;
	var nv:Int;
	var ni:Int;

	// points, directions of the lines of a curve
	static var px = [for (i in 0...5) 0.0];
	static var py = [for (i in 0...5) 0.0];
	static var dx = [for (i in 0...4) 0.0];
	static var dy = [for (i in 0...4) 0.0];
	static var ok = [for (i in 0...4) false];

	public static function discTexture():Texture {
		var c:js.html.CanvasElement = js.Browser.document.createCanvasElement();
		c.width = DISC;
		c.height = DISC;
		var x = c.getContext2d();
		x.fillStyle = "#fff";
		x.beginPath();
		x.arc(DISC / 2, DISC / 2, DISC_R, 0, Math.PI * 2);
		x.fill();
		return Texture.from(c);
	}

	public function new(disc:Texture) {
		alloc(1024);
		geom = js.Syntax.code("new PIXI.MeshGeometry({0}, {1}, {2})", pos, uv, idx);
		mesh = js.Syntax.code("new PIXI.Mesh({0}, new PIXI.MeshMaterial({1}))", geom, disc);
	}

	function alloc(verts:Int) {
		var p = new Float32Array(verts * 2), u = new Float32Array(verts * 2), i = new Uint16Array(verts * 2);
		if (pos != null) {
			p.set(pos);
			u.set(uv);
			i.set(idx);
		}
		pos = p;
		uv = u;
		idx = i;
	}

	inline function vert(x:Float, y:Float, u:Float, v:Float) {
		pos[nv * 2] = x;
		pos[nv * 2 + 1] = y;
		uv[nv * 2] = u;
		uv[nv * 2 + 1] = v;
		nv++;
	}

	inline function tri(a:Int, b:Int, c:Int) {
		idx[ni++] = a;
		idx[ni++] = b;
		idx[ni++] = c;
	}

	function discAt(x:Float, y:Float, r:Float) {
		var h = r * DISC / 2 / DISC_R;
		var b = nv;
		vert(x - h, y - h, 0, 0);
		vert(x + h, y - h, 1, 0);
		vert(x + h, y + h, 1, 1);
		vert(x - h, y + h, 0, 1);
		tri(b, b + 1, b + 2);
		tri(b, b + 2, b + 3);
	}

	public function build(s:Array<Float>, color:Int) {
		nv = 0;
		ni = 0;
		var n = Std.int(s.length / 7);
		if (pos.length < n * 18 * 2)
			alloc(n * 18 * 2);
		var i = 0;
		while (i < s.length) {
			var x0 = s[i], y0 = s[i + 1], cx = s[i + 2], cy = s[i + 3], x1 = s[i + 4], y1 = s[i + 5];
			var r = s[i + 6] / 2;
			i += 7;
			// (a curve to the same point draws nothing in Flash)
			if (x0 == x1 && y0 == y1 && x0 == cx && y0 == cy)
				continue;
			for (k in 0...5) {
				var t = k / 4, u = 1 - k / 4;
				px[k] = u * u * x0 + 2 * u * t * cx + t * t * x1;
				py[k] = u * u * y0 + 2 * u * t * cy + t * t * y1;
			}
			var any = false;
			for (k in 0...4) {
				var ex = px[k + 1] - px[k], ey = py[k + 1] - py[k];
				var l = Math.sqrt(ex * ex + ey * ey);
				ok[k] = l > 1e-9;
				if (ok[k]) {
					dx[k] = ex / l;
					dy[k] = ey / l;
					any = true;
				}
			}
			if (any) {
				// lines of no length: direction of a neighbour
				for (k in 1...4)
					if (!ok[k] && ok[k - 1]) {
						dx[k] = dx[k - 1];
						dy[k] = dy[k - 1];
						ok[k] = true;
					}
				var k = 3;
				while (k > 0) {
					k--;
					if (!ok[k]) {
						dx[k] = dx[k + 1];
						dy[k] = dy[k + 1];
						ok[k] = true;
					}
				}
				var b = nv;
				for (k in 0...5) {
					// normal (mitred between two lines)
					var nx, ny;
					if (k == 0) {
						nx = -dy[0];
						ny = dx[0];
					} else if (k == 4) {
						nx = -dy[3];
						ny = dx[3];
					} else {
						var ax = -dy[k - 1], ay = dx[k - 1];
						nx = ax - dy[k];
						ny = ay + dx[k];
						var l = Math.sqrt(nx * nx + ny * ny);
						if (l < 1e-6) {
							nx = ax;
							ny = ay;
						} else {
							nx /= l;
							ny /= l;
							var c = nx * ax + ny * ay;
							var m = 1 / (c < 0.5 ? 0.5 : c);
							nx *= m;
							ny *= m;
						}
					}
					vert(px[k] + nx * r, py[k] + ny * r, 0.5, 0.5);
					vert(px[k] - nx * r, py[k] - ny * r, 0.5, 0.5);
				}
				for (k in 0...4) {
					var a = b + k * 2;
					tri(a, a + 1, a + 2);
					tri(a + 1, a + 3, a + 2);
				}
			}
			discAt(px[0], py[0], r);
			discAt(px[4], py[4], r);
		}
		geom.getBuffer("aVertexPosition").update(pos);
		geom.getBuffer("aTextureCoord").update(uv);
		geom.getIndex().update(idx);
		mesh.size = ni;
		mesh.visible = ni > 0;
		mesh.tint = color;
	}

	public function dispose() {
		mesh.destroy();
		geom.destroy();
	}
}
