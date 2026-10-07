package spiroule;

// Runner.hx of the original: a spark running down the spiral (120 of them at the start of the game, only for the eye)
class Runner extends Phys {
	public var pos:Float;
	public var speed:Float;
	public var acc:Float;

	public var dx:Float;
	public var dy:Float;

	public function new() {
		var mc = Game.me.dm.attach("fxSpark", Game.DP_FX);
		super(mc);
		speed = 0;
		acc = 0;
		pos = 0;
		dx = (Seed.randVfx() * 2 - 1) * 8;
		dy = (Seed.randVfx() * 2 - 1) * 8;
	}

	override public function update():Void {
		speed += acc * Timer.tmod;
		if (frict != null)
			speed *= Math.pow(frict, Timer.tmod);
		pos += speed;
		if (pos < 0)
			pos = 0;

		var p = Cs.getPos(pos);

		x = p.x + dx;
		y = p.y + dy;

		super.update();
	}
}
