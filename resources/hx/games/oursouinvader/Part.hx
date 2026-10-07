package oursouinvader;

// Part.mt of the original
class Part extends Phys {
	public var timer:Null<Float>;
	public var fadeType:Null<Float>;
	public var fadeLimit:Float;

	public function new(mc:MC) {
		super(mc);
		Cs.game.pList.push(this);
		fadeLimit = 10;
		scale = 100;
	}

	override public function update() {
		super.update();

		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				// (switch (fadeType) { case 0: ... case 1: ... default: ... }: an unset fadeType fades the alpha)
				if (fadeType == 0) {
					root._xscale = scale * c;
					root._yscale = root._xscale;
				} else if (fadeType == 1) {
					root._yscale = scale * c;
				} else {
					root._alpha = c * 100;
				}
				if (timer < 0) {
					kill();
				}
			}
		}
	}

	override public function kill() {
		Cs.game.pList.remove(this);
		super.kill();
	}
}
