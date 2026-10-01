package elloninthedark;

class Part extends Phys {
	public var timer:Null<Float>;
	public var fadeType:Null<Int>;
	public var fadeLimit:Float;
	public var scale:Float;
	public var vr:Null<Float>;

	public function new(mc:ASprite) {
		super(mc);
		Cs.game.pList.push(this);
		fadeLimit = 10;
		scale = 100;
	}

	override public function update() {
		super.update();
		if (vr != null) {
			if (frict != null)
				vr *= frict;
			root._rotation += vr * Timer.tmod;
		}
		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				switch (fadeType) {
					case 0:
						root._xscale = scale * c;
						root._yscale = root._xscale;
					case _:
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
