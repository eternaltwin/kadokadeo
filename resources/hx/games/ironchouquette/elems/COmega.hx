package ironchouquette.elems;

import mt.Timer;

// frame 1
class COmega extends Bads {
	public var turn:ASprite;
	public var eye:ASprite;

	public function new() {
		var root = Cs.game.dm.empty(Game.DP_BADS);
		super(root);
		turn = root.attachMovie("omegaTurn", 0);
		var body = root.attachMovie("omegaBody", 1);

		eye = root.attachMovie("omegaEye", 2);
		eye.loop = true;
		eye.play();

		eye._y = 15;

		setLevel(1.6);
		setScore(Cs.C_OMEGA);

		hp = 1;
		var raf = newRafale();
		raf.addShot(1, [3, 0.6], 100, 1);
		shootTimer = 150 + Cs.rand() * 500;

		turnSpeed = 2 + Cs.rand() * 6;
	}

	public override function update() {
		turn._rotation += vy * Timer.tmod * 2.5;
		super.update();
	}
}
