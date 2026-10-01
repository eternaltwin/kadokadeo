package kanjisadventure.ent;

class Bad extends Ent {
	public var flEatable:Bool;
	public var flUndead:Bool;
	public var flChaos:Bool;

	var bid:Int;
	var lastDir:Null<Int>;

	public var swapDir:Null<Int>;

	var seek:Int;

	public var bhAtt:AttackBehaviour;
	public var bhMove:MoveBehaviour;

	public function new(bid:Int) {
		super();
		seek = 0;
		flBad = true;
		flEatable = false;
		flUndead = false;
		flChaos = false;
		restX = 11.9;
		restY = 17;
		setType(bid);
		init();
		strikeId = 0;
	}

	override function setFloor(fl:Floor) {
		if (floor != null)
			floor.bads.remove(this);
		super.setFloor(fl);
		floor.bads.push(this);
	}

	override function checkAttack() {
		if (flFreeze)
			return;
		if (action != null)
			return;
		if (swapDir != null)
			return;

		var trgList = getTrgList(sq);
		if (trgList.length > 0) {
			var rdi = trgList[Seed.random(trgList.length)];
			switch (bhAtt) {
				case BStick:
					setAction(Attack(rdi));
				case BRandom(c):
					if (Seed.rand() < c)
						setAction(Attack(rdi));
			}
		}
	}

	override function checkMove() {
		if (flFreeze)
			return;
		if (action != null)
			return;
		if (swapDir != null) {
			setAction(Goto(swapDir));
			swapDir = null;
			return;
		}

		var moveList = [];
		var di = 0;
		for (d in Cs.DIR) {
			var next = floor.getSquare(sq.x + d[0], sq.y + d[1]);
			if (next != null && next.isFree())
				moveList.push(di);
			di++;
		}

		if (moveList.length > 0) {
			var rdi = moveList[Seed.random(moveList.length)];
			var bh = bhMove;

			var hdi = getHeroDist();
			if (hdi <= seek && !bh.match(BCoward) && !flChaos)
				bh = BHunt;

			switch (bh) {
				case BNormal(c):
					var fdi = rdi;
					if (Seed.rand() < c) {
						for (di in moveList)
							if (di == lastDir)
								fdi = di;
					}
					setAction(Goto(fdi));
					lastDir = fdi;
				case BErratic(c):
					if (Seed.rand() < c)
						setAction(Goto(rdi));

				case BHunt:
					if (flBad && hdi <= 2) {
						var fa = Game.me.hero.futurAction;
						if (fa != null && fa.match(Goto(_)) && Seed.random(hdi) == 0)
							return;
					}

					if (flGood) {
						if (Seed.random(Std.int(Math.pow(hdi, 2))) == 0)
							return;
					}
					var fdi = rdi;

					var d = Cs.DIR[fdi];
					var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
					var rh = sq2.heat;
					for (di in moveList) {
						var d = Cs.DIR[di];
						var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
						if (lessHeat(sq2.heat, rh)) {
							rh = sq2.heat;
							fdi = di;
						}
					}
					setAction(Goto(fdi));

				case BCoward:
					var fdi = rdi;
					var d = Cs.DIR[fdi];
					var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
					var rh = sq2.heat;
					for (di in moveList) {
						var d = Cs.DIR[di];
						var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
						if (moreHeat(sq2.heat, rh)) {
							rh = sq2.heat;
							fdi = di;
						}
					}
					setAction(Goto(fdi));
			}
		}
	}

	// comparisons of the original with null heats (AS2: null < n and n < null are false, null was the "else" case)
	static inline function lessHeat(h:Null<Int>, rh:Null<Int>) {
		return rh == null || (h != null && h < rh);
	}

	static inline function moreHeat(h:Null<Int>, rh:Null<Int>) {
		return h == null || (rh != null && h > rh);
	}

