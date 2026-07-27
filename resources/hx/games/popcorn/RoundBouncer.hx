package popcorn;

import mt.bumdum.Lib.Num;
import mt.Timer;

class RoundBouncer extends Bouncer {
	static var RAY = KadoKadeoManager.I(6);

	var pList:Array<{x:Int, y:Int}>;

	static var mList:Array<ASprite>;

	var vvx:Float;
	var vvy:Float;

	public function new(sprite:Phys) {
		super(sprite);
		if (mList == null)
			mList = new Array();

		pList = new Array();

		var ray = RAY;
		var max = 4;
		for (i in 0...max) {
			var a = (i / max) * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			pList.push({x: Std.int(ca * ray), y: Std.int(sa * ray)});
		}

		//
		frict = 0.3;
	}

	override public function update():Void {
		while (mList.length > 100)
			mList.shift().removeMovieClip();

		parc = 1;
		var tr = 0;
		updateVV();

		while (parc > 0) {
			if (ox < 0 || ox > 1 || oy < 0 || oy > 1) {
				return;
			}

			var cx = null;
			var cy = null;

			var sx = 0;
			var sy = 0;

			if (vvx > 0) {
				cx = (1 - ox) / vvx;
				sx = 1;
			} else if (vvx < 0) {
				cx = ox / vvx;
				sx = -1;
			} else {
				cx = 1;
			}

			if (vvy > 0) {
				cy = (1 - oy) / vvy;
				sy = 1;
			} else if (vvy < 0) {
				cy = oy / vvy;
				sy = -1;
			} else {
				cy = 1;
			}

			var c = null;

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
			ox = Num.mm(0, ox + vvx * c, 1);
			oy = Num.mm(0, oy + vvy * c, 1);
			parc -= c;

			if (flCheck) {
				if (sx == 0 && sy == 0)
					trace("Oh mon dieu, c'est affreux!");

				var cp = isRoundFree(px + sx, py + sy);
				var flGo = cp == null;
				if (!flGo) {
					var a = Math.atan2(vvy, vvx);
					var n = getNormal(cp.x, cp.y, {x: sx, y: sy}, RAY);
					var da = Math.abs(Num.hMod((n - a), 3.14));

					if (da > 1.57) {
						flGo = true;
					} else {
						bounce(a, n);
						var fc = Math.max(0, 1 - ((da / 1.57) * 0.8 + 0.5));
						var f = Math.pow(frict, fc);
						sp.vx *= f;
						sp.vy *= f;
						updateVV();
					}
				}
				if (flGo) {
					px += sx;
					py += sy;
					ox = Num.mm(0, ox - sx, 1);
					oy = Num.mm(0, oy - sy, 1);
				}
			}
		}
		if (sp.bouncer == this) {
			sp.x = px + ox;
			sp.y = py + oy;
		}
	}

	public function bounce(a:Float, n:Float):Void {
		onBounceAngle(a, n);
		var p = Math.sqrt(sp.vx * sp.vx + sp.vy * sp.vy);
		a = bounceAngle(a, n);
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		sp.vx = ca * p;
		sp.vy = sa * p;
		updateVV();
	}

	public function updateVV():Void {
		vvx = sp.vx * Timer.tmod;
		vvy = sp.vy * Timer.tmod;
	}

	public function getNormal(bx:Int, by:Int, bdir:{x:Int, y:Int}, ray:Int):Float {
		// GET SIDE LIST
		var sideList = [[bdir.x, bdir.y]];
		for (i in 0...2) {
			var px = bx;
			var py = by;
			var dir = {x: bdir.x, y: bdir.y}
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
		// RETUUUUUUUUUUUUURN !
		return Math.atan2(dy, dx);
	}

	public function bounceAngle(a:Float, n:Float):Float {
		var da = Num.hMod((n - a), 3.14);
		var dx = Math.cos(da);
		var dy = Math.sin(da);
		var na = Math.atan2(dy, -dx);
		return Num.hMod(n - na, 3.14);
	}

	public function turn(d:{x:Int, y:Int}, sens:Int):{x:Int, y:Int} {
		return {x: -d.y * sens, y: d.x * sens}
	}

	public function isRoundFree(x:Int, y:Int):{x:Int, y:Int} {
		for (dec in pList) {
			var p = {x: x + dec.x, y: y + dec.y};
			if (!Cs.game.isFree(p.x, p.y))
				return p;
		}
		return null;
	}
}
