package kanjisadventure.ev;

class Shoot extends Event {
	public var shot:ASprite;

	var trg:Ent;
	var ent:Ent;

	public var dmg:Null<Int>;
	public var bhl:Array<Int>;

	public function new(e:Ent, t:Ent, ?d:Int) {
		ent = e;
		trg = t;
		dmg = d;
		super();
		var dx = trg.x - ent.x;
		var dy = trg.y - ent.y;
		spc = 0.5 / Math.sqrt(dx * dx + dy * dy);

		// black glow of the original baked in "mcShot"
		shot = Game.me.cfl.dm.attach("mcShot", kanjisadventure.Floor.DP_FX);
		shot.stop();
		shot._x = -10000;

		bhl = [0];
	}

	override function update() {
		super.update();
		shot._x = ((trg.x + 0.5) * coef + (ent.x + 0.5) * (1 - coef)) * Cs.CS;
		shot._y = ((trg.y + 0.5) * coef + (ent.y + 0.5) * (1 - coef)) * Cs.CS;
		shot._rotation += 16;
		if (coef == 0 || shot._prevState == null || shot._prevState.x < -5000)
			shot.updateState();

		if (coef == 1) {
			impact();
			kill();
		}
	}

	function impact() {
		shot.removeMovieClip();

		for (bh in bhl) {
			switch (bh) {
				case 0:
					trg.fxDamage(dmg);
					trg.hurt(dmg);
				case 1:
					trg.freeze();
			}
		}
	}

	override function kill() {
		Game.me.event = null;
		Game.me.gogogo();
	}
}
