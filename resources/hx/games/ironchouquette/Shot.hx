package ironchouquette;

import mt.Timer;
import mt.bumdum.Lib;
import pixi.core.Pixi.BlendModes;

class Shot extends Phys {
	public var flGood:Bool;
	public var flPierce:Bool;
	public var flInvincible:Bool;
	public var flWarp:Bool;

	public var damage:Float;
	public var a:Float;
	public var decal:Float;
	public var va:Float;
	public var ca:Float;
	public var speed:Float;
	public var accel:{inc:Float, max:Float};

	public var bList:Array<Int>;

	public var op:{x:Float, y:Float}
	public var trg:Bads;
	public var thruster:{vx:Float, vy:Float, sleep:Float}
	public var queue:String;
	public var skin:Int;
	public var onKill:Void->Void;

	var alreadyHit = false;

	public function new(mc) {
		super(mc);

		va = 0.1;
		ca = 0.1;

		decal = 0;
		speed = KadoKadeoManager.I(2);

		flPierce = false;
		flInvincible = false;
		ray = KadoKadeoManager.I(3);
		damage = 0;
		Cs.game.shotList.push(this);
		bList = new Array();
		fadeType = 6; // alpha out
		fadeLimit = 10;
	}

	public override function update() {
		if (this.root == null) {
			kill();
			return;
		}

		if (accel != null) {
			speed = Math.min(speed + accel.inc * Timer.tmod, accel.max);
		}

		checkCols();
		updateBehaviour();
		super.update();

		if (isOut(KadoKadeoManager.I(50)))
			kill();

		/*
			updateBehaviour();
		 */
	}

	public function updateBehaviour() {
		for (n in 0...bList.length) {
			var id = bList[n];

			switch (id) {
				case 0: // BOMB
					root._rotation += vr * Timer.tmod;

				case 3: // HOMING
					if (sleep == null || sleep <= 0) {
						getNewBadTrg();
						if (trg != null) {
							var da = getAng({x: trg.x, y: trg.y}) - a;
							while (da > 3.14)
								da -= 6.28;
							while (da < -3.14)
								da += 6.28;
							a += Num.mm(-va, da * ca, va) * Timer.tmod;
							updateVit();
						}
					}
				case 4: // ONDULE
					decal = (decal + 43 * Timer.tmod) % 628;
					a += Math.cos(decal / 100) * 0.2 * Timer.tmod;
					updateVit();

				case 5: // SWARM
					if (Math.sqrt(vx * vx + vy * vy) < KadoKadeoManager.I(3) || Seed.rand() / Timer.tmod < 0.1) {
						a = Seed.random(4) * 1.57;
						vx = Math.cos(a) * speed;
						vy = Math.sin(a) * speed;
					}
				case 6: // PLASMA DRAW
					Cs.game.plasmaDraw(root, 0);
				case 7: // ACCEL
					speed += KadoKadeoManager.S(0.05) * Timer.tmod;
				case 11:
					var max = 2 * Game.PM;
					for (i in 0...max) {
						var p = new Part(Cs.game.dm.attach("partPlasmaBolt", Game.DP_PARTS));
						var a = Seed.randVfx() * 6.28;
						var r = Seed.randVfx() * 40;
						p.x = x + Math.cos(a) * r;
						p.y = y + Math.sin(a) * r;
						p.vy = -KadoKadeoManager.S(1 + Seed.randVfx() + 6);
						// p.timer = 20+Math.random()*10;
						p.root._xscale = 150;
						p.root._yscale = p.root._xscale;
						p.root.blendMode = BlendModes.ADD;
						p.fadeType = 0;
						// original: frame script of partPlasmaBolt frame 7 -> Part.incrust(1): stamped into plasma
						// layer 1 (ADD) and killed there, leaving the fading trail; frames 8-20 were never shown
						p.root.onFrame.set(7, function() {
							Cs.game.plasmaDraw(p.root, 1);
							p.kill();
						});
						p.root.play();
					}
				case _:
			}
		}

		if (thruster != null) {
			if (thruster.sleep == null) {
				vx += thruster.vx * Timer.tmod;
				vy += thruster.vy * Timer.tmod;
			} else {
				thruster.sleep -= Timer.tmod;
				if (thruster.sleep < 0)
					thruster.sleep = null;
			}
		}

		if (queue != null) {
			if (op != null) {
				var mc = Cs.game.dm.attach(queue, Game.DP_PARTS);
				mc._rotation = 180 + getAng(op) / 0.0174;
				mc._xscale = getDist(op);
				mc._x = x;
				mc._y = y;
				// mc.blendMode = BlendModes.ADD;
				if (timer != null)
					mc._alpha = Num.mm(0, 10 * timer, 100);
				Cs.game.plasmaDraw(mc, 0);

				mc.removeMovieClip();
			}
			op = {x: x, y: y + Game.SCROLL_SPEED * 3};
			/*
				var mc = Cs.game.dm.attach("queueRocket",Game.DP_PARTS);
				mc._rotation = 180+getAng(op)/0.0174;
				mc._xscale = getDist(op);
				mc._x = x;
				mc._y = y;
				op={x:x,y:y}
			 */
		}
	}

