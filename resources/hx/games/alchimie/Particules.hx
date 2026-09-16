package alchimie;

class Particules {
	var dmanager:DepthManager;
	var tbl:Array<{
		mc:ASprite,
		x:Float,
		y:Float,
		a:Float,
		vx:Float,
		vy:Float,
		va:Float,
		ax:Float,
		ay:Float,
		f:Float
	}>;

	public function new(dman:DepthManager) {
		dmanager = dman;
		tbl = [];
	}

	function randAngle():Float {
		return (Seed.randomVfx(3600) / 10) / (Math.PI * 2);
	}

	public function add(x:Float, y:Float):Void {
		var mc = dmanager.attach("part", Cs.PLAN_PART);
		var s = Seed.randomVfx(100) / 10 * (Seed.randomVfx(2) * 2 - 1);
		mc.gotoAndStop(Seed.randomVfx(4) + 1);
		mc._x = x;
		mc._y = y;
		tbl.push({
			mc: mc,
			x: x,
			y: y,
			a: randAngle(),
			vx: KadoKadeoManager.S(s),
			vy: KadoKadeoManager.S(-(Seed.randomVfx(200) / 10)),
			va: s,
			ax: 0,
			ay: KadoKadeoManager.S(1.5),
			f: 0.98
		});
	}

	public function main():Void {
		var i = 0;
		while (i < tbl.length) {
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
			if (p.x < KadoKadeoManager.I(-100)
				|| p.x > KadoKadeoManager.I(400)
				|| p.y < KadoKadeoManager.I(-100)
				|| p.y > KadoKadeoManager.I(400)) {
				p.mc.removeMovieClip();
				tbl.splice(i, 1);
			} else {
				i++;
			}
		}
	}
}
