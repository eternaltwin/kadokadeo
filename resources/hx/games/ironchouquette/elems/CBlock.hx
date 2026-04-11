package ironchouquette.elems;

// frame 20
class CBlock extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("blockBody", Game.DP_BADS);
		super(root);

		var reactor = root.attachMovie("blockReactor");
		reactor.loop = true;
		reactor.play();
		reactor._y = -66 * Cs.NEW_GEN_SCALE;

		var p1 = root.attachMovie("blockp1");
		p1.loop = true;
		p1.play();
		p1._x = -42 * Cs.NEW_GEN_SCALE;
		p1._y = -45 * Cs.NEW_GEN_SCALE;

		var p2 = root.attachMovie("blockp2");
		p2.loop = true;
		p2.play();
		p2._x = -28 * Cs.NEW_GEN_SCALE;
		p2._y = 6 * Cs.NEW_GEN_SCALE;

		var p3 = root.attachMovie("blockp3");
		p3.loop = true;
		p3.play();
		p3._x = 6 * Cs.NEW_GEN_SCALE;
		p3._y = -27 * Cs.NEW_GEN_SCALE;

		var p4 = root.attachMovie("blockp4");
		p4.loop = true;
		p4.play();
		p4._x = 35 * Cs.NEW_GEN_SCALE;
		p4._y = 37 * Cs.NEW_GEN_SCALE;

		var p5 = root.attachMovie("blockp5");
		p5.loop = true;
		p5.play();
		p5._x = -20 * Cs.NEW_GEN_SCALE;
		p5._y = 65 * Cs.NEW_GEN_SCALE;

		var p6 = root.attachMovie("blockp6");
		p6.loop = true;
		p6.play();
		p6._x = -39 * Cs.NEW_GEN_SCALE;
		p6._y = -61 * Cs.NEW_GEN_SCALE;

		var p7 = root.attachMovie("blockp7");
		p7.loop = true;
		p7.play();
		p7._x = -37 * Cs.NEW_GEN_SCALE;
		p7._y = -58 * Cs.NEW_GEN_SCALE;

		setLevel(6);
		setScore(Cs.C_BLOCK);
		hp = 30;
		// rect = {rw:45,rh:66}
		setRect(45 * Cs.NEW_GEN_SCALE, 66 * Cs.NEW_GEN_SCALE);
		y = -rect.rh;
		Cs.game.dm.under(root);
	}
}
