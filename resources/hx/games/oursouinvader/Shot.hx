package oursouinvader;

// Shot.mt of the original: 0 the hero's spike, 2 octopus, 3 bomber, 4 oyster (pearl), 5 boss (big pearl)
class Shot extends Phys {
	public var ray:Float;

	var deadLine:Float;

	public var sShot:Float;

	var sType:Int;

	var badShot:Bool;
	var bounce:Bool;

	var flDead:Bool;

	// (mc: always null) the original calls super() in the branch of its type, after setting badShot / bounce / flDead
	// and deadLine (-ray + 3 before ray is set: NaN, never read): the clip is attached first here, the fields are the
	// same
	public function new(mc:MC, type:Int) {
		super(Cs.game.dm.attach(type == 0 ? "mcSpike" : type == 2 ? "mcShootOcto" : type == 3 ? "mcShootBomber" : "mcShootPearl", 2));
		badShot = false;
		bounce = false;
		flDead = false;
		sType = type;

		// HERO single shot
		if (type == 0) {
			ray = 4;
			sShot = 5;
			vy = 0;
			vx = 0;
			vr = 0;
		}

		// OCTOPUSSY shot
		if (type == 2) {
			ray = 4;
			sShot = 5;
			vy = 0;
			vx = 0;
			vr = 0;
			badShot = true;
		}

		// Bomber shot
		if (type == 3) {
			ray = 4;
			sShot = 3;
			vy = 0;
			vx = 0;
			vr = 0;
			badShot = true;
		}

		// Oyster shot
		if (type == 4) {
			ray = 4;
			sShot = 1;
			vy = 0;
			vx = 0;
			vr = 0;
			badShot = true;
		}

		// Boss shot
		if (type == 5) {
			ray = 8;
			sShot = 8;
			vy = 0;
			vx = 0;
			vr = 0;
			badShot = true;
			root._xscale = 200;
			vr = 20;
		}

		Cs.game.shotList.push(this);
		deadLine = -ray + 3;
	}

	override public function update() {
		super.update();
		if (sType == 4) {
			sShot = sShot + (0.07 * sShot);
			vy = sShot;
		}
		checkShot();
		isKilling();
		reflect();
	}

	function isKilling() {
		// Enemy Shot
		if (badShot) {
			var hero = Cs.game.hero;
			var xmin = hero.x - hero.hWidth;
			var xmax = hero.x + hero.hWidth;
			var ymin = hero.y - hero.hHeight;
			var ymax = hero.y + hero.hHeight;
			if ((y >= ymin) && (y <= ymax)) {
				if ((x >= xmin) && (x <= xmax)) {
					Cs.game.hero.shooted(this);
					return;
				}
			}
		} else {
			// Hero Shot
			if (!flDead) {
				var list = Cs.game.monsterList;
				// (the length is read at each turn: a monster that explodes leaves the list, the next one takes its index)
				var i = 0;
				while (i < list.length) {
					var monster = list[i];
					var xmin = monster.x - monster.ray;
					var xmax = monster.x + monster.ray;
					var ymin = monster.y - monster.ray;
					var ymax = monster.y + monster.ray;

					if ((y >= ymin) && (y <= ymax)) {
						if ((x >= xmin) && (x <= xmax)) {
							if (!list[i].flDeath) {
								list[i].shooted();
							}

							// monsterList[i] again: when the monster has just exploded it is the next one (a closed oyster
							// there sends the shot back), or undefined after the last one (the shot is killed)
							var m = i < list.length ? list[i] : null;
							if (m != null && (m.mType == 4) && m.isClosed) {
								reBound();
							} else {
								kill();
								return;
							}
						}
					}
					i++;
				}
			}
		}
	}

	function reflect() {
		if ((x > 300) || (x < 0)) {
			root._rotation = -root._rotation;
			vx = -vx;
		}
	}

	// the shot bounces off a closed oyster: it no longer hits anything and its "dead" animation kills it (mcSpike frame
	// 20: obj.kill()); its new speed only moves the picture (the visual random)
	function reBound() {
		root.gotoAndPlay("dead");
		vx = Seed.randVfx() * 10;
		vy = Seed.randVfx() * -vy;
		flDead = true;
	}

	function checkShot() {
		if ((y < -10) || (y > 310))
			kill();
	}

	override public function kill() {
		Cs.game.shotList.remove(this);
		super.kill();
	}
}
