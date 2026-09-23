package bactery;

import kado.KadoKadeoManager;
import mt.Timer;
import pixi.filters.colormatrix.ColorMatrixFilter;

class Bille {
	var game:Game;

	public var mc:ASprite;
	public var t:Int;
	public var x:Int;
	public var y:Int;
	public var px:Float;
	public var py:Float;

	var dy:Float;

	public var group:Array<Bille>;

	public function new(g:Game, t:Int) {
		game = g;
		mc = game.dmanager.attach("bille", Const.PLAN_BLOCKS);
		setSkin(t);
	}

	public function select(b:Bool):Void {
		if (b) {
			var filter = new ColorMatrixFilter();
			var offset = -50 / 255;
			filter.matrix = [
				1, 0, 0, 0, offset,
				0, 1, 0, 0, offset,
				0, 0, 1, 0, offset,
				0, 0, 0, 1,      0
			];
			mc.filters = [filter];
		} else {
			mc.filters = null;
		}
	}

	public function setPos(x:Int, y:Int):Void {
		this.x = x;
		this.y = y;
		mc._x = x * Const.BSIZE + Const.PX;
		mc._y = y * Const.BSIZE + Const.PY;
		px = mc._x;
		py = mc._y;
		game.level.tbl[x][y] = this;
	}

	public function score():Void {
		switch (t) {
			case 0 | 1 | 2 | 3:
				mc.removeMovieClip();
				mc = null;
				KadoKadeoManager.kkm.addScore(Const.C150);
				game.stats.k++;
				var p = centerPart("partScore");
				p.skin.play();
				p.skin._rotation = Seed.randVfx() * 360;
				p.skin.removeOnFrame = 29;
				var p2 = centerPart("partRound");
				p2.skin.removeOnFrame = 6;
			case 9:
				mc.removeMovieClip();
				mc = null;
				var p3 = centerPart("partStoneBlast");
				p3.skin.removeOnFrame = 18;
				KadoKadeoManager.kkm.addScore(Const.C50);
				game.stats.w++;
			case 10:
				mc.removeMovieClip();
				mc = null;
				game.stats.m++;

				var ray = KadoKadeoManager.I(12);
				for (_ in 0...6) {
					var p = game.newPart("partMonster");
					var a = Seed.randVfx() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var sp = KadoKadeoManager.S(0.6 + Seed.randVfx() * 0.5);
					p.x = px + ca * ray;
					p.y = py + sa * ray;
					p.vitx = ca * sp;
					p.vity = sa * sp;
					p.timer = 10 + Seed.randVfx() * 10;
					p.init();
				}
				var p4 = centerPart("partDeath");
				p4.skin.removeOnFrame = 29;
			case 4:
				mc.removeMovieClip();
				mc = null;
				KadoKadeoManager.kkm.addScore(Const.C1000);
				game.stats.b++;
				var p = game.newPart("partAureole");
				p.x = px;
				p.y = py;
				p.scale = 50;
				p.vits = 20;
				p.timer = 20;
				p.fadeTypeList = [1];
				p.init();

				var p = centerPart("partBonusValue2");
				p.skin.removeOnFrame = 18;
				var compt = 20;
				p.skin.onFrame.set(12, () -> if (compt-- > 0) p.skin.gotoAndPlay(11));
		}
		if (t != Const.ID_MONSTER)
			game.flash(mc);
	}

	function centerPart(link:String):Part {
		var p = game.newPart(link);
		p.x = px;
		p.y = py;
		p.init();
		return p;
	}

	public function setSkin(t:Int):Void {
		this.t = t;
		mc.gotoAndStop(t + 1);
	}

	public function moveTo(x:Int, y:Int):Bool {
		var tx = x * Const.BSIZE + Const.PX;
		var ty = y * Const.BSIZE + Const.PY;
		var p = Math.pow(0.8, Timer.tmod);
		mc._x = mc._x * p + tx * (1 - p);
		py = py * p + ty * (1 - p);
		if (tx != px)
			mc._y = py + Math.sin((mc._x - px) * 3.14 / (tx - px)) * (tx < px ? KadoKadeoManager.I(10) : -KadoKadeoManager.I(10));
		else
			mc._y = py;

		var dx = mc._x - tx;
		var dy = mc._y - ty;
		var d = Math.sqrt(dx * dx + dy * dy);
		return d > KadoKadeoManager.I(1);
	}
}
