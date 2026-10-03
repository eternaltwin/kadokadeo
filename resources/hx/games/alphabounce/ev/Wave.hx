package alphabounce.ev;

class Wave extends Event {
	var mcWave:Mc;
	var y:Int;

	public function new() {
		super();
		y = Cs.YMAX - 1;
		mcWave = Game.me.dm.attach("wave", Game.DP_PARTS);
	}

	override public function update() {
		super.update();

		for (i in 0...2) {
			y--;
			for (x in 0...Cs.XMAX) {
				var bl = Game.me.getBlock(x, y);
				if (bl != null) {
					bl.damage(0, 1);
				}
			}
		}

		mcWave._y = Cs.getY(y);
		if (y < -2)
			kill();
	}

	override public function kill() {
		mcWave.removeMovieClip();
		super.kill();
	}
}
