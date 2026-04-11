package ironchouquette;

class Part extends Phys {
	public function new(mc) {
		super(mc);
		Cs.game.pList.push(this);
		fadeLimit = 10;
		scale = 100;
	}

	public function incrust(n) {
		trace("DEAD CODE ? incrust() in Part.hx");
		// Cs.game.plasmaDraw(root, 1);
		// kill();
	}

	public override function kill() {
		Cs.game.pList.remove(this);
		super.kill();
	}
}
