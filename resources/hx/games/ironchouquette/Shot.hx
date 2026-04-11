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
	public var trg:{x:Float, y:Float, flDeath:Bool};
	public var thruster:{vx:Float, vy:Float, sleep:Float}
	public var queue:String;

	public function new(mc) {
		super(mc);

		va = 0.1;
		ca = 0.1;

		decal = 0;
		speed = 2 * Cs.NEW_GEN_SCALE;

		flPierce = false;
		flInvincible = false;
		ray = 3 * Cs.NEW_GEN_SCALE;
		damage = 0;
		Cs.game.shotList.push(this);
		bList = new Array();
		fadeType = 6; // alpha out
		fadeLimit = 10;
	}

	public override function update() {
		if (accel != null) {
			speed = Math.min(speed + accel.inc * Timer.tmod, accel.max);
		}

		checkCols();
		updateBehaviour();
		super.update();

		if (isOut(50 * Cs.NEW_GEN_SCALE))
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
							var da = getAng(trg) - a;
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
					if (Math.sqrt(vx * vx + vy * vy) < 3 * Cs.NEW_GEN_SCALE || Cs.rand() / Timer.tmod < 0.1) {
						a = Cs.random(4) * 1.57;
						vx = Math.cos(a) * speed;
						vy = Math.sin(a) * speed;
					}
				case 6: // PLASMA DRAW
					Cs.game.plasmaDraw(root, 0);
				case 7: // ACCEL
					speed += 0.05 * Cs.NEW_GEN_SCALE * Timer.tmod;
				case 11:
					var max = 2 * Game.PM;
					for (i in 0...max) {
						var p = new Part(Cs.game.dm.attach("partPlasmaBolt", Game.DP_PARTS));
						var a = Cs.rand() * 6.28;
						var r = Cs.rand() * 40;
						p.x = x + Math.cos(a) * r;
						p.y = y + Math.sin(a) * r;
						p.vy = -(1 + Cs.rand() + 6) * Cs.NEW_GEN_SCALE;
						// p.timer = 20+Math.random()*10;
						p.root._xscale = 150;
						p.root._yscale = p.root._xscale;
						p.root.blendMode = BlendModes.ADD;
						p.fadeType = 0;
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
				trg = cast b;
				dist = d;
			}
		}

		if (list.length > 0) {
			trg = cast list[Cs.random(list.length)];
		} else {
			trg = null;
		}
	}

	public function checkCols() {
		if (flGood) {
			var list = Cs.game.badsList;
			for (i in 0...list.length) {
				var b = list[i];
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
			if (h.invincibleTimer != null)
				return;
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
		b.hit(this);

		if (!flInvincible) {
			if (flPierce && hp < damage) {
				damage -= hp;
			} else {
				var mc = Cs.game.dm.attach("partImpact", Game.DP_PARTS);
				mc._x = x;
				mc._y = y;
				mc._xscale = 50 + damage * 100;
				mc._yscale = mc._xscale;
				mc._rotation = Cs.rand() * 360;
				mc.blendMode = BlendModes.ADD;
				kill();
				return;
			}
		}
	}

	public function onHit(bad) {}

	public function setSkin(n, d) {
		// TODO: root is maybe reassigned ? memory leak ?
		root = Cs.game.shots.layer[d].dm.attach("mcShot", 0);
		root.gotoAndStop(n);
		root.obj = this;
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
