package elloninthedark;

class Medusa extends Bads {
	public var speedDecal:Float;

	public function new(mc:ASprite) {
		super(mc, 10);
		ray = KadoKadeoManager.I(10);
		hp = 60;
		// root.stop() in the original: the tentacles keep moving (nested clips)
		root.loop = true;
		root.play();
		frict = 0.98;
		score = Cs.SCORE_MEDUSA;
		gid = 8;
		speedDecal = 0;
		speed = KadoKadeoManager.S(1.5);
		x = Cs.mcw + ray + KadoKadeoManager.I(5);
		y = ray + Seed.rand() * (Cs.GL + ray * 2);
	}

	override public function update() {
		super.update();
		speed *= 1.002;
		speedDecal = (speedDecal + (Cs.u(speed) * 13.5) * Timer.tmod) % 628;

		var h = Cs.game.hero;
		var sp = speed + Math.cos(speedDecal / 100) * KadoKadeoManager.S(6);

		var a = getAng(h);

		var dx = Math.cos(a) * sp - vx;
		var dy = Math.sin(a) * sp - vy;

		var c = 0.3;
		var lim = 1 / 0;
		vx += Num.mm(-lim, dx * c, lim) * Timer.tmod;
		vy += Num.mm(-lim, dy * c, lim) * Timer.tmod;

		checkGround();
		bounceFamily();
	}
}
