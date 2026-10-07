package happyptitank;

// @:bind TheEnd (symbol 41): the big missile at the end of the time
class TheEnd extends MovieClip implements Anim {
	var time:Float;
	var duration:Float;

	public function new(?sym:Int = 41) {
		super(sym);
		gotoAndStop(1);
		time = 0;
		duration = 6;
		Game.root.addChild(this);
	}

	public function update():Bool {
		time += Timer.deltaT;
		var delta = Math.min(1, time / duration);
		gotoAndStop(1 + Math.floor(delta * totalFrames));
		if (delta >= 1)
			return false;
		return true;
	}
}

// @:bind YouDie (symbol 32): the tank destroyed
class YouDie extends TheEnd {
	public function new() {
		super(32);
		duration = 0.8;
	}
}
