package ironchouquette.elems;

// frame 8
class CCutty extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("cuttyBody", Game.DP_BADS);
		super(root);

		var reactor1 = root.attachMovie("badReactor");
		reactor1._visible = false;
		reactor1.loop = true;
		reactor1.play();
		reactor1._rotation = -90;
		reactor1._x = KadoKadeoManager.I(-7);

		var reactor2 = root.attachMovie("badReactor");
		reactor2._visible = false;
		reactor2.loop = true;
		reactor2.play();
		reactor2._rotation = -90;
		reactor2._x = KadoKadeoManager.I(-7);
		reactor2._xscale = -100;

		root.onFrame.set(7, function() {
			if (!reactor1._visible) {
				reactor1._visible = true;
				reactor2._visible = true;
			}
		});

		setLevel(7);
		setScore(Cs.C_CUTTY_CLOSE);
		score2 = Cs.C_CUTTY_OPEN;

		vr = (Seed.random(2) * 2 - 1) * (5 + Seed.rand() * 10);
		hp = 14;
		va = 0.07;
		turnCoef = 0.1;
		bounceId = 0;
		speed = KadoKadeoManager.S(4.5);
		bList = [8];
	}
}
