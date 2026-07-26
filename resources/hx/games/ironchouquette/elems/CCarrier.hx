package ironchouquette.elems;

// frame 17
class CCarrier extends Bads {
	var bonusId:Int;
	var bonusDir:Int;

	public function new() {
		var root = Cs.game.dm.attach("carrierBody", Game.DP_BADS);
		super(root);

		var reactor1 = root.attachMovie("badReactor");
		reactor1._rotation = -90;
		reactor1.loop = true;
		reactor1.play();

		var reactor2 = root.attachMovie("badReactor");
		reactor2._rotation = -90;
		reactor2.loop = true;
		reactor2.play();
		reactor2._xscale = -100;

		setLevel(10);
		setScore(Cs.C0);
		hp = 3;
		ray = KadoKadeoManager.I(20);
		waitTimer = 300;

		speed = KadoKadeoManager.I(6);
		a = 1.57;
		va = 0.5;
		turnCoef = 0.15;
		flOrient = true;
		bList = [3];
		onTargetReach = () -> {
			chooseNewTarget(KadoKadeoManager.I(20), Cs.mcw - KadoKadeoManager.I(20), KadoKadeoManager.I(30), KadoKadeoManager.I(190));
		};
		onTargetReach();
		bonusId = Bonus.getRandomId();
		bonusDir = Seed.random(2);

		onDeath = () -> {
			dropBonus(bonusId, bonusDir);
		};
	}
}
