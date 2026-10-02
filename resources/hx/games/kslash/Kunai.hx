package kslash;

class Kunai extends Shoot {
	public function new(mc:Clip) {
		super(mc);
		// (a second time: the kunai is updated twice per frame, like in the original)
		Cs.game.sList.push(this);
	}

	override public function checkCol() {
		super.checkCol();
		var hero = Cs.game.hero;
		if (!hero.flInvicible && hero.sTimer == null) {
			var dx = root._x - hero.root._x;
			var dy = root._y - hero.root._y;

			if (Math.sqrt(dx * dx + dy * dy) < 14) {
				hero.hit(this);
				kill();
			}
		}
	}

	override public function kill() {
		super.kill();
		Cs.game.sList.remove(this);
	}
}
