package alphabounce;

import mt.bumdum.Sprite;
import mt.bumdum.Phys;

// mcBall: one frame per type (frame 2, fire: a tail `smc` turned by the code and an animated core)
class BallSkin extends ASprite {
	public var pic:Mc;
	public var core:Mc;

	public function new() {
		super();
		pic = new Mc("ball", false);
		addChild(pic);
		smc = new Mc("ballFire");
		addChild(smc);
		core = new Mc("ballCore");
		addChild(core);
		gotoAndStop(1);
	}

	override public function gotoAndStop(frame:Dynamic) {
		var f:Int = Std.int(frame);
		pic.gotoAndStop(f);
		_currentframe = f;
		smc._visible = core._visible = f == 2;
		pic._visible = f != 2;
	}
}

class Ball extends Element {
	static var ANGLE_MAX = 1.2;

	public var flUp:Bool;
	public var flBounce:Bool;
	public var type:Int;
	public var speed:Float;
	public var damage:Float;
	public var gluePoint:Null<Float>;
	public var ray:Float;
	public var va:Float;
	public var ca:Float;
	public var sleep:Null<Float>;
	public var trg:Block;

	// trail: position last stamped in the plasma
	public var trailX:Null<Float>;
	public var trailY:Null<Float>;

	public function new(mc:ASprite) {
		super(mc);
		Game.me.balls.push(this);
		ox = 0;
		oy = 0;
		px = Std.int(Cs.XMAX * 0.5);
		py = Std.int(Cs.YMAX - 3);
		vx = (Seed.rand() * 2 - 1);
		vy = -(4 + Seed.rand() * 2);
		speed = 6;
		flUp = true;
		type = -1;
		setType(Cs.BALL_STANDARD);
	}

	override public function update() {
		flBounce = false;

		if (gluePoint != null) {
			noTrail();
			y = Game.me.pad.y - ray;
			x = Game.me.pad.x + gluePoint;
			moveTo(x, y);
			updatePos();
			if (type == Cs.BALL_FIRE)
				root.smc._rotation = 90;
			return;
		}

		if (sleep != null) {
			noTrail();
			sleep -= Timer.tmod;
			if (sleep < 0)
				sleep = null;
			return;
		}

		super.update();
		// CHECK PAD
		if (flUp && vy > 0 && y > Game.me.pad.y - ray) {
			var cx = (x - Game.me.pad.x) / Game.me.pad.ray;
			if (Math.abs(cx) < 1) {
				if (type == Cs.BALL_SHADE) {
					destroy();
					return;
				}
				colPad(cx);
			} else if (Game.me.pad.flProtect) {
				colProtect();
			} else {
				flUp = false;
			}
		}

		// CHECK DEATH;
		if (!flUp && y > Cs.mch + 10) {
			if (Game.me.balls.length == 1 && Game.me.levelTimer < 600 && Game.me.flSafe && type != Cs.BALL_SHADE) {
				moveTo(x, Cs.mch + 10);
				vy *= -1;
				flUp = true;
				Game.me.newTitle(26, true);
				if (Game.me.lvl == 0)
					setSpeed(3);
			} else {
				destroy();
				// (the original goes on with a ball removed from the game)
			}
		}

		switch (type) {
			case Cs.BALL_FIRE:
				var a = Math.atan2(vy, vx);
				root.smc._rotation = a / 0.0174;
				genSparks(1, 20);

			case Cs.BALL_ICE:
				genSparks(2, 10);
				genIceShards();
				Game.me.ballTrail(this);

			case Cs.BALL_DRUNK:
				var a = Cs.atan2(vy, vx);
				va += (Seed.rand() * 2 - 1) * 0.03 * (speed / 6) * Timer.tmod;
				va *= Cs.pow(0.95, Timer.tmod);

				a += va * Timer.tmod;
				vx = Cs.cos(a) * speed;
				vy = Cs.sin(a) * speed;

				genBubbles();
				Game.me.ballTrail(this);

			case Cs.BALL_KAMIKAZE:
				if (trg == null || trg.flDeath) {
					trg = Game.me.blocks.length > 0 ? Game.me.blocks[Seed.random(Game.me.blocks.length)] : null;
					ca = 0.01;
				}
				if (trg != null) {
					var a = Cs.atan2(vy, vx);
					var dx = Cs.getX(trg.x + 0.5) - x;
					var dy = Cs.getY(trg.y + 0.5) - y;
					var ta = Cs.atan2(dy, dx);

					ca = Math.min(ca + 0.002 * Timer.tmod, 1);

					va += Num.hMod(ta - a, 3.14) * ca;
					va *= Cs.pow(0.8, Timer.tmod);

					a += va;

					vx = Cs.cos(a) * speed;
					vy = Cs.sin(a) * speed;
				}
				Game.me.ballTrail(this);

			case Cs.BALL_YOYO:
				var sp = speed * 4 * (1 - (y / (Cs.mch + 15)));
				var a = Cs.atan2(vy, vx);
				vx = Cs.cos(a) * sp;
				vy = Cs.sin(a) * sp;
				Game.me.ballTrail(this);

			default:
				Game.me.ballTrail(this);
		}

		if (flBounce) {
			for (i in 0...2) {
				var a = Cs.atan2(vy, vx);
				var ba = i * 3.14;
				var da = Num.hMod(ba - a, 3.14);
				var la = 1.57 - ANGLE_MAX;
				if (Math.abs(da) < la) {
					var dif = la - Math.abs(da);
					var sens = Math.abs(da) / da;
					if (da == 0)
						sens = 1;
					a -= dif * sens;
					setAngle(a);
				}
			}
		}
	}

