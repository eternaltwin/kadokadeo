package elloninthedark;

class Bactery extends Bads {
	public static var MARGIN = KadoKadeoManager.I(10);

	public var dif:Float;
	public var wTimer:Float;
	public var sleep:Float;

	public var bloupDecal:Float;
	public var bloupSpeed:Null<Float>;

	public function new(mc:ASprite) {
		super(mc, 5);
		ray = KadoKadeoManager.I(14);
		hp = 10;
		root.loop = true;
		root.play();
		frict = 0.97;
		score = Cs.SCORE_BACTERY;
		gid = 7;
		decal = Seed.rand() * 628;
		wTimer = 400;

		dif = Seed.rand() * 50;
		sleep = 0;
		x = Cs.mcw + ray + KadoKadeoManager.I(5);
		y = MARGIN + Seed.rand() * (Cs.GL + MARGIN * 2);
		newTrg();
		Cs.bact++;
	}

	override public function update() {
		super.update();

		dif += 3 * Timer.tmod;
		wTimer -= (1 + dif * 0.005) * Timer.tmod;
		if (wTimer < 0) {
			wTimer = 500;
			newTrg();
			if (Seed.random(4) == 0 && Cs.bact < 16) {
				var b = new Bactery(Cs.game.mdm.attach("mcBactery", Game.DP_MONSTER));
				b.x = x;
				b.y = y;
				b.dif = dif;
				b.sleep = 1;
				Cs.game.monsterLevel -= b.level;
				b.level = 0;
				for (i in 0...8) {
					var p = new Part(Cs.game.mdm.attach("partBactery", Game.DP_PARTS));
					var a = 6.28 * i / 8;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var sp = KadoKadeoManager.S(0.3 + Seed.randVfx() * 2.5);
					p.x = x + ca * ray;
					p.y = y + sa * ray;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.scale = 100 + Seed.randVfx() * 100;
					p.root._xscale = p.scale;
					p.root._yscale = p.scale;
					p.timer = 10 + Seed.randVfx() * 10;
					p.fadeType = 0;
				}
				b.bloup();
				bloup();
			}
		}

		if (bloupSpeed != null) {
			bloupSpeed *= Math.pow(0.96, Timer.tmod);
			bloupDecal = (bloupDecal + bloupSpeed * 2 * Timer.tmod) % 628;
			var amp = bloupSpeed * 0.5;
			root._xscale = 100 + Math.cos(bloupDecal / 100) * amp;
			root._yscale = 100 + Math.sin(bloupDecal / 100) * amp;
			if (bloupSpeed < 1) {
				bloupSpeed = null;
			}
		}

		checkGround();

		move();
		bounceFamily();
	}

	public function bloup() {
		bloupSpeed = 66;
		bloupDecal = Seed.randVfx() * 628;
	}

	public function move() {
		decal = (decal + 17 * Timer.tmod) % 628;
		var r = KadoKadeoManager.S(Math.max(10, 150 - dif * 0.3));
		var pos = {
			x: trg.x + Math.cos(decal / 100) * r,
			y: trg.y + Math.sin(decal / 100) * r
		};

		sleep = Math.min(sleep + (0.01 * Timer.tmod), 1);

		var speed = KadoKadeoManager.S(Math.min(0.1 + dif * 0.0001, 0.5)) * sleep;
		speedToward(pos, 0.2, speed);

		var b = KadoKadeoManager.S(0.3);
		if (x < ray + MARGIN) {
			vx += b * Timer.tmod;
		}
		if (x > Cs.mcw - (ray + MARGIN) && sleep >= 1) {
			vx -= b * Timer.tmod;
		}
		if (y < ray + MARGIN) {
			vy += b * Timer.tmod;
		}
		if (y > Cs.GL - (ray + MARGIN)) {
			vy -= b * Timer.tmod;
		}
	}

	override public function hit(shot:Shot) {
		super.hit(shot);
		var a = Math.atan2(shot.vy, shot.vx);
		vx += Math.cos(a) * shot.damage * KadoKadeoManager.S(4);
		vy += Math.sin(a) * shot.damage * KadoKadeoManager.S(4);
	}

	public function newTrg() {
		var r = KadoKadeoManager.S(Seed.rand() * Math.max(0, 200 - dif * 0.3));
		var a = Seed.rand() * 6.28;

		var h = Cs.game.hero;

		trg = {
			x: Num.mm(KadoKadeoManager.I(50) + MARGIN, h.x + Math.cos(a) * r, Cs.mcw - MARGIN),
			y: Num.mm(MARGIN, h.y + Math.sin(a) * r, Cs.GL - MARGIN)
		};
	}

	override public function kill() {
		Cs.bact--;
		super.kill();
	}
}
