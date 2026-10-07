package quadrikolor;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;
import pixi.mesh.NineSlicePlane;

typedef LineSeg = {
	x0:Float,
	y0:Float,
	x1:Float,
	y1:Float,
	alpha:Float,
	mark:Bool
};

/**
 * The aiming line of Game.drawLines: the original drew it with the Flash drawing API in `lines` (lineStyle(26, white,
 * alpha) + lineTo, one stroke per bounce, round caps) and attached a `lineseg` mark at each bounce, again at every
 * Flash frame. Only drawn, never read by the game: it is built at each picture from the position and rotation the ship
 * is shown at (its clip, interpolated), so the line turns with the ship.
 *
 * A stroke is a strip of a white disc 26 px wide (in Flash pixels) stretched in its middle (NineSlicePlane): round
 * caps, anti-aliased edges, one alpha per stroke; two strokes overlap at a bounce like in Flash.
 */
class Lines extends ASprite {
	// texture pixels per Flash pixel
	static inline var PX = 2;
	static var disc:Texture;

	var strokes:Container;
	var marks:Container;

	// set by the game at each step: drawn or not (drawLines / clearLines, as shown), the ship, carbu, the bounds
	public var shown:Bool = false;
	public var ship:Ball;
	public var carbu:Int = 0;
	public var bounds:Physics.Bounds;

	public function new() {
		super();
		strokes = new Container();
		marks = new Container();
		addChild(strokes);
		addChild(marks);
		if (disc == null)
			disc = makeDisc();
	}

	// a white disc of the stroke's thickness (+ 1 px of margin for the anti-aliasing)
	static function makeDisc():Texture {
		var r = Const.BALL_RAY * PX;
		var size = 2 * r + 2;
		var c = js.Browser.document.createCanvasElement();
		c.width = size;
		c.height = size;
		var ctx = c.getContext2d();
		ctx.fillStyle = "#ffffff";
		ctx.beginPath();
		ctx.arc(size / 2, size / 2, r, 0, Math.PI * 2);
		ctx.fill();
		return Texture.from(c);
	}

	// Game.drawLines: the path of the ship (centre) from (px, py) at `rot` degrees, bouncing on the bounds
	public static function path(px:Float, py:Float, rot:Float, carbu:Int, b:Physics.Bounds, r:Float):Array<LineSeg> {
		var out:Array<LineSeg> = [];
		var totd:Float = Const.MIN_LINE + Const.DELTA_LINE * (Const.MAX_CARBU - carbu);
		var a = rot * Math.PI / 180;
		var alpha = 20;
		while (totd > 0) {
			var sx = Math.cos(a);
			var sy = Math.sin(a);
			var m = Math.POSITIVE_INFINITY;
			var d:Float;
			var x = 0;
			var y = 0;

			d = (px - b.xmin - r) / -sx;
			if (d > 0.1 && d < m) {
				m = d;
				x = 1;
				y = 0;
			}

			d = (py - b.ymin - r) / -sy;
			if (d > 0.1 && d < m) {
				m = d;
				x = 0;
				y = 1;
			}

			d = (px - b.xmax + r) / -sx;
			if (d > 0.1 && d < m) {
				m = d;
				x = -1;
				y = 0;
			}

			d = (py - b.ymax + r) / -sy;
			if (d > 0.1 && d < m) {
				m = d;
				x = 0;
				y = -1;
			}

			d = Math.min(m, totd);
			totd -= d;
			var nx = px + d * sx;
			var ny = py + d * sy;
			out.push({
				x0: px,
				y0: py,
				x1: nx,
				y1: ny,
				alpha: alpha,
				mark: totd > 0
			});
			px = nx;
			py = ny;

			var k = (1 + b.coef) * (x * sx + y * sy);
			sx -= k * x;
			sy -= k * y;
			a = Math.atan2(sy, sx);
			alpha -= 4;
		}
		return out;
	}

	override public function updateGraphics(a:Float) {
		super.updateGraphics(a);
		var c:ASprite = ship != null ? ship.mc.clip : null;
		if (!shown || c == null) {
			visible = false;
			trim(strokes, 0);
			trim(marks, 0);
			return;
		}
		var p = c._prevState != null ? c._prevState : c._curState;
		var n = c._curState;
		var dr = n.rotation - p.rotation;
		while (dr > Math.PI)
			dr -= 2 * Math.PI;
		while (dr < -Math.PI)
			dr += 2 * Math.PI;
		var rot = (p.rotation + dr * a) * 180 / Math.PI;
		show(path(p.x + (n.x - p.x) * a, p.y + (n.y - p.y) * a, rot, carbu, bounds, ship.r));
	}

	function show(segs:Array<LineSeg>) {
		visible = true;
		var ns = 0;
		var nm = 0;
		for (s in segs) {
			// lineStyle(BALL_RAY * 2, 0xFFFFFF, alpha): nothing drawn from alpha 0
			if (s.alpha > 0) {
				var p:NineSlicePlane;
				if (ns < strokes.children.length) {
					p = cast strokes.children[ns];
				} else {
					var h = Std.int(disc.width / 2);
					p = new NineSlicePlane(disc, h, 0, h, 0);
					p.pivot.set(h, h);
					p.scale.set(1 / PX, 1 / PX);
					strokes.addChild(p);
				}
				var dx = s.x1 - s.x0;
				var dy = s.y1 - s.y0;
				p.width = Math.sqrt(dx * dx + dy * dy) * PX + disc.width;
				p.height = disc.height;
				p.x = s.x0;
				p.y = s.y0;
				p.rotation = Math.atan2(dy, dx);
				p.alpha = s.alpha / 100;
				p.visible = true;
				ns++;
			}
			// the lineseg mark of a bounce (_alpha = alpha * 100 / 20)
			if (s.mark && s.alpha > 0) {
				var sp:PixiSprite;
				if (nm < marks.children.length) {
					sp = cast marks.children[nm];
				} else {
					var t = Tex.get("lineseg_0")[0];
					sp = new PixiSprite(t);
					sp.anchor.copyFrom(t.defaultAnchor);
					sp.scale.set(1 / PX, 1 / PX);
					marks.addChild(sp);
				}
				sp.x = s.x1;
				sp.y = s.y1;
				sp.alpha = Math.min(1, s.alpha * 100 / 20 / 100);
				sp.visible = true;
				nm++;
			}
		}
		trim(strokes, ns);
		trim(marks, nm);
	}

	// only the strokes and marks drawn stay (what is not shown does not depend on what was drawn before: the same
	// display tree after a seek)
	static function trim(c:Container, n:Int) {
		while (c.children.length > n)
			c.removeChildAt(c.children.length - 1).destroy();
	}
}
