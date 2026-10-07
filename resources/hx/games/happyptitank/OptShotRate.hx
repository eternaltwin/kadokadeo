package happyptitank;

// @:bind OptShotRate (symbol 205): shoots twice as often
class OptShotRate extends Option {
	public function new() {
		super(205);
		time = 15000;
	}

	override public function activate() {
		super.activate();
		Game.instance.shotRate /= 2;
	}

	override public function inactivate() {
		Game.instance.shotRate *= 2;
	}
}
