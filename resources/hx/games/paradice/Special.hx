package paradice;

// Special.mt of the original: a flame thrower (sid 0), a bomb (1) or three grenades (2), carried like a ball
// (Flamer.mt, an older copy of this class also named Special, is not used by the game)
class Special extends Ball {
	public var sid:Int;

	public function new() {
		super();
	}

	override public function setSkin(mc:MC) {
		super.setSkin(mc);
		mc.sub("b").gotoAndStop(30 + sid);
	}
}
