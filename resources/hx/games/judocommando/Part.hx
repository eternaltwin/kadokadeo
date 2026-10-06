package judocommando;

// the pieces of brick, wood and dust of Game.newShard (entities: they bounce on the level, pure pictures)
class Part extends Ent {
	public var timer:Float;
	public var fadeLimit:Float;
	public var fadeType:Int;
	public var vr:Null<Float>;
	public var fvr:Null<Float>;

	public function new(mc:MC) {
		super(mc);
		fadeLimit = 10;

		type = PART;
	}

	override function update() {
		super.update();

		if (vr != null)
			root._rotation += vr;
		if (fvr != null)
			vr *= fvr;

		timer--;
		if (timer < fadeLimit) {
			var c = timer / fadeLimit;

			switch (fadeType) {
				case 0:
					root._visible = Std.int(timer / 3) % 2 == 1;
				case 1:
					root._alpha = c * 100;
				default:
			}

			if (timer < 0) {
				kill();
			}
		}
	}

	override function onCollision(sx:Int, sy:Int) {
		super.onCollision(sx, sy);
		vr *= -0.75;
	}
}
