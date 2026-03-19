package kslash;

class Star extends Shoot {
	public var damage:Int;

	public function new(mc) {
		super(mc);
		Cs.game.nsList.push(this);
		damage = 5;
	}

	public override function checkCol() {
		super.checkCol();
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