	public function updateVit() {
		vx = Math.cos(a) * speed;
		vy = Math.sin(a) * speed;
		orient();
	}

	public function getNewBadTrg() {
		var list = Cs.game.badsList;
		var dist = 1 / 0;
		trg = null;
		for (i in 0...list.length) {
			var b = list[i];
			var d = getDist({x: b.x, y: b.y});
			if (d < dist) {
				trg = b;
				dist = d;
			}
		}

		if (list.length > 0) {
			trg = list[Seed.random(list.length)];
		} else {
			trg = null;
		}
	}

	public function checkCols() {
		if (flGood) {
			var list = Cs.game.badsList;
			for (b in list) {
				if (b == null)
					continue;
				if (b.rect != null) {
					if (Math.abs(x - b.x) < (b.rect.rw + ray) && Math.abs(y - b.y) < (b.rect.rh + ray)) {
						hit(b);
					}
				} else {
					if (getDist({x: b.x, y: b.y}) < ray + b.ray) {
						hit(b);
					}
				}
			}
		} else {
			var h = Cs.game.hero;
			if (h.invincibleTimer != null) {
				if (!alreadyHit) {
					Cs.game.stats.sak[Hero.WP_LASER][Cs.game.stats.sak[Hero.WP_LASER].length - 1][1] += 1;
					alreadyHit = true;
				}
				return;
			}
			var dist = getDist({x: h.x, y: h.y});
			if (dist < Cs.game.hero.ray + ray) {
				Cs.game.hero.hit(this);
				kill();
			}
		}
	}

	public function hit(b) {
		onHit(b);
		var hp = b.hp;
		var isDead = b.hit(this);

		if (onKill != null && isDead) {
			onKill();
		}

		if (!flInvincible) {
			if (flPierce && hp < damage) {
				damage -= hp;
			} else {
				var mc = Cs.game.dm.attach("partImpact", Game.DP_PARTS);
				mc._x = x;
				mc._y = y;
				mc._xscale = 50 + damage * 100;
				mc._yscale = mc._xscale;
				mc._rotation = Seed.randVfx() * 360;
				mc.blendMode = BlendModes.ADD;
				mc.removeOnFrame = 14;
				mc.play();
				kill();
				return;
			}
		}
	}

	public function onHit(bad) {}

	public function setSkin(n, d) {
		var loop = true;
		switch (n) {
			case 14:
				root = Cs.game.shots.layer[d].dm.attach("mcShot14", 0);
				root.onFrame.set(1, () -> root._rotation = Seed.randVfx() * 360);
				root.onFrame.set(8, () -> root.gotoAndPlay(5));
			case 15 | 16 | 17 | 18 | 21:
				root = Cs.game.shots.layer[d].dm.attach("mcShot" + n, 0);
			case 19:
				root = Cs.game.shots.layer[d].dm.attach("mcShot19", 0);
				root.onFrame.set(5, () -> root.gotoAndPlay(3));
			case 22:
				root = Cs.game.shots.layer[d].dm.attach("mcShot22", 0);
				root.removeObjOnFrame = 8;
			case 23:
				root = Cs.game.shots.layer[d].dm.attach("mcShot23", 0);
				loop = false;
			case 13 | _:
				root = Cs.game.shots.layer[d].dm.attach("mcShot13", 0);
		}
		root.loop = loop;
		root.play();
		root.obj = this;
		skin = n;
		updatePos();
	}

	public function orient() {
		root._rotation = Math.atan2(vy, vx) / 0.0174;
	}

	public override function kill() {
		Cs.game.shotList.remove(this);
		super.kill();
	}
}
