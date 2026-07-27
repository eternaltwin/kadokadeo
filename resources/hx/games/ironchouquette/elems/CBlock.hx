package ironchouquette.elems;

// frame 20
class CBlock extends Bads {
	public function new() {
		var root = Cs.game.dm.empty(Game.DP_BADS);
		super(root);
		var body = root.attachMovie("blockBody", 0);

		var reactor = root.attachMovie("blockReactor", "react", -1);
		reactor.loop = true;
		reactor.play();
		reactor._y = -KadoKadeoManager.I(66);

		var p1 = root.attachMovie("blockp1", 1);
		p1.loop = true;
		p1.play();
		p1._x = -KadoKadeoManager.I(42);
		p1._y = -KadoKadeoManager.I(45);

		var p2 = root.attachMovie("blockp2", 1);
		p2.loop = true;
		p2.play();
		p2._x = -KadoKadeoManager.I(28);
		p2._y = KadoKadeoManager.I(6);

		var p3 = root.attachMovie("blockp3", 1);
		p3.loop = true;
		p3.play();
		p3._x = KadoKadeoManager.I(6);
		p3._y = -KadoKadeoManager.I(27);

		var p4 = root.attachMovie("blockp4", 1);
		p4.loop = true;
		p4.play();
		p4._x = KadoKadeoManager.I(35);
		p4._y = KadoKadeoManager.I(37);

		var p5 = root.attachMovie("blockp5", 1);
		p5.loop = true;
		p5.play();
		p5._x = -KadoKadeoManager.I(20);
		p5._y = KadoKadeoManager.I(65);

		var p6 = root.attachMovie("blockp6", 1);
		p6.loop = true;
		p6.play();
		p6._x = -KadoKadeoManager.I(39);
		p6._y = -KadoKadeoManager.I(61);

		var p7 = root.attachMovie("blockp7", 1);
		p7.loop = true;
		p7.play();
		p7._x = -KadoKadeoManager.I(37);
		p7._y = -KadoKadeoManager.I(58);

		setLevel(6);
		setScore(Cs.C_BLOCK);
		hp = 30;
		// rect = {rw:45,rh:66}
		setRect(KadoKadeoManager.I(45), KadoKadeoManager.I(66));
		y = -rect.rh;
		Cs.game.dm.under(root);
	}
}
