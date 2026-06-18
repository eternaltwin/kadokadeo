package crepuscud;

import js.html.Console;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;
import common_haxe_avm1.KKApi;

class Missile extends Projectile {
	public static var BOOST = 0;
	public static var COLOR = [0xAAFF66, 0x88AAFF, 0xFF66CC];

	public var special:Int;

	public function new(?mc:ASprite) {
		if (mc == null)
			mc = Game.me.dm.attach("mcMissile", Game.DP_MISSILE);
		super(mc);

		var speed = Cs.S(0.75 + Seed.rand() * Game.me.dif * 0.5);

		x = Seed.rand() * Cs.mcw;
		y = -speed * 4;

		var ma = 45;
		var tx = ma + Seed.rand() * (Cs.mcw - Cs.S(ma + 5));
		var ty = Cs.mch;

		var dx = tx - x;
		var dy = ty - y;

		// SPECIAL
		if (Seed.random(10) == 0)
			special = 0;
		if (Seed.random(60) == 0)
			special = 1;
		if (Seed.random(300) == 0)
			special = 2;
		if (special != null)
			qcol = COLOR[special];

		setAngle(Math.atan2(dy, dx));

		if (special != null)
			speed = Cs.S([3, 5, 9][special]);
		setSpeed(speed + BOOST);

		Game.me.missiles.push(this);
		Game.me.totalSpeed += speed;
	}

	override function update() {
		super.update();

		if (y > Game.GY) {
			var gy = Game.me.getGroundHeight(Std.int(x));
			if (y > gy) {
				y = gy;
				groundExplode();
			}
			return;
		}
	}

	public function explode(pool) {
		var onde = new Onde(x, y, Cs.RAY_MISSILE);
		onde.pool = pool;

		var score = KKApi.cmult(Cs.SCORE_MISSILE[pool.n], KKApi.const(pool.multi));
		if (special != null)
			score = Cs.SCORE_BONUS[special];
		Game.me.addScore(x, y, score, special);

		var max = 24;
		var cr = 8;
		for (i in 0...max) {
			var a = (i + Seed.rand()) / max * 6.28;
			var ca = Cs.S(Math.cos(a));
			var sa = Cs.S(Math.sin(a));
			var speed = 1.5 + Seed.rand() * 3;
			var p = new Phys(Game.me.dm.attach("partSquareLight", Game.DP_PARTS));
			p.x = x + ca * speed * cr;
			p.y = y + sa * speed * cr;
			p.vx = ca * speed;
			p.vy = sa * speed;
			p.timer = 10 + Seed.rand() * 20;
			p.fadeType = 0;
			p.root.gotoAndPlay(Seed.random(2) + 1);
			p.weight = 0.05 + Seed.rand() * 0.1;
			p.frict = 0.9;
		}

		Game.me.expl++;
		kill();
	}

	public function groundExplode() {
		// HOLE
		Game.me.makeHole(x, y, 0.15 + Seed.rand() * 0.05);

		// FX
		var mc = Game.me.dm.attach("fxDemiOnde", Game.DP_MISSILE);
		mc.play();
		mc.removeOnFrame = 9;
		mc._x = x;
		mc._y = y;

		var max = 18;
		var cr = 5;
		for (i in 0...max) {
			var a = -(i + Seed.rand()) / max * 3.14;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var speed = 0.2 + Seed.rand() * 3;
			var p = new Phys(Game.me.dm.attach("partDirt", Game.DP_PARTS));
			p.x = x + ca * speed * cr;
			p.y = y + sa * speed * cr;
			p.vx = ca * speed;
			p.vy = sa * speed;
			p.timer = 10 + Seed.rand() * 20;
			p.fadeType = 0;
			p.weight = 0.15 + Seed.rand() * 0.15;
			p.setScale(50 + Seed.rand() * 50);
		}

		kill();
	}

	override function kill() {
		Game.me.missiles.remove(this);
		Game.me.totalSpeed -= speed;
		super.kill();
	}
}
