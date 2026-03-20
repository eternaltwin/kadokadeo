package kslash;

class Star extends Shoot {
	public var damage:Int;

	public function new(mc) {
		super(mc);
		Cs.game.nsList.push(this);
		// mc.getGraphics().beginFill(0xAA00DD, 0.5).drawRect(-Cs.SIZE / 2, -Cs.SIZE / 2, Cs.SIZE, Cs.SIZE);
		damage = 5;
	}

	public override function checkCol() {
		super.checkCol();
		if (x < 0 || x >= Game.XMAX || y < 0 || y >= Game.YMAX) {
			kill();
			return;
		}
		var list = Cs.game.grid[x][y].list;

		if (list.length > 0) {
			var m = list[0];
			m.hit(this);
			kill();
		}
	}

	public override function kill() {
		super.kill();
		Cs.game.nsList.remove(this);
	}
}
