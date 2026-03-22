package ironchouquette;

import mt.bumdum.Sprite;
import mt.Timer;

class Phys extends mt.bumdum.Phys {
	public var ray:Float;

	public var flash:Float;
	public var plasmaId:Int;

	public function new(mc) {
		super(mc);
		// frict = 1
		vx = 0;
		vy = 0;
	}

	public override function update() {
		super.update();

		if (plasmaId != null) {
			Cs.game.plasmaDraw(root, plasmaId);
		}
	}

	public function updateFlash() {
		if (flash != null) {
			var prc = Math.min(flash, 100);
			flash *= 0.6;
			if (flash < 2) {
				flash = null;
				prc = 0;
			}
			Col.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	public function collide(sp) {
		var d = getDist(sp);
		return d < ray + sp.ray;
	}

	//
	public function fxOnde(sc) {
		var p = Cs.game.dm.attach("mcOnde", Game.DP_UNDERPARTS);
		p._x = x;
		p._y = y;
		p._xscale = sc;
		p._yscale = sc;
	}

	public function fxExplode(sc) {
		var p = Cs.game.dm.attach("mcMiniExplo", Game.DP_UNDERPARTS);
		p._x = x;
		p._y = y;
		p._xscale = sc;
		p._yscale = sc;
	}

	public function throwDebris(gid:Int, coef:Float) {
		if (coef == null)
			coef = 1;
		var fr = 0;
		while (true) {
			fr++;
			var p = new Part(Cs.game.dm.attach("partDebris", Game.DP_PARTS));
			p.root.gotoAndStop(Std.string(gid));
			var mc = downcast(p.root).sub;
			mc.gotoAndStop(Std.string(fr));

			var flBreak = (fr + 1) > mc._totalframes * coef;
			var a = Math.random() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var c = 0.5 + Math.random() * 0.5;
			var sp = 3;

			p.x = x + ca * c * ray;
			p.y = y + sa * c * ray;
			p.vx = vx + ca * c * sp;
			p.vy = vy + sa * c * sp;
			p.vr = (Math.random() * 2 - 1) * 15;
			p.timer = 10 + Math.random() * 10;
			p.fadeType = 0;
			p.root._rotation = Math.random() * 360;
			if (flBreak)
				break;
		}
	}

	public function getRandomPart(gid:Int):Part {
		var p = new Part(Cs.game.dm.attach("partDebris", Game.DP_PARTS));
		p.root.gotoAndStop(Std.string(gid));
		var mc = downcast(p.root).sub;
		mc.gotoAndStop(Std.string(Std.random(mc._totalframes) + 1));

		return p;
	}
}
