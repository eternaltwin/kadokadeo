package kanjisnightmare;

// kunai thrown to hang from the ceiling or under a platform
class Grap extends Sprite {
	public var flMain:Bool;
	public var flFly:Bool;
	public var vx:Float;
	public var vy:Float;
	public var speed:Int;

	public function new(mc:ASprite) {
		super(mc);
		flMain = true;
		flFly = true;
		vx = 0;
		vy = 0;
	}

	override public function update() {
		super.update();
		if (flFly) {
			for (i in 0...speed) {
				var oy = y;
				x += vx * Timer.tmod;
				y += vy * Timer.tmod;
				var flCol = y < 10;
				for (pl in Cs.game.platList) {
					if (pl.y + 12 < oy && pl.y + 12 > y && x > pl.x && x < pl.x + pl.w) {
						flCol = true;
						pl.grap = this;
						break;
					}
				}
				if (flCol) {
					flFly = false;
					var a = Math.atan2(vy, vx);
					var ray = 12;
					x = Cs.q(x - Math.cos(a) * ray);
					y = Cs.q(y - Math.sin(a) * ray);
					root.gotoAndStop(2);
					if (flMain)
						Cs.game.hero.grap();
					updatePos();
				}
			}
			if (y < 0) {
				if (flMain)
					Cs.game.hero.releaseGrap();
				kill();
			}
		} else {
			if (!flMain)
				kill();
		}
	}

	public function orient() {
		var sens = 1;
		if (vx < 0)
			sens = -1;
		root._xscale = sens * 100;
		root._rotation = Math.atan2(vy, vx) / 0.0174;
		if (vx < 0)
			root._rotation += 180;
	}

	public function drop() {
		flMain = false;
	}
}
