package kanjisadventure.ent;

class Hero extends Ent {
	public var futurAction:Action;

	public var flFire:Bool;
	public var luck:Int;

	public function new() {
		super();
		flGood = true;
		flBad = false;
		flFire = false;
		Game.me.hero = this;
		lifeMax = 12;
		restX = 12;
		restY = 14.8;
		animFrames = 10;
		buildCaracs();
		init();
	}

	override function init() {
		super.init();
		Game.me.displayLife();
	}

	// CARACS
	public function buildCaracs() {
		flDoubleDamage = false;
		damageMin = 1;
		damageMax = 2;

		armor = 0;
		luck = 0;

		agility = 3;
		dodge = 4;

		// WEAPON
		switch (Game.me.weaponId) {
			case 1: // COUTEAU
				damageMax = 3;
			case 2: // KATANA
				damageMax = 5;
		}

		strikeId = Game.me.weaponId;

		// ARMOR
		switch (Game.me.armorId) {
			case 1: // LEATHER
				armor = 1;
				dodge -= 1;
			case 2: // METAL
				armor = 2;
				agility -= 1;
				dodge -= 2;
		}

		for (id in Game.me.inventory) {
			switch (id) {
				case 18: // AMULETTE ROUGE
					damageMin++;
					damageMax++;
				case 19: // AMULETTE VERTE
					dodge++;
				case 20: // AMULETTE BLEUE
					agility += 2;
				case 24: // PORTE BONHEUR
					luck += 5;
				case 33: // DEGATS !!
					flDoubleDamage = true;
				case 34: // ZIPPO !!
					flFire = true;
				default:
			}
		}

		if (life > lifeMax)
			life = lifeMax;
		Game.me.displayLife();
		Game.me.displayShuriken();
	}

	// walk clip of the direction with the weapon and the armor
	override function bodyName() {
		return "hero" + direction + "_" + Game.me.weaponId + "_" + Game.me.armorId;
	}

	override function bodyFrame() {
		return animFrame;
	}

	public function paint() {
		refreshBody();
	}

	override function checkMove() {
		if (futurAction == null)
			return;
		switch (futurAction) {
			case Goto(di):
				setAction(futurAction);
			default:
		}
	}

	override function checkAttack() {
		if (futurAction == null)
			return;
		switch (futurAction) {
			case Attack(di):
				setAction(futurAction);
			default:
		}
	}

	public function incLife(n:Int) {
		var d = lifeMax - life;
		if (n > d)
			n = d;
		life += n;
		Game.me.displayLife();
		Game.me.log("Vous guérissez " + n + " blessure(s).");
	}

	public function setFuturAction(ac:Action) {
		futurAction = ac;
	}

	override function hurt(n:Null<Int>) {
		super.hurt(n);
		Game.me.displayLife();
	}

	override function kill() {
		sq.fxLight();
		// the clip plays its "die" frames (tombstone) and stays
		if (root != null) {
			if (body != null)
				body.removeMovieClip();
			var tomb = root.attachMovie("heroDie", "smc", 1);
			tomb.stopOnFrame = [tomb._totalframes];
			tomb.play();
		}
		root = null;
		body = null;
		super.kill();
	}
}
