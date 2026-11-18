package crepuscud;

import mt.bumdum.Sprite;

class Onde extends Sprite {
	var size:Float;
	var coef:Float;
	var tm:Float;

	public var pool:{n:Int, multi:Int};

	// achievements only: the missiles this wave destroyed, and the special colours among them (bits 0, 1, 2)
	public var oCnt:Int = 0;
	public var oCols:Int = 0;

	public function new(x, y, size) {
		var mc = Game.me.edm.attach("mcOnde", Game.DP_ONDE);
		mc.play();
		super(mc);
		this.size = size;
		this.x = x;
		this.y = y;
		var ray = size * 0.5 + KadoKadeoManager.S(4);
		root._xscale = root._yscale = ray / KadoKadeoManager.I(2);
		// Game.me.plasma.drawMc(root);

		coef = 0;
		tm = 0;

		var mc = Game.me.dm.attach("mcImpact", Game.DP_PARTS);
		mc._x = x;
		mc._y = y;
		mc._xscale = mc._yscale = size * 8 / KadoKadeoManager.I(1);
		mc.play();
		mc.removeOnFrame = 15;
	}

	override function update() {
		super.update();

		tm += mt.Timer.tmod;
		while (tm >= 1) {
			tm--;
			coef += (1 - coef) * 0.5;
		}

		var ray = size * coef * 0.5 + KadoKadeoManager.S(4);
		root._xscale = root._yscale = ray / KadoKadeoManager.I(2);

		var list = Game.me.missiles.copy();
		for (mis in list) {
			var dx = mis.x - x;
			var dy = mis.y - y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist < ray && mis.y > KadoKadeoManager.S(15)) {
				// achievements only: this wave's kills and the special colours it destroys (read before the missile dies,
				// frozen once the game is lost)
				if (!Game.me.flGameOver) {
					oCnt++;
					if (mis.special != null)
						oCols |= 1 << mis.special;
					if (oCnt > Game.me.stats.me)
						Game.me.stats.me = oCnt;
					if (oCols == 7)
						Game.me.stats.rb = 1;
				}
				mis.explode(pool);
				pool.n = Std.int(Math.min(pool.n + 1, Cs.SCORE_MISSILE.length - 1));
			}
		}

		if (coef > 0.997)
			kill();
	}
}
