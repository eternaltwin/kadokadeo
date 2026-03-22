package kslash;

class Kunai extends Shoot {
	public override function checkCol() {
		super.checkCol();
		if (!Cs.game.hero.flInvicible && Cs.game.hero.sTimer == null) {
			var dx = root._x - Cs.game.hero.root._x;
			var dy = root._y - Cs.game.hero.root._y;

			if (Math.sqrt(dx * dx + dy * dy) < 14 * Cs.NEW_GEN_SCALE) {
				Cs.game.hero.hit(this);
				kill();
			}
		}
	}
}
