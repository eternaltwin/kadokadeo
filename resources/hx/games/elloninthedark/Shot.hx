package elloninthedark;

class Shot extends Phys {
	public var bList:Array<Int>;
	public var op:{x:Float, y:Float};
	public var flGood:Bool;
	public var flPierce:Bool;
	public var flInvincible:Bool;

	public var damage:Float;

	public var timer:Null<Float>;
	public var a:Float;
	public var decal:Float;
	public var vr:Float;
	public var va:Float;
	public var ca:Float;
	public var speed:Float;

	public var trg:Bads;

	public function new() {
		super(Cs.game.mdm.attach("mcShot1", Game.DP_SHOT));
		root.stop();
		flPierce = false;
		flInvincible = false;
		ray = KadoKadeoManager.I(4);
		damage = 0;
		bList = new Array();
	}

	override public function update() {
		super.update();
		updateBehaviour();
		checkCols();

		//
		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < 10) {
				root._alpha = 10 * timer;
				if (timer < 0) {
					kill();
				}
			}
		}
		// REBOND EXCEPTION
		if (ray > KadoKadeoManager.S(15) && y > Cs.GL - ray) {
			vy *= -1;
			y = Cs.GL - ray;
		}
	}

	public function updateBehaviour() {
		for (n in 0...bList.length) {
			var id = bList[n];

			switch (id) {
				case 0: // BOMB
					root._rotation += vr * Timer.tmod;
					if (y > Cs.GL) {
						onHit(null);
						kill();
					}

				case 1: // PAILLETTES
					for (i in 0...2) {
						var p = new Part(Cs.game.mdm.attach("partBurn", Game.DP_PARTS));
						var a = Seed.randVfx() * 6.28;
						var d = Seed.randVfx() * ray;
						p.x = x + Math.cos(a) * d;
						p.y = y + Math.sin(a) * d;
						p.frict = 0.92;
						p.vx = vx * (0.5 * Seed.randVfx() * 0.3);
						p.vy = vy * (0.5 * Seed.randVfx() * 0.3);
						p.timer = 10 + Seed.randVfx() * 10;
						p.scale = 50 + Seed.randVfx() * 100;
						p.root._xscale = p.scale;
						p.root._yscale = p.scale;
						p.root.stopOnFrame = [16];
						p.root.play();
					}

				case 2: // QUEUE
					if (op != null) {
						var mc = Cs.game.mdm.attach("partQueue", Game.DP_PARTS);
						mc._rotation = getAng(op) / 0.0174;
						mc._xscale = Cs.u(getDist(op));
						mc._x = x;
						mc._y = y;
						mc.removeOnFrame = 9;
						mc.play();
					}
					op = {x: x, y: y};

				case 3: // HOMING
					if (trg == null || trg.flDeath)
						getNewBadTrg();
					if (trg != null) {
						var da = getAng(trg) - a;
						while (da > 3.14)
							da -= 6.28;
						while (da < -3.14)
							da += 6.28;
						a += Num.mm(-va, da * ca, va) * Timer.tmod;
						updateVit();
						if (x > Cs.GL - ray) {
							x = Cs.GL - ray;
							vx *= -1;
						}
					}

				case 4: // ONDULE
					decal = (decal + 43 * Timer.tmod) % 628;
					a += Math.cos(decal / 100) * 0.2;
					updateVit();
			}
		}
	}

	public function updateVit() {
		vx = Math.cos(a) * speed;
		vy = Math.sin(a) * speed;
		orient();
	}

	public function getNewBadTrg() {
		var list = Cs.game.badsList;
		if (list.length > 0) {
			trg = list[Seed.random(list.length)];
		} else {
			trg = null;
		}
	}

	public function checkCols() {
		if (flGood) {
			var list = Cs.game.badsList;
			var i = 0;
			while (i < list.length) {
				var b = list[i];
				if (getDist(b) < ray + b.ray) {
					onHit(b);
					var hp = b.hp;
					b.hit(this);
					if (!flInvincible) {
						if (flPierce && hp < damage) {
							damage -= hp;
						} else {
							kill();
							return;
						}
					}
				}
				i++;
			}
		} else {
			var h = Cs.game.hero;
			var dist = getDist(h);
			if (h.flShield) {
				var max = ray + KadoKadeoManager.I(30);
				if (dist < max) {
					var d = (max - dist);
					var a = getAng(h);
					x -= Math.cos(a) * d;
					y -= Math.sin(a) * d;
				}
			} else {
				if (dist < Cs.game.hero.ray + ray) {
					Cs.game.hero.hit(this);
					kill();
				}
			}
		}

		// BOUNDS
		var m = KadoKadeoManager.I(30) + ray;
		if (x < -m || x > Cs.mcw + m || y < -m || y > Cs.GL + m) {
			this.kill();
		}
	}

	public function onHit(bad:Bads) {
		for (n in 0...bList.length) {
			var id = bList[n];
			switch (id) {
				case 0: // BOMB
					var list = Cs.game.badsList;
					var i = 0;
					while (i < list.length) {
						var b = list[i];
						if (b != bad) {
							if (getDist(b) < b.ray + ray + KadoKadeoManager.I(36)) {
								b.hit(this);
							}
						}
						i++;
					}
					var p = new Part(Cs.game.mdm.attach("partBombExplosion", Game.DP_PARTS));
					p.x = x;
					p.y = y;
					p.vx = -Cs.SCROLL_SPEED;
					p.frict = null;
					p.updatePos();
					p.root.onFrame.set(27, () -> p.kill());
					p.root.play();
			}
		}
	}

	// skins = frames of the original "mcShot" clip, flattened as "mcShot<n>" animations
	public function setSkin(n:Int) {
		var old = root;
		root = Cs.game.mdm.attach("mcShot" + n, Game.DP_SHOT);
		root._x = old._x;
		root._y = old._y;
		root._rotation = old._rotation;
		root._xscale = old._xscale;
		root._yscale = old._yscale;
		root._alpha = old._alpha;
		old.removeMovieClip();
		switch (n) {
			case 1 | 7:
				root.stop();
			case 6: // laser: stop() at the end of its growth
				root.stopOnFrame = [5];
				root.play();
			case 10: // gotoAndPlay(2) on its last frame
				root.onFrame.set(9, () -> root.gotoAndPlay(2));
				root.play();
			case _:
				root.loop = true;
				root.play();
		}
	}

	public function orient() {
		root._rotation = Math.atan2(vy, vx) / 0.0174;
	}
}
