package cookinglili;

import cookinglili.Level;

class McSprite extends ASprite {
	public var ice:ASprite;
}

class Token {
	var game:Game;

	public var mc:McSprite;
	public var id:Int;
	public var combo:T_Combo;
	public var fall:Int;
	public var moveDist:Float;
	public var explDelay:Int;
	public var x:Int;
	public var y:Int;
	public var fl_armor:Bool;

	public var mul:Int;

	public function new(g, i) {
		game = g;
		fall = 0;
		explDelay = -1;
		fl_armor = false;
		setId(i);
	}

	public function setId(i) {
		id = i;
		if (id < 3)
			mul = 1;
		else
			mul = 2 + id - 3;
	}

	public function attach(x, y) {
		if (mc == null) {
			mc = cast game.dm.attach("token", Cs.DP_TOKENS);
			mc.gotoAndStop(id + 1);
			mc.ice = mc.attachMovie("fx_ice_break");
			mc.ice._rotation = Seed.randomVfx(360);
			mc._rotation = Seed.randomVfx(4) * 90;
			mc._alpha = Seed.randomVfx(15) + 85;
			mc._x += KadoKadeoManager.S(Seed.randomVfx(4)) * (Seed.randomVfx(2) * 2 - 1);
			mc._y += KadoKadeoManager.S(Seed.randomVfx(2)) * (Seed.randomVfx(2) * 2 - 1);
			//			mc.blendMode = "screen";
		}
		mc._x = Level.x_token(x);
		mc._y = Level.y_token(y);
		//		mc._width = Cs.TWID;
		//		mc._height = Cs.THEI;
		mc.ice._visible = fl_armor;
		if (fl_armor) {
			//			mc._alpha = 70;
		}
	}

	public function debug() {
		return mc._name;
	}
}
