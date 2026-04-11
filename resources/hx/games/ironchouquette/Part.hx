package ironchouquette;

class Part extends Phys {
	public function new(mc) {
		super(mc);
		Cs.game.pList.push(this);
		fadeLimit = 10;
		scale = 100;
	}

	public override function kill() {
		Cs.game.pList.remove(this);
		super.kill();
	}
}