	public function colPad(cx:Float) {
		// RECAL
		moveTo(x, Game.me.pad.y - ray);
		updatePos();

		// CALCUL DU REBOND
		var a = -1.57 + cx * ANGLE_MAX;
		vx = Cs.cos(a) * speed;
		vy = Cs.sin(a) * speed;
		Game.me.pad.padec = null; // AUTO PLAY

		// GLUE
		if (Game.me.pad.type == Cs.PAD_GLUE) {
			gluePoint = x - Game.me.pad.x;
			var max = 10;
			for (i in 0...max) {
				var a = -i / max * 3.14;
				var ca = Math.cos(a);
				var sa = Math.sin(a);
				var sp = 0.5 + Seed.randVfx() * 3;
				var cr = 4;
				var p = new Phys(Game.me.dm.attach("glue", 0));
				p.x = x + ca * sp * cr;
				p.y = y + sa * sp * cr;
				p.vx = ca * sp;
				p.vy = sa * sp;
				p.weight = 0.1 + Seed.randVfx() * 0.15;
				p.timer = 10 + Seed.randVfx() * 10;
				p.setScale(p.weight * 400);
				p.fadeType = 0;
			}
		}

		// TRIPLE
		if (type == Cs.BALL_HALO) {
			var max = 5;
			for (i in 0...max) {
				var b = clone();
				b.sleep = (i + 1) * 3 - 1;
				b.setType(Cs.BALL_SHADE);
				b.root._alpha = 50;
				Game.me.dm.under(b.root);
			}
		}
	}

	public function colProtect() {
		moveTo(x, Game.me.pad.y - ray);
		updatePos();
		vy *= -1;

		// PARTS
		var max = Std.int(2 + 12 * Cs.getPerfCoef());
		var cr = 3;
		for (i in 0...max) {
			var a = (i / max - 1) * 3.14 + (Seed.randVfx() * 2 - 1) * 0.2;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = 0.5 + Seed.randVfx() * 4;
			var p = new alphabounce.fx.Spark(Game.me.dm.attach("sparkPink", Game.DP_PARTS), 3);
			p.x = x + ca * sp * cr;
			p.y = y + sa * sp * cr + 5;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.weight = 0.1 + Seed.randVfx() * 0.1;
			p.timer = 10 + Seed.randVfx() * 20;
			p.root._yscale = 100;
		}
	}

