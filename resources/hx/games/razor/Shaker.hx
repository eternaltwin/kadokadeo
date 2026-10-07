package razor;

// Shaker.hx of the original: a particle drawn at a random offset around its position (the scores of
// Game.FL_VISEW_SCORE, which is false: never created)
class Shaker extends Phys {
	public var shake:Float;

	public function new(mc:MC) {
		super(mc);
		shake = 3;
	}

	override public function updatePos() {
		root._x = x + (Seed.randVfx() * 2 - 1) * shake;
		root._y = y + (Seed.randVfx() * 2 - 1) * shake;
	}
}
