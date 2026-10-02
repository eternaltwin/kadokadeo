package magmax;

import common_haxe_avm1.display.BBox;
import mt.Timer;

class Tir {
	public var mc:ASprite;
	public var bbox:BBox;

	var game:Game;
	var fromMonster:Bool;
	var x:Float;
	var y:Float;
	var dx:Float;
	var dy:Float;

	public var pow:Int;

	public function new(g, t, x, y, dx, dy) {
		game = g;
		pow = 1;
		fromMonster = t == 1 || t == 2;
		this.x = x;
		this.y = y;
		this.dx = dx;
		this.dy = dy;
		mc = game.dmanager.attach("tir" + (t + 1), Cs.PLAN_TIR);
		mc.play();
		mc.loop = true;
		mc._x = x;
		mc._y = y;
		mc._rotation = Math.atan2(dy, dx) * 180 / Math.PI;
		bbox = mc.attachBBox(switch (t) {
			case 0:
				new BBox(KadoKadeoManager.I(-11), KadoKadeoManager.I(-6), KadoKadeoManager.I(20), KadoKadeoManager.I(14));
			case 1:
				new BBox(KadoKadeoManager.S(-9.5), KadoKadeoManager.S(-9.25), KadoKadeoManager.I(19), KadoKadeoManager.S(18.5));
			case 2:
				new BBox(KadoKadeoManager.S(-7.5), KadoKadeoManager.S(-7.5), KadoKadeoManager.I(15), KadoKadeoManager.I(15));
			case 3:
				new BBox(KadoKadeoManager.I(-13), KadoKadeoManager.S(-13.25), KadoKadeoManager.S(25.5), KadoKadeoManager.I(26));
			case _:
				throw 'Unknown tir type: $t';
		});
	}

	public function update() {
		x += dx * Timer.tmod;
		y += dy * Timer.tmod;
		mc._x = x;
		mc._y = y;

		if (fromMonster) {
			if (game.hero.mc.col.hitTestBbox(bbox))
				game.gameOver();
		} else {
			var i;
			var l = game.monsters;
			for (m in l) {
				if (m.mc.sub.col.hitTestBbox(bbox)) {
					m.touched(this);
					mc.removeMovieClip();
					return false;
				}
			}
		}

		if (x < KadoKadeoManager.I(-10) || y < KadoKadeoManager.I(-10) || x > KadoKadeoManager.I(310) || y > KadoKadeoManager.I(310)) {
			mc.removeMovieClip();
			return false;
		}
		return true;
	}
}
