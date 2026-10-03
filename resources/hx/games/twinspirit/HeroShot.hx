package twinspirit;

class HeroShot extends Phys {
	public var damage:Float;

	public function new(mc:ASprite) {
		super(mc);
		damage = 1;
		ray = 4;
		Game.me.shots.push(this);
	}

	override public function update() {
		checkCols();

		if (x < -ray || x > Cs.mcw + ray || y < -ray || y > Cs.mch + ray) {
			kill();
		}

		super.update();
	}

	function checkCols() {
		var px = Cs.getPX(x);
		var py = Cs.getPY(y);

		for (bad in Game.me.badCell(px, py).copy()) {
			var dx = (bad.x - x);
			var dy = (bad.y - y) / bad.scy;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist < ray + bad.ray) {
				bad.impact(this);
				kill();
			}
		}
	}

	override public function kill() {
		Game.me.shots.remove(this);
		super.kill();
	}

	public function fxImpact() {
		var mc = Game.me.dm.attach("impact", Game.DP_FX);
		mc.removeAfter = true;
		mc._x = x + (Seed.randVfx() * 2 - 1) * 4;
		mc._y = y + (Seed.randVfx() * 2 - 1) * 4;
		mc._rotation = Seed.randVfx() * 360;
	}

	public function fxBounce(bad:Bad) {
		var mc = Game.me.dm.attach("bounce", Game.DP_FX);
		mc.removeAfter = true;
		mc._x = x;
		mc._y = y;
		mc._rotation = Seed.randVfx() * 306;
	}
}
