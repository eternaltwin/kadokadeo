package happyptitank;

// (Option extends flash.display.Sprite; its subclasses are bound to the symbols of the options)
class Option extends MovieClip {
	public var start:Float;
	public var time:Float;
	public var end:Float;
	public var value:KKConst;
	public var ctime:Float;
	public var ftime:Float;
	public var dead:Bool;

	public function new(sym:Int) {
		super(sym, true);
		end = time = 0;
		ctime = Game.instance.now;
		ftime = ctime;
		dead = false;
		value = KKApi.const(50);
	}

	public function update(now:Float) {
		var life = Math.min(1, (now - ctime) / 10000) * 100;
		if (life < 80) {} else if (life >= 100) {
			dead = true;
			visible = false;
		} else if (now - ftime > 100) {
			visible = !visible;
			ftime = now;
		}
	}

	public function activate() {
		visible = true;
		start = Game.instance.now;
	}

	public function inactivate() {}
}
