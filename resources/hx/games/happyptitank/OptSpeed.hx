package happyptitank;

// @:bind OptSpeed (symbol 211): a faster tank
class OptSpeed extends Option {
	static var FACTOR = 1.5;

	public function new() {
		super(211);
		time = 5000;
	}

	override function activate() {
		super.activate();
		Game.instance.tank.maxSpeed *= FACTOR;
	}

	override function inactivate() {
		Game.instance.tank.maxSpeed /= FACTOR;
	}
}
