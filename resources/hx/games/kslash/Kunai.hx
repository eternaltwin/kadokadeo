package kslash;

class Kunai extends Shoot {
	public function new(mc) {
		super(mc);
		Cs.game.sList.push(this);
	}

	public override function checkCol() {
		super.checkCol();
		if (!Cs.game.hero.flInvicible && Cs.game.hero.sTimer == null) {
			var dx = root._x - Cs.game.hero.root._x;
			var dy = root._y - Cs.game.hero.root._y;

			if (Math.sqrt(dx * dx + dy * dy) < 14) {
				Cs.game.hero.hit(this);
				kill();
			}
		}
	}

	public override function kill() {
		super.kill();
		Cs.game.sList.remove(this);
	}
}
