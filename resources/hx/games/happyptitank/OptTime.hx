package happyptitank;

// @:bind OptTime (symbol 213): 20 more seconds
class OptTime extends Option {
	public function new() {
		super(213);
		time = 20000;
	}

	override public function activate() {
		super.activate();
		Game.instance.endTime += 20000;
	}

	override public function inactivate() {
		var diff = Game.instance.now - start;
		var diff = Math.min(time, diff);
		Game.instance.endTime = Game.instance.endTime - 20000 + diff;
		Game.instance.optTimes = KKApi.cadd(Game.instance.optTimes, KKApi.const(Std.int(Math.round(diff / 1000))));
	}
}
