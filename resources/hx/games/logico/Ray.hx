package logico;

// (never created: the code attaching mcRay in Game.updateCombo is commented out in the original)
class Ray extends Phys {
	var vys:Float;

	public function new(mc:MC) {
		super(mc);
		vys = 1 + Seed.randVfx() * 5;
	}

	override public function update():Void {
		super.update();
	}
}
