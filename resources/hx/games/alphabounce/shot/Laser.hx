package alphabounce.shot;

// mcLaser: smc (a red bar of 6 x 100, its yscale grows to 44 and shrinks after the hit) and its outline
class Laser extends Shot {
	var flHit:Bool;
	var height:Float;
	var vit:Float;

	public function new(mc:ASprite) {
		super(mc);
		height = 44;
		root.smc._yscale = 0;
		flHit = false;
	}

	override public function update() {
		super.update();
		var sens = 1;
		if (flHit)
			sens = -1;
		root.smc._yscale = Num.mm(0, root.smc._yscale + vit * Timer.tmod * sens, height);
		if (flHit && root.smc._yscale == 0)
			kill();

		Game.me.plasmaDraw(root);
	}

	public function setVit(n:Float) {
		vit = n;
		vy = -n;
	}

	override public function hit() {
		flHit = true;
		vy = 0;
	}
}