	public function setType(n:Int) {
		if (type == Cs.BALL_SHADE)
			return;

		type = n;
		root.gotoAndStop(type + 1);

		switch (type) {
			case Cs.BALL_STANDARD:
				damage = 1;
				ray = 4;
			case Cs.BALL_FIRE:
				damage = 2;
				ray = 5;
			case Cs.BALL_ICE:
				damage = 1;
				ray = 4;
			case Cs.BALL_DRUNK:
				damage = 1;
				ray = 4;
				va = 0;
			case Cs.BALL_KAMIKAZE:
				damage = 1;
				ray = 5;
				va = 0;
			case Cs.BALL_HALO:
				damage = 1;
				ray = 4;
		}
	}

	public function setSpeed(n:Float) {
		// FIX(yota): Zele do creates infinite loops with Kamikaze
		if (n > 30.0 && type == Cs.BALL_KAMIKAZE)
			setType(Cs.BALL_STANDARD);

		speed = n;
		var a = Cs.atan2(vy, vx);
		vx = Cs.cos(a) * speed;
		vy = Cs.sin(a) * speed;
	}

	public function setAngle(a:Float) {
		vx = Cs.cos(a) * speed;
		vy = Cs.sin(a) * speed;
	}

	override function onBounce(px:Int, py:Int) {
		Game.me.hit(px, py, type, damage);
		flBounce = true;
		if (type == Cs.BALL_SHADE && px > 0 && px < Cs.XMAX) {
			destroy();
		}
	}

	public function clone() {
		var ball = Game.me.newBall();
		ball.moveTo(x, y);
		ball.updatePos();
		ball.speed = speed;
		ball.setType(type);
		ball.vx = vx;
		ball.vy = vy;
		ball.gluePoint = gluePoint;
		return ball;
	}

	// FX
	function genSparks(fr:Int, turn:Float) {
		if (Seed.randomVfx(Sprite.spriteList.length) < 20) {
			var mc = Game.me.dm.empty(Game.DP_UNDERPARTS);
			var smc = new Mc("spark" + fr);
			smc.stops = [22];
			mc.addChild(smc);
			mc.smc = smc;
			var p = new Phys(mc);
			p.x = x;
			p.y = y;
			var c = 0.3 + Seed.randVfx() * 0.5;
			p.vx = c * vx;
			p.vy = c * vy;
			p.vr = (Seed.randVfx() * 2 - 1) * turn;
			p.root._rotation = Seed.randVfx() * 360;
			p.timer = 10 + Seed.randVfx() * 30;
			smc._x = Seed.randVfx() * 15;
			p.frict = 0.95;
		}
	}

	function genIceShards() {
		if (Seed.randomVfx(Sprite.spriteList.length) < 15) {
			var p = new Phys(Game.me.dm.attach("iceShard", Game.DP_UNDERPARTS));
			p.x = x + (Seed.randVfx() * 2 - 1) * 4;
			p.y = y + (Seed.randVfx() * 2 - 1) * 4;
			var c = 0.7 + Seed.randVfx() * 0.3;
			p.vx = c * vx;
			p.vy = c * vy;
			p.vr = (Seed.randVfx() * 2 - 1) * 8;
			p.root._rotation = Math.atan2(vy, vx) / 0.0174;
			p.timer = 10 + Seed.randVfx() * 10;
			p.fadeType = 0;
			p.weight = 0.1 + Seed.randVfx() * 0.1;
		}
	}

	function genBubbles() {
		if (Seed.randomVfx(Sprite.spriteList.length) < 15) {
			var p = new Phys(Game.me.dm.attach("bubble", Game.DP_UNDERPARTS));
			p.x = x + (Seed.randVfx() * 2 - 1) * 4;
			p.y = y + (Seed.randVfx() * 2 - 1) * 4;
			var c = 0.1 + Seed.randVfx() * 0.2;
			p.vx = c * vx;
			p.vy = c * vy;
			p.timer = 10 + Seed.randVfx() * 20;
			p.fadeType = 0;
			p.weight = -(0.1 + Seed.randVfx() * 0.2);
			p.setScale(50 + Seed.randVfx() * 100);
		}
	}

	function destroy() {
		kill();
		if (Game.me.balls.length == 0) {
			Game.me.initGameOver();
		}
	}

	public function noTrail() {
		trailX = trailY = null;
	}

	override public function kill() {
		Game.me.balls.remove(this);
		super.kill();
	}
}
