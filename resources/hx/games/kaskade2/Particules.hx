package kaskade2;

import mt.Timer;

class Particules {
	var dmanager:mt.DepthManager;
	var tbl:Array<{
		mc:ASprite,
		x:Float,
		y:Float,
		a:Float,
		vx:Float,
		vy:Float,
		va:Float,
		ax:Int,
		ay:Float,
		f:Float
	}>;

	public function new(dman) {
		dmanager = dman;
		tbl = new Array();
	}

	public function randAngle() {
		return (Std.random(3600) / 10) / (Math.PI * 2);
	}

	public function addWordPart(x:Float, y:Float, f:Float) {
		var mc = dmanager.attach("part", Const.PLAN_PART);
		var s = Std.random(100) / 10 * (Std.random(2) * 2 - 1);
		mc.gotoAndStop((Std.random(4) + 1).int());
		mc._x = x;
		mc._y = y;
		var p = {
			mc: mc,
			x: x,
			y: y,
			a: randAngle(),
			vx: s,
			vy: -(Std.random(200) / 10),
			va: s,
			ax: 0,
			ay: 1.5,
			f: 0.98
		};
		tbl.push(p);
	}

	public function main() {
		var i = 0;
		var n = tbl.length;
		while (i < n) {
			var p = tbl[i];
			var f = Math.pow(p.f, Timer.tmod);
			p.vx *= f;
			p.vy *= f;
			p.vx += p.ax;
			p.vy += p.ay;
			p.x += p.vx;
			p.y += p.vy;
			p.a += p.va;
			p.mc._x = p.x;
			p.mc._y = p.y;
			p.mc._rotation = p.a * 180 / Math.PI;
			if (p.x < -100 || p.x > 400 || p.y < -100 || p.y > 400) {
				p.mc.removeMovieClip();
				tbl.splice(i, 1);
				i--;
			}
			i++;
		}
	}
}
