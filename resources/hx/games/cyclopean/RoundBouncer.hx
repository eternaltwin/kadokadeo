package cyclopean;

// a round body (a ring of points) rolling pixel by pixel in the level bitmap: it slides along the walls, the
// normal of a wall is measured by following its edge (getNormal)
class RoundBouncer extends Bouncer {
	public static inline var RAY = 4;

	var pList:Array<{x:Int, y:Int}>;

	public function new(sprite:Phys) {
		super(sprite);
		pList = [{x: 0, y: 0}];
		frict = 0.3;
	}

	public function setRoundShape(ray:Float, max:Int):Void {
		pList = new Array();
		for (i in 0...max) {
			var a = (i / max) * 6.28;
			var ca = Cs.cos(a);
			var sa = Cs.sin(a);
			pList.push({x: Std.int(ca * ray), y: Std.int(sa * ray)});
		}
	}

	override public function update():Void {
		// (mList, the debug markers: never filled)
		parc = 1;
		// port: a guard against an endless loop (the Flash player would have stopped the script); never reached by
		// the moves of the game
		var guard = 0;

		while (parc > 0) {
			if (ox < 0 || ox > 1 || oy < 0 || oy > 1) {
				// ("decal error!")
				return;
			}
			if (++guard > 100000)
				break;

			var cx:Float;
			var cy:Float;

			var sx = 0;
			var sy = 0;

			if (sp.vx > 0) {
				cx = (1 - ox) / sp.vx;
				sx = 1;
			} else if (sp.vx < 0) {
				cx = ox / sp.vx;
				sx = -1;
			} else {
				cx = 1;
			}

			if (sp.vy > 0) {
				cy = (1 - oy) / sp.vy;
				sy = 1;
			} else if (sp.vy < 0) {
				cy = oy / sp.vy;
				sy = -1;
			} else {
				cy = 1;
			}

			var c:Float;

			var acx = Math.abs(cx);
			var acy = Math.abs(cy);
			var flCheck = true;

			if (acx < acy) {
				c = acx;
				sy = 0;
			} else {
				c = acy;
				sx = 0;
			}

			if (c >= parc) {
				c = parc;
				flCheck = false;
			}
			ox = Cs.mm(0, ox + sp.vx * c, 1);
			oy = Cs.mm(0, oy + sp.vy * c, 1);
			parc -= c;

			if (flCheck) {
				var cp = isRoundFree(px + sx, py + sy);
				var flGo = cp == null;
				if (!flGo) {
					var a = Cs.atan2(sp.vy, sp.vx);
					var n = getNormal(cp.x, cp.y, {x: sx, y: sy}, RAY);
					var da = Math.abs(Cs.hMod((n - a), 3.14));

					if (da > 1.57) {
						flGo = true;
					} else {
						bounce(a, n);
						hitPoint(cp);
						var fc = Math.max(0, 1 - ((da / 1.57) * 0.8 + 0.5));
						var f = Cs.pow(frict, fc);
						sp.vx *= f;
						sp.vy *= f;
					}
				}
				if (flGo) {
					onSwapPixel();
					px += sx;
					py += sy;
					ox = Cs.mm(0, ox - sx, 1);
					oy = Cs.mm(0, oy - sy, 1);
				}
			}
		}
		sp.x = px + ox;
		sp.y = py + oy;
	}

	function bounce(a:Float, n:Float):Void {
		onBounce(sp.vx, sp.vy);
		var p = Math.sqrt(sp.vx * sp.vx + sp.vy * sp.vy);
		a = bounceAngle(a, n);
		var ca = Cs.cos(a);
		var sa = Cs.sin(a);
		sp.vx = ca * p;
		sp.vy = sa * p;
	}

	function getNormal(bx:Int, by:Int, bdir:{x:Int, y:Int}, ray:Int):Float {
		// GET SIDE LIST
		var sideList = [[bdir.x, bdir.y]];
		for (i in 0...2) {
			var px = bx;
			var py = by;
			var dir = {x: bdir.x, y: bdir.y};
			var sens = i * 2 - 1;
			for (n in 0...ray) {
				var f = turn(dir, sens);
				var nx = px + f.x;
				var ny = py + f.y;
				if (!Cs.game.isFree(nx, ny)) {
					dir = f;
				} else {
					if (Cs.game.isFree(nx + dir.x, ny + dir.y)) {
						px = nx + dir.x;
						py = ny + dir.y;
						dir = turn(dir, -sens);
					} else {
						px = nx;
						py = ny;
					}
				}
				sideList.push([dir.x, dir.y]);
			}
		}

		// GET ANGLE
		var dx = 0;
		var dy = 0;
		for (dir in sideList) {
			dx += dir[0];
			dy += dir[1];
		}
		return Cs.atan2(dy, dx);
	}

	function bounceAngle(a:Float, n:Float):Float {
		var da = Cs.hMod((n - a), 3.14);
		var dx = Cs.cos(da);
		var dy = Cs.sin(da);
		var na = Cs.atan2(dy, -dx);
		return Cs.hMod(n - na, 3.14);
	}

	function turn(d:{x:Int, y:Int}, sens:Int):{x:Int, y:Int} {
		return {x: -d.y * sens, y: d.x * sens};
	}

	function isRoundFree(x:Int, y:Int):{x:Int, y:Int} {
		for (dec in pList) {
			var p = {x: x + dec.x, y: y + dec.y};
			if (!Cs.game.isFree(p.x, p.y))
				return p;
		}
		return null;
	}

	// replaced by the sprite that wants them (Ball: traceQueue, impact)
	public dynamic function onSwapPixel():Void {}

	public dynamic function hitPoint(p:{x:Int, y:Int}):Void {}
}
