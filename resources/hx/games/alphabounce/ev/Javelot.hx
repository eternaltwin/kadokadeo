package alphabounce.ev;

import mt.bumdum.Phys;

class Javelot extends Event {
	static var SPEED = 5;

	var mcJavelot:Mc;
	var x:Int;
	var y:Int;

	public function new() {
		super();
		x = Cs.getPX(Game.me.pad.x);
		y = Cs.YMAX + 4;

		mcJavelot = Game.me.dm.attach("javelot", Game.DP_PAD);
		mcJavelot._x = Cs.getX(x + 0.5);
		mcJavelot._y = Cs.getY(y);
		mcJavelot.blendMode = pixi.core.Pixi.BlendModes.ADD;

		Game.me.dm.under(mcJavelot);
	}

	override public function update() {
		super.update();

		for (i in 0...SPEED) {
			y--;
			var bl = Game.me.getBlock(x, y);
			if (bl != null) {
				bl.explode();
			}
		}

		mcJavelot._y = Cs.getY(y);

		var max = Std.int(3 + Cs.getPerfCoef() * 8);
		var hh = Cs.BH * SPEED;
		for (i in 0...max) {
			var p = new Phys(Game.me.dm.attach("light", Game.DP_PARTS));
			p.x = mcJavelot._x + (Seed.randVfx() * 2 - 1) * 10;
			p.y = mcJavelot._y + Seed.randVfx() * hh;
			p.vy = -Seed.randVfx() * hh * 0.75;
			p.timer = 10 + Seed.randVfx() * 20;
		}

		if (y < -14)
			kill();
	}

	override public function kill() {
		mcJavelot.removeMovieClip();
		super.kill();
	}
}
