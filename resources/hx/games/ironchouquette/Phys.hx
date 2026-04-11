package ironchouquette;

import mt.bumdum.Lib;

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

	public function collide(sp:Phys) {
		var d = getDist({x: sp.x, y: sp.y});
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
}
