package alphabounce;

class Shot extends Element {
	var damage:Float;

	public function new(mc:ASprite) {
		super(mc);
		damage = 1;
	}

	override function onBounce(px:Int, py:Int) {
		Game.me.hit(px, py, -1, damage);
		hit();
	}

	public function hit() {
		kill();
	}
}
