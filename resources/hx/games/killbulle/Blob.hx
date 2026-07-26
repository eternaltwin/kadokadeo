package killbulle;

import kado.KadoKadeoManager;
import pixi.filters.colormatrix.ColorMatrixFilter;
import kado.Seed;
import mt.Timer;
import mt.bumdum.Lib;

class Blob {
	public var game:Game;
	public var x:Float;
	public var y:Float;
	public var dx:Float;
	public var dy:Float;
	public var speed:Float;
	public var size:Float;
	public var dir:Int;
	public var bonus:Null<Bonus>;
	public var mc:ASprite;
	public var col:ASprite;

	public function new(g:Game, size:Float, b:Null<Bonus>) {
		game = g;
		bonus = b;
		this.size = size;
		speed = KadoKadeoManager.S(5 + game.level / 20);
		y = -KadoKadeoManager.I(100);
		dx = 2.5;
		dy = 1;
		dir = Seed.random(2) * 2 - 1;
		x = game.hero.x + dir * KadoKadeoManager.I(50);
		mc = game.dmanager.attach("blob", Cs.PLAN_BLOB);
		col = mc.attachMovie("blobCol", "col");
		col.play();
		col.loop = true;
		mc.play();
		mc.loop = true;
		mc._xscale = size;
		mc._yscale = size;
		setColor(mc);
	}

	public function setColor(mc:ASprite):Void {
		var rb = bonus != null ? 150 : 40;
		var gb = bonus != null ? 10 : 30;
		var filter = new ColorMatrixFilter();
		filter.matrix = [
			0.82,    0,    0, 0,  rb / 255,
			   0, 0.86,    0, 0,  gb / 255,
			   0,    0, 0.52, 0, -51 / 255,
			   0,    0,    0, 1,         0
		];
		col.filters = [filter];
	}

	public function hit():Void {
		game.blobs.remove(this);
		var e = game.dmanager.attach("animExplose", Cs.PLAN_BLOB);
		e.play();
		e.removeOnFrame = 13;
		e._x = x;
		e._y = y;
		e._xscale = size / 2;
		e._yscale = size / 2;
		setColor(e);
		game.level++;

		mc.removeMovieClip();
		var dsize = size / 2;
		if (size == 150)
			dsize = 100;
		if (size >= 25 && bonus == null) {
			var b;
			b = new Blob(game, dsize, null);
			b.x = x + KadoKadeoManager.S(size) / 4;
			b.y = y;
			b.dy = -Math.abs(dy);
			b.dir = 1;
			b.update();
			game.blobs.push(b);

			b = new Blob(game, dsize, null);
			b.x = x - KadoKadeoManager.S(size) / 4;
			b.y = y;
			b.dy = -Math.abs(dy);
			b.dir = -1;
			b.update();

			game.blobs.push(b);
		} else {
			if (bonus != null) {
				bonus.fall();
			}
			game.tsize -= size;
		}
	}

	public function update():Bool {
		dy = Num.q(dy + 0.9 * Timer.tmod);
		var s = speed / 15 * Timer.tmod;
		x = Num.q(x + dir * dx * s);
		y = Num.q(y + dy * s);

		if (y > Cs.MINY - KadoKadeoManager.S(size) / 2) {
			y = Cs.MINY - KadoKadeoManager.S(size) / 2;
			dy = Num.q(-20 - Math.sqrt(size));
		}

		if (x < KadoKadeoManager.S(size) / 2) {
			x = KadoKadeoManager.S(size) - x;
			dir *= -1;
		} else if (x > Cs.WIDTH - KadoKadeoManager.S(size) / 2) {
			x = Cs.WIDTH * 2 - KadoKadeoManager.S(size) - x;
			dir *= -1;
		}

		if (bonus != null) {
			bonus.mc._x = x;
			bonus.mc._y = y;
		}
		mc._x = x;
		mc._y = y;
		return true;
	}
}
