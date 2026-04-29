package starfang;

import mt.bumdum.Part;
import mt.bumdum.Lib.Num;
import mt.Timer;

class Shot extends Phys {
	var op:{x:Float, y:Float};
	var flInvincible:Bool;
	var trg:Bads;

	public var thruster:{vx:Float, vy:Float, sleep:Float};
	public var bList:Array<Int>;
	public var flGood:Bool;
	public var flPierce:Bool;
	public var va:Float;
	public var ca:Float;
	public var flWarp:Bool;
	public var ft:Int;
	public var damage:Float;
	public var a:Float;
	public var decal:Float;
	public var speed:Float;
	public var queue:String;

	public function new(mc) {
		super(mc);
		root.stop();
		flPierce = false;
		flInvincible = false;
		ray = 4 * Cs.NEW_GEN_SCALE;
		damage = 0;
		ft = 0;
		Cs.game.shotList.push(this);
		bList = new Array();
	}

	override function update() {
		var oldTimer = timer;
		timer = null;
		super.update();
		timer = oldTimer;
		if (flWarp)
			checkWarp();
		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < 10) {
				switch (ft) {
					case 0:
						root._alpha = 10 * timer;

					case 3:
						root._xscale = 10 * timer;
						root._yscale = 10 * timer;
				}
				if (timer < 0) {
					timer = null;
					switch (ft) {
						case 1:
							fxOnde(ray * 2 + 40 * Cs.NEW_GEN_SCALE);
							fxExplode(ray * 2 + 20 * Cs.NEW_GEN_SCALE);
							kill();

						case 2:
							root.gotoAndPlay(8);

						case _:
							kill();
					}
				}
			}
		}
		checkCols();
		updateBehaviour();
		if (isOut(100 * Cs.NEW_GEN_SCALE))
			kill();

		// Cs.game.plasmaDraw(root,0)

		/*
			updateBehaviour();


		 */
	}

	override function updatePos() {
		super.updatePos();
		op = {x: x, y: y};
	}

	function updateBehaviour() {
		for (n in 0...bList.length) {
			var id = bList[n];

			switch (id) {
				case 0: // BOMB;
					root._rotation += vr * Timer.tmod;

				case 3: // HOMING;
					getNewBadTrg();
					if (trg == null)
						break;
					var da = getAng({x: trg.x, y: trg.y}) - a;
					while (da > 3.14)
						da -= 6.28;
					while (da < -3.14)
						da += 6.28;
					a += Num.mm(-va, da * ca, va) * Timer.tmod;
					updateVit();

				case 4: // ONDULE;
					decal = (decal + 43 * Timer.tmod) % 628;
					a += Math.cos(decal / 100) * 0.2;
					updateVit();

				case 5: // SWARM;
					if (Math.sqrt(vx * vx + vy * vy) < 3 * Cs.NEW_GEN_SCALE || Seed.rand() / Timer.tmod < 0.1) {
						a = Seed.random(4) * 1.57;
						vx = Math.cos(a) * speed;
						vy = Math.sin(a) * speed;
					}
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
			var mc = Cs.game.dm.attach("queueRocket", Game.DP_PARTS);
			mc._rotation = 180 + getAng(op) / 0.0174;
			mc._xscale = getDist(op);
			mc._x = x;
			mc._y = y;
			mc.removeOnFrame = 19;
			mc.play();

			op = {x: x, y: y}
		}
	}

	function updateVit() {
		vx = Math.cos(a) * speed;
		vy = Math.sin(a) * speed;
		orient();
	}

	function getNewBadTrg() {
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

	function checkCols() {
		if (flGood) {
			var list = Cs.game.badsList;
			for (i in 0...list.length) {
				var b = list[i];
				if (b == null) {
					continue;
				}
				if (getDist({x: b.x, y: b.y}) < ray + b.ray) {
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
							mc.removeOnFrame = 15;
							mc.play();

							kill();
							return;
						}
					}
				}
			}
		} else {
			var h = Cs.game.hero;
			var dist = getDist({x: h.x, y: h.y});

			if (dist < Cs.game.hero.ray + ray) {
				Cs.game.hero.hit(this);
				kill();
			}
		}

		// BOUNDS
		if (isOut(ray))
			this.kill();
	}

	function onHit(bad) {
		for (n in 0...bList.length) {
			var id = bList[n];
			switch (id) {
				case 0: // BOMB;
					var list = Cs.game.badsList;
					for (i in 0...list.length) {
						var b = list[i];
						if (b != bad) {
							if (getDist({x: b.x, y: b.y}) < b.ray + ray + 36 * Cs.NEW_GEN_SCALE) {
								b.hit(this);
							}
						}
					}
					var p = new Part(Cs.game.dm.attach("partBombExplosion", Game.DP_PARTS));
					p.x = x;
					p.y = y;
					p.frict = null;
					p.updatePos();
			}
		}
	}

	public function orient() {
		root._rotation = Math.atan2(vy, vx) / 0.0174;
	}

	override function kill() {
		Cs.game.shotList.remove(this);
		super.kill();
	}
}
