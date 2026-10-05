package popcorn;

import mt.bumdum.Lib.Num;
import popcorn.Game.GameAnimSprite;
import mt.Timer;

class Corn extends Phys {
	static var FRAME_MAX = 100;

	static var RAY = KadoKadeoManager.I(5);

	var jumpTimer:Float;
	var frame:Float;

	public var step:Int;

	public function new(mc:ASprite) {
		mc = Cs.game.dm.attach("mcCorn", Game.DP_CORN);
		mc.stopOnFrame = [1, 100];
		Cs.game.cList.push(this);
		super(mc);

		weight = KadoKadeoManager.S(0.14 + Seed.rand() * (0.1 + Cs.game.boss.escPop));
		frict = 0.95;

		step = 0;
	}

	override public function update():Void {
		super.update();

		switch (step) {
			case 0:
				if (y > Cs.game.ly) {
					bouncer = new RoundBouncer(this);
					bouncer.onBounceAngle = this.col;
					step = 1;
				}
				var m = RAY * 2.7;
				if (x < m || x > Cs.mcw - m) {
					x = Num.mm(m, x, Cs.mcw - m);
					vx *= -1;
				}
			case 1:
				if (jumpTimer != null) {
					jumpTimer -= Timer.tmod;
				}

				if (bouncer == null) {
					//
					frame = Math.min(frame + 15 * Timer.tmod, FRAME_MAX);
					root.gotoAndStop(Std.int(frame) + 1);

					//
					var m = new pixi.core.math.Matrix.Matrix();
					Cs.game.lvl.draw(root, m);
					if (root._currentframe == root._totalframes) {
						kill();
					}
				} else if (bouncer is RoundBouncer) {
					var b:RoundBouncer = cast bouncer;
					while (b.isRoundFree(bouncer.px, bouncer.py) != null) {
						bouncer.px = Std.int(Num.mm((RAY + KadoKadeoManager.I(3)), bouncer.px, Cs.mcw - (RAY + KadoKadeoManager.I(3))));
						bouncer.py--;
					}
				}
		}

		if (y > Cs.HEIGHT)
			kill();
	}

	public function col(a:Float, n:Float):Void {
		if (jumpTimer == null) {
			jumpTimer = 30;
		} else {
			if (jumpTimer < 0 && Math.abs(Num.hMod(1.57 - n, 3.14)) < 1.57) {
				if (Cs.game.hero.trg == this) {
					Cs.game.hero.releaseJump();
				} else {
					Cs.game.ly = Math.min(Cs.game.ly, y - KadoKadeoManager.I(30));
					vx = 0;
					vy = 0;
					weight = 0;
					removeBouncer();
					frame = 0;
					root._rotation = Seed.rand() * 360;
					Cs.game.stampPopcorn(x, y, root._rotation);
					Cs.game.stats.e.push(1);
				}
			}
		}
	}

	public function explode(bx:Float, by:Float):Void {
		for (i in 0...12) {
			var p = Cs.game.newPart("mcCornDebris");
			var a = Seed.randVfx() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = KadoKadeoManager.S(0.5 + Seed.randVfx() * 2);

			p.x = x + ca * RAY * Seed.randVfx();
			p.y = y + sa * RAY * Seed.randVfx();
			p.vx = ca * sp + bx * 0.5;
			p.vy = sa * sp + by * 0.5;
			p.setScale(50 + Seed.randVfx() * 50);
			p.timer = 10 + Seed.randVfx() * 10;
			p.weight = KadoKadeoManager.S(0.05 + Seed.randVfx() * 0.1);
			p.fadeType = 0;
			p.root.gotoAndStop(Seed.randomVfx(root._totalframes) + 1);
		}

		var impact:GameAnimSprite = cast Cs.game.dm.attach("mcImpact", Game.DP_PART);
		impact._x = x;
		impact._y = y;
		impact.frame = 0;
		impact.fs = 9;
		impact.play();
		Cs.game.animator.push(impact);

		kill();
	}

	override public function kill():Void {
		Cs.game.cList.remove(this);
		super.kill();
	}
}
