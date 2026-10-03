package alphabounce.fx;

import mt.bumdum.Phys;

class Part extends Phys {
	public var bouncer:Bouncer;

	public function new(mc:ASprite) {
		super(mc);
		bouncer = new Bouncer(this);
	}

	override public function update() {
		super.update();
		x -= vx * Timer.tmod;
		y -= vy * Timer.tmod;
		bouncer.update();
		updatePos();
	}
}
