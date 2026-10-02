package kslash;

class Star extends Shoot {
	public var damage:Float;

	public function new(mc:Clip) {
		super(mc);
		Cs.game.nsList.push(this);
		damage = 5;
	}

	override public function checkCol() {
		super.checkCol();
		var list = Cs.game.gridList(x, y);

		if (list != null && list.length > 0) {
			var m = list[0];
			m.hit(this);
			kill();
		}
	}

	override public function kill() {
		super.kill();
		Cs.game.nsList.remove(this);
	}
}
