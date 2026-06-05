package kanjisnightmare;

import mt.Timer;
import mt.bumdum.Lib.Num;
import mt.bumdum.Sprite;

class Grap extends Sprite {
	var flMain:Bool;

	public var flFly:Bool;

	var long:Float;

	public var vx:Float;
	public var vy:Float;
	public var speed:Int;

	public function new(mc) {
		super(mc);

		flMain = true;
		flFly = true;
	}

	public override function update() {
		super.update();

		if (flFly) {
			for (i in 0...speed) {
				var oy = y;

				x = Num.q(x + vx * Timer.tmod);
				y = Num.q(y + vy * Timer.tmod);

				var flCol = Num.q(y) < Cs.S(10);

				for (n in 0...Cs.game.platList.length) {
					var pl = Cs.game.platList[n];
					var py = Num.q(pl.y + Cs.S(12));
					var px = Num.q(x);
					if (py < Num.q(oy) && py > Num.q(y) && px > Num.q(pl.x) && px < Num.q(pl.x + pl.w)) {
						flCol = true;
						pl.grap = this;
						break;
					}
				}

				if (flCol) {
					flFly = false;

					var ray = Cs.S(12);
					var speed = Num.q(Math.sqrt(vx * vx + vy * vy));
					if (speed > 0) {
						x = Num.q(x - (vx / speed) * ray);
						y = Num.q(y - (vy / speed) * ray);
					}
					root.gotoAndStop(2);
					// long = GP_DIST;//getDist(Cs.game.hero)*0.5

					if (flMain)
						Cs.game.hero.grap();

					updatePos();
				}
			}

			if (Num.q(y) < 0) {
				if (flMain) {
					Cs.game.hero.releaseGrap();
				}
				kill();
			}
		} else {
			if (!flMain) {
				/*
					var m = new flash.geom.Matrix();
					m.scale(root._xscale/100,root._yscale/100);
					m.rotate(root._rotation*0.0174);
					m.translate(x,y);
					Cs.game.mcCaveTop.bmp.draw(root,m,null,null,null,null);
				 */
				kill();
			}
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
