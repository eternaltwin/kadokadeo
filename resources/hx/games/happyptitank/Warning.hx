package happyptitank;

// @:bind Warning (symbol 62)
class Warning extends MovieClip implements Anim {
	static var DURATION = 1;

	var time:Float;
	var duration:Float;

	public function new(?sym:Int = 62) {
		super(sym);
		x = (Game.W - width) / 2;
		y = 50;
		time = 0;
		duration = 1;
		Game.instance.addChild(this);
		Game.instance.addAnimation(this);
	}

	public function update():Bool {
		time += Timer.deltaT;
		var delta = Math.min(duration, time) / duration;
		gotoAndStop(1 + Math.floor(totalFrames * delta));
		if (delta >= 1) {
			if (parent != null)
				parent.removeChild(this);
			return false;
		}
		return true;
	}
}

// @:bind Rainbow1 (symbol 54): "zone cleared"
class Rainbow1 extends Warning {
	public function new() {
		super(54);
		x = Game.W / 2;
		y = Game.H;
		duration = 1;
	}
}
