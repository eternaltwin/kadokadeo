package elloninthedark;

class Bonus extends Phys {
	public static var SPEED = KadoKadeoManager.S(1.5);
	public static var MX = KadoKadeoManager.I(11);
	public static var MY = KadoKadeoManager.I(15);

	public static var STATS = [
		200, // FIREBALL
		200, // PINK BEAM
		200, // PLASMA
		0, 0, 0, 0, 0, 0, 0,
		100, // BOMB
		100, // TENTACULE
		100, // HOMING
		0, 0, 0, 0, 0, 0, 0,
		400, // BONUS VERT
		200, // BONUS BLEU
		20, // BONUS ROUGE
		0, 0, 0, 0, 0, 0, 0,
		100, // BUILD
		300, // SPEED UP
		50 // SHIELD
	];

	public var id:Int;

	// the card face (frame id+1 of the "mcCard" clip) is baked in "mcBonus<frame>"
	public function new() {
		var id = getRandomId();
		var h = Cs.game.hero;
		if (id == 30 && h.flBuild)
			id = 21;
		if (id == 31 && h.flSpeedUp)
			id = 21;
		if (id == 32 && h.flShield)
			id = 21;
		super(Cs.game.mdm.attach("mcBonus" + (id + 1), Game.DP_BONUS));
		this.id = id;
		// cards flip, score orbs (card stopped on its first frame) keep turning
		root.loop = true;
		root.play();

		vx = -SPEED;
		vy = (Seed.random(2) * 2 - 1) * SPEED * 1.5;

		frict = 1;
	}

	override public function update() {
		super.update();
		//
		if (y < MY || y > Cs.GL - MY) {
			vy *= -1;
			y = Num.mm(MY, y, Cs.GL - MY);
		}
		if (x < MX) {
			vx *= -1;
			x = MX;
		}
		if (y > Cs.mcw + MX) {
			kill();
		}
		//
		var help = KadoKadeoManager.I(10);
		if (Math.abs(Cs.game.hero.x - x) < MX + help && Math.abs(Cs.game.hero.y - y) < MY + help) {
			take();
		}
	}

	public function take() {
		var h = Cs.game.hero;
		Cs.game.stats.b.push(id);
		var score:Null<Int> = null;
		switch (id) {
			case 0 | 1 | 2:
				if (h.shotType == id) {
					h.shotPower = Std.int(Math.min(h.shotPower + 1, 2));
				} else {
					h.shotType = id;
				}
			case 10 | 11 | 12:
				h.takeSide(id - 10);
			case 20:
				score = Cs.C1000;
			case 21:
				score = Cs.C3000;
			case 22:
				score = Cs.C10000;
			case 30:
				h.flBuild = true;
			case 31:
				h.initSpeedUp();
			case 32:
				h.initShield();
		}
		if (score != null) {
			Cs.game.spawnScore(x, y, KKApi.val(score));
			KadoKadeoManager.kkm.addScore(score);
		}

		kill();
	}

	public static function getRandomId():Int {
		var sum = 0;
		for (i in 0...STATS.length)
			sum += STATS[i];
		var rand = Seed.random(sum);
		sum = 0;
		for (i in 0...STATS.length) {
			sum += STATS[i];
			if (sum > rand)
				return i;
		}
		return 0;
	}
}
