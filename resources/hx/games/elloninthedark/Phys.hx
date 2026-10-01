package elloninthedark;

class Phys extends Sprite {
	public var ray:Float;

	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;

	public function new(mc:ASprite) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
	}

	override public function update() {
		super.update();

		if (weight != null) {
			vy += weight * Timer.tmod;
		}

		if (frict != null) {
			var f = Math.pow(frict, Timer.tmod);
			vx *= f;
			vy *= f;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
	}

	public function speedToward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Num.mm(-lim, dx * c, lim);
		vy += Num.mm(-lim, dy * c, lim);
	}

	public function genGroundSmoke() {
		var p = new Part(Cs.game.mdm.attach("partSmoke", Game.DP_PARTS));
		p.x = x + (Seed.randVfx() * 2 - 1) * KadoKadeoManager.S(8);
		p.y = y + ray;
		p.vx = -Cs.SCROLL_SPEED * 3 + (Seed.randVfx() * 2 - 1) * KadoKadeoManager.S(4);
		p.timer = 10 + Seed.randVfx() * 10;
		p.root._rotation = Seed.randVfx() * 360;
		p.root.stopOnFrame = [4];
		p.root.play();
	}
}
