package starfang;

import mt.bumdum.Part;
import mt.bumdum.Lib.PointWithGetter;

class Phys extends mt.bumdum.Phys {
	var ray:Float;

	function collide(sp:Hero) {
		if (sp == null) {
			return false;
		}
		var p:PointWithGetter = sp;
		var d = getDist(p);
		return d < ray + sp.ray;
	}

	function checkWarp() {
		if (x < -ray) {
			x = Cs.mcw + ray;
		}
		if (x > Cs.mcw + ray) {
			x = -ray;
		}
		if (y < -ray) {
			y = Cs.mch + ray;
		}
		if (y > Cs.mch + ray) {
			y = -ray;
		}
	}

	//
	function fxOnde(sc) {
		var p = Cs.game.dm.attach("mcOnde", Game.DP_UNDERPARTS);
		p._x = x;
		p._y = y;
		p._xscale = sc;
		p._yscale = sc;
		p.removeOnFrame = 6;
		p.play();
	}

	function fxExplode(sc) {
		var p = Cs.game.dm.attach("mcMiniExplo", Game.DP_UNDERPARTS);
		p._x = x;
		p._y = y;
		p._xscale = sc;
		p._yscale = sc;
		p.removeOnFrame = 9;
		p.play();
	}

	function throwDebris(gid:Int, coef:Float) {
		if (coef == null)
			coef = 1;
		var fr = 0;
		while (true) {
			fr++;
			var p = new Part(Cs.game.dm.attach("partDebris" + gid, Game.DP_PARTS));
			p.root.gotoAndStop(fr);

			var flBreak = (fr + 1) > p.root._totalframes * coef;
			var a = Cs.rand() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var c = 0.5 + Cs.rand() * 0.5;
			var sp = 3;

			p.x = x + ca * c * ray;
			p.y = y + sa * c * ray;
			p.vx = vx + ca * c * sp;
			p.vy = vy + sa * c * sp;
			p.vr = (Cs.rand() * 2 - 1) * 15;
			p.timer = 10 + Cs.rand() * 10;
			p.fadeType = 0;
			p.root._rotation = Cs.rand() * 360;
			if (flBreak)
				break;
		}
	}
}
