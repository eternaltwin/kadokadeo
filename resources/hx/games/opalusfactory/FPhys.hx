package opalusfactory;

// FPhys.hx of the original: a Phys that calls onEnd when it is killed
class FPhys extends Phys {
	public var onEnd:Void->Void;

	public function new(mc:MC) {
		super(mc);
	}

	override public function kill():Void {
		super.kill();
		if (onEnd != null)
			onEnd();
	}
}
