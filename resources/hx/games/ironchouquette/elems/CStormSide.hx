package ironchouquette.elems;

// frame 12
class CStormSide extends Bads {
	public function new(lvl:Int, sens:Int) {
		var root = Cs.game.dm.attach("stormSide" + Std.string(lvl), Game.DP_BADS);
		super(root);

		root.play();

		setLevel(2 + lvl);
		flSide = true;
		root._xscale = sens * 100;
		hp = 8 + lvl * 6;
		ray = 20 * Cs.NEW_GEN_SCALE;

		//
		var raf = newRafale();
		raf.addShot(0, [12, 19], 12, 1 + lvl);
		raf.cooldown = 150;
		shootTimer = 150;
	}
}
