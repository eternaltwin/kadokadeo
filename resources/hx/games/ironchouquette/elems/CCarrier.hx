package ironchouquette.elems;

// frame 17
class CCarrier extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("carrierBody", Game.DP_BADS);
		super(root);

		var reactor1 = root.attachMovie("badReactor");
		reactor1.loop = true;
		reactor1.play();

		var reactor2 = root.attachMovie("badReactor");
		reactor2.loop = true;
		reactor2.play();
		reactor2._xscale = -100;

		setLevel(10);
		setScore(Cs.C0);
		hp = 3;
		ray = 20 * Cs.NEW_GEN_SCALE;
		waitTimer = 300;

		speed = 6 * Cs.NEW_GEN_SCALE;
		a = 1.57;
		va = 0.5;
		turnCoef = 0.15;
		flOrient = true;
		bList = [3];
		onTargetReach = () -> {
			chooseNewTarget(20 * Cs.NEW_GEN_SCALE, Cs.mcw - 20 * Cs.NEW_GEN_SCALE, 30 * Cs.NEW_GEN_SCALE, 190 * Cs.NEW_GEN_SCALE);
		};
		onTargetReach();

		onDeath = () -> {
			dropBonus();
		};
	}
}
