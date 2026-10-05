package paradice;

// Part.mt of the original
class Part extends Phys {
	public var timer:Null<Float>;
	public var fadeType:Null<Float>;
	public var fadeLimit:Float;
	public var scale:Float;
	public var vr:Null<Float>;

	public function new(mc:MC) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
	}

	override public function update() {
		super.update();
		if (vr != null) {
			vr *= frict;
			root._rotation += vr * Timer.tmod;
		}
		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				// (switch (fadeType) { case 0: ... default: ... }: an unset fadeType fades the alpha)
				if (fadeType == 0) {
					root._xscale = scale * c;
					root._yscale = root._xscale;
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
		super.kill();
	}
}
