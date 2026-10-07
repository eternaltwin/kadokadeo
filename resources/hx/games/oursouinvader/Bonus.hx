package oursouinvader;

// Bonus.mt of the original: 0 - 2 points, 3 speed, 4 triple shot, 5 fire rate, 6 shield bubble
class Bonus extends Phys {
	static var STATS = [10, 3, 1, 6, 6, 6, 1];

	var ray:Float;

	public var bType:Int;

	// (mc: always null)
	public function new(mc:MC) {
		super(Cs.game.dm.attach("mcBonus", 2));
		ray = 4;
		vy = 2;

		bType = getRandomId();
		root.gotoAndStop(bType + 1);

		Cs.game.bonusList.push(this);
	}

	override public function update() {
		super.update();
		checkdeadLine();
		isTaken();
	}

	function isTaken() {
		var h = Cs.game.hero;
		var adx = Math.abs(h.x - x);
		var ady = Math.abs(h.y - y);
		if (adx < h.hWidth + ray && ady < h.hHeight + ray)
			applyBonus();
	}

	function applyBonus() {
		switch (bType) {
			case 0, 1, 2:
				var score = Cs.SCORE_BONUS[bType];
				Cs.game.addScore(score);
				Cs.game.dispScore(score, x, y);
			case 3:
				Cs.game.hero.speed = 8;
			case 4:
				Cs.game.hero.type = 2;
			case 5:
				Cs.game.hero.fireRate = 10;
			case 6:
				Cs.game.hero.initBubble();
		}
		Cs.game.hero.flasher();
		#if debug
		Cs.game.stats.bonus[bType]++;
		#end
		kill();
	}

	function checkdeadLine() {
		if (y > 310)
			kill();
	}

	function getRandomId():Int {
		var max = 0;
		for (i in 0...STATS.length)
			max += STATS[i];
		var rand = Seed.random(max);
		var sum = 0;
		for (i in 0...STATS.length) {
			sum += STATS[i];
			if (sum > rand)
				return i;
		}
		return null;
	}

	override public function kill() {
		Cs.game.bonusList.remove(this);
		super.kill();
	}
}
