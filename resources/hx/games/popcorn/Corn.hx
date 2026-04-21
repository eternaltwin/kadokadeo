package popcorn;

import mt.bumdum.Lib.Num;
import popcorn.Game.GameAnimSprite;
import mt.Timer;

class Corn extends Phys {
	static var FRAME_MAX = 100;

	static var RAY = 5 * Cs.NEW_GEN_SCALE;

	var jumpTimer:Float;
	var frame:Float;

	public var step:Int;

	public function new(mc:ASprite) {
		mc = Cs.game.dm.attach("mcCorn", Game.DP_CORN);
		mc.stopOnFrame = [1, 100];
		Cs.game.cList.push(this);
		super(mc);

		weight = (0.14 + Cs.rand() * (0.1 + Cs.game.boss.escPop)) * Cs.NEW_GEN_SCALE;
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
						bouncer.px = Std.int(Num.mm((RAY + 3 * Cs.NEW_GEN_SCALE), bouncer.px, Cs.mcw - (RAY + 3 * Cs.NEW_GEN_SCALE)));
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
					Cs.game.ly = Math.min(Cs.game.ly, y - 30 * Cs.NEW_GEN_SCALE);
					vx = 0;
					vy = 0;
					weight = 0;
					removeBouncer();
					frame = 0;
					root._rotation = Cs.rand() * 360;
					Cs.game.stampPopcorn(x, y, root._rotation);
				}
			}
		}
	}

	public function explode(bx:Float, by:Float):Void {
		for (i in 0...12) {
			var p = Cs.game.newPart("mcCornDebris");
			var a = Cs.rand() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = (0.5 + Cs.rand() * 2) * Cs.NEW_GEN_SCALE;

			p.x = x + ca * RAY * Cs.rand();
			p.y = y + sa * RAY * Cs.rand();
			p.vx = ca * sp + bx * 0.5;
			p.vy = sa * sp + by * 0.5;
			p.setScale(50 + Cs.rand() * 50);
			p.timer = 10 + Cs.rand() * 10;
			p.weight = (0.05 + Cs.rand() * 0.1) * Cs.NEW_GEN_SCALE;
			p.fadeType = 0;
			p.root.gotoAndStop(Cs.random(root._totalframes) + 1);
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
