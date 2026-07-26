package travoltax.opt;

import common_haxe_avm1.display.ASprite;
import kado.KadoKadeoManager;
import travoltax.Common.Cs;
import travoltax.Common.Step;
import travoltax.Game;
import travoltax.Option;

class Breaker extends Option {
	var timer:Float;
	var list:Array<Array<Int>>;

	var mcLaser:ASprite;

	public function new(max) {
		super();
		Game.me.step = Freeze;
		destroyPiece();
		timer = 0;

		// LIST
		var px = 0;
		var py = Cs.YMAX - 1;
		var sens = 1;
		list = [];
		while (true) {
			var n = Game.me.grid[py][px];
			if (n != null)
				list.push([px, py]);
			px += sens;
			if (px == -1 || px == Cs.XMAX) {
				sens *= -1;
				py--;
				if (py < Cs.YMAX - max)
					break;
			}
		}

		// LASER
		mcLaser = Game.me.dm.attach("mcLaser", Game.DP_PARTS);
		mcLaser._x = Cs.mcw * 0.5;
		mcLaser._y = -KadoKadeoManager.I(10);
	}

	public override function update() {
		timer += mt.Timer.tmod;
		var mod = 1;
		while (timer > mod && list.length > 0) {
			timer -= mod;
			var p = list.shift();
			Game.me.destroySquare(p[0], p[1]);

			var dx = Cs.MX + (p[0] + 0.5) * Cs.SIZE - mcLaser._x;
			var dy = Cs.MY + (p[1] + 0.5) * Cs.SIZE - mcLaser._y;
			var a = Math.atan2(dy, dx);
			mcLaser._rotation = a / 0.0174;
			mcLaser._xscale = Math.sqrt(dx * dx + dy * dy);
			Game.me.drawRainbowShade(mcLaser);

			KadoKadeoManager.kkm.addScore(Cs.SCORE_BREAK);

			if (list.length == 0)
				break;
		}

		if (list.length == 0)
			kill();

		super.update();
	}

	public override function kill() {
		Game.me.checkLines();
		mcLaser.removeMovieClip();
		super.kill();
	}
}
