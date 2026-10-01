package kanjisadventure.ent;

class Trader extends Ent {
	public function new() {
		super();
		flTrader = true;
		lifeMax = 5;
		restX = 12;
		restY = 17;
		init();
	}

	override function bodyName() {
		return "trader";
	}

	override function die() {
		var id = 3;
		if (Seed.random(5) == 0)
			id = 4;
		sq.addItem(id);
		sq.showItem();

		// "die" frames: sinks into the floor then removes itself
		if (root != null) {
			if (body != null)
				body.removeMovieClip();
			var mc = root.attachMovie("traderDie", "smc", 1);
			mc.removeOnFrame = mc._totalframes;
			mc.play();
		}
		root = null;
		body = null;

		super.die();
	}
}