	// --- TYPE ---
	public function setType(id:Int) {
		bid = id;
		switch (bid) {
			case 0: // CACA
				bhMove = BNormal(0.1);
				bhAtt = BRandom(0.5);
				agility = 1;
				dodge = 3;
				lifeMax = 2;
				damageMax = 2;
				seek = 2;

			case 1: // ORK
				flEatable = true;
				bhMove = BNormal(0.6);
				bhAtt = BStick;
				agility = 2;
				dodge = 2;
				lifeMax = 4;
				damageMax = 3;
				seek = 3;

			case 2: // INSECT
				bhMove = BNormal(0.1);
				bhAtt = BStick;
				agility = 3;
				dodge = 4;
				damageMax = 2;
				lifeMax = 2;
				seek = 10;

			case 3: // SKELETTONS
				flUndead = true;
				bhMove = BNormal(0.5);
				bhAtt = BStick;
				agility = 3;
				dodge = 3;
				lifeMax = 3;
				damageMax = 5;
				seek = 3;

			case 4: // HYDRA
				flEatable = true;
				bhMove = BNormal(0.2);
				bhAtt = BStick;
				agility = 4;
				dodge = 2;
				damageMin = 2;
				damageMax = 4;
				lifeMax = 8;
				seek = 3;

			case 5: // ZOMBI
				flUndead = true;
				bhMove = BNormal(0.3);
				bhAtt = BStick;
				agility = 2;
				dodge = 1;
				damageMax = 5;
				lifeMax = 12;
				seek = 10;

			case 6: // WARRIOR
				flEatable = true;
				bhMove = BNormal(0.8);
				bhAtt = BStick;
				agility = 4;
				dodge = 4;
				damageMin = 2;
				damageMax = 6;
				lifeMax = 6;
				seek = 4;

			case 7: // SORCERER
				flUndead = true;
				bhMove = BNormal(0.2);
				bhAtt = BStick;
				agility = 3;
				dodge = 7;
				damageMin = 1;
				damageMax = 10;
				lifeMax = 5;
				seek = 5;

			case 20: // OURS
				flEatable = true;
				flGood = true;
				flBad = false;
				bhMove = BNormal(0);
				bhAtt = BStick;
				agility = 3;
				dodge = 3;
				damageMin = 2;
				damageMax = 5;
				lifeMax = 10;
				seek = 10;

			case 21: // DOG
				flEatable = true;
				flGood = true;
				flBad = false;
				bhMove = BNormal(0);
				bhAtt = BStick;
				agility = 4;
				dodge = 6;
				damageMin = 1;
				damageMax = 3;
				lifeMax = 3;
				seek = 10;

			default:
		}
	}

	//
	override function bodyName() {
		return "bad" + bid;
	}

	override function bodyFrame() {
		return direction + 1;
	}

	override function attach() {
		super.attach();
		if (flChaos) {
			Filt.glow(root, 8, 2, 0xFFFFFF);
			Filt.glow(root, 4, 4, 0xAA00FF);
		}
	}

	//
	override function die() {
		if (flBad) {
			// DROP
			if (sq.itemId == null) {
				var gid = getDrop();
				if (gid != null) {
					sq.addItem(gid);
					sq.showItem();
				}
			}
			// SCORE
			var sc = (bid + 1) * Cs.SCORE_MONSTER;
			KadoKadeoManager.kkm.addScore(sc);
			sq.fxScore(sc);
		}
		// the clip plays its "die" frames (sinks into the floor) then removes itself
		if (root != null) {
			if (body != null)
				body.removeMovieClip();
			var mc = root.attachMovie("badDie" + bid, "smc", 1);
			mc.removeOnFrame = mc._totalframes;
			mc.play();
		}
		root = null;
		body = null;

		super.die();
	}

	public function getDrop():Null<Int> {
		switch (bid) {
			case 0:
				if (Seed.random(2) == 0)
					return null; // CACA -> RIEN
			case 3:
				if (Seed.random(10) == 0)
					return 32; // SQUELETTE -> OS
			case 4:
				if (Seed.random(10) == 0)
					return 29; // HYDRA -> TELEPORT
			case 6:
				if (Seed.random(100) == 0)
					return 8; // WARRIOR -> KATANA
		}

		// FOOD
		if (flEatable && Seed.random(12) == 0) {
			return 10;
		}

		// GOLD
		var gid = 1;
		var rnd = 10 - (Game.me.hero.luck + bid);
		if (rnd < 1)
			rnd = 1;
		if (Seed.random(rnd) == 0)
			gid++;
		if (Seed.random(10 + rnd) == 0)
			gid++;
		return gid;
	}

	// TEXT
	override function getName() {
		return Lang.getBadName(bid);
	}

	//
	public function setChaos() {
		flChaos = true;
		bhMove = BErratic(0.7);
		sq.fxChaos();
		display();
	}

	//
	override function kill() {
		super.kill();
		floor.bads.remove(this);
	}

	//
	public function getTrgList(sq:Square):Array<Int> {
		var a = [];
		var di = 0;
		for (d in Cs.DIR) {
			var next = floor.getSquare(sq.x + d[0], sq.y + d[1]);
			if (next != null && next.ent != null) {
				if (flBad && (next.ent.flGood || flChaos))
					a.push(di);
				if (flGood && next.ent.flBad)
					a.push(di);
			}
			di++;
		}
		return a;
	}
}
