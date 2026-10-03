package alphabounce;

import mt.bumdum.Sprite;
import common_haxe_avm1.KeyboardManager;

// mcPad: two ends `side0` / `side1` and the middle `mid` (scaled by the code) with its power bar `mid.smc`, one frame per
// type of pad
class PadSkin extends ASprite {
	public var side0:Mc;
	public var side1:Mc;
	public var mid:PadMid;

	public function new() {
		super();
		side0 = new Mc("padSide", false);
		side1 = new Mc("padSide", false);
		side1._xscale = -100;
		mid = new PadMid();
		addChild(side0);
		addChild(side1);
		addChild(mid);
	}
}

class PadMid extends ASprite {
	public var pic:Mc;
	public var bar:Mc;

	public function new() {
		super();
		pic = new Mc("padMid", false);
		addChild(pic);
		bar = new Mc("padBar", false);
		bar._x = 50;
		bar._y = 5;
		addChild(bar);
		smc = bar;
		gotoAndStop(1);
	}

	override public function gotoAndStop(frame:Dynamic) {
		var f:Int = Std.int(frame);
		_currentframe = f;
		pic.gotoAndStop(f);
		// smc only on frames 3-5 (time, laser, protection)
		bar._visible = f >= 3 && f <= 5;
		if (bar._visible)
			bar.gotoAndStop(f - 2);
	}
}

class Pad extends Sprite {
	public static var SIDE = 14;
	public static var SPEED = 10;

	static var DY = 1;

	public var ray:Float;
	public var type:Int;
	public var moveFactor:Int;

	public var flGo:Bool;
	public var flStop:Bool;
	public var flProtect:Bool;
	public var flMouse:Bool;
	public var padec:Null<Float>;

	public var power:Null<Float>;
	public var recovery:Float;

	var skin:PadSkin;
	var mcProtection:Mc;

	public function new(mc:PadSkin) {
		super(mc);
		skin = mc;

		y = Cs.getY(Cs.YMAX + DY);
		x = Cs.mcw * 0.5;

		flMouse = false;
		type = -1;
	}

	public function init() {
		flGo = false;
		flStop = false;
		flProtect = false;
		power = null;
		moveFactor = 1;
		setRay(36);
		setType(Cs.PAD_STANDARD);
	}

	override public function update() {
		move();
		if (power != null)
			updatePower();
		if (Game.me.flPress)
			salve();

		switch (type) {
			case Cs.PAD_AIMANT:
				for (b in Game.me.balls) {
					if (b.vy > 0 && b.type != Cs.BALL_KAMIKAZE && b.type != Cs.BALL_SHADE && b.y < y) {
						var a = Cs.atan2(b.vy, b.vx);
						var dx = x - b.x;
						var dy = y - b.y;
						var ta = Cs.atan2(dy, dx);
						var dist = Math.sqrt(dx * dx + dy * dy);
						a += Num.hMod(ta - a, 3.14) * 0.25;
						b.vx = Cs.cos(a) * b.speed;
						b.vy = Cs.sin(a) * b.speed;

						if (dist < 150 && Seed.randVfx() * dist < 30) {
							var p = new alphabounce.fx.Attract(Game.me.dm.attach("attractLine", Game.DP_PARTS));
							var ec = 12;
							p.x = b.x + (Seed.randVfx() * 2 - 1) * ec;
							p.y = b.y + (Seed.randVfx() * 2 - 1) * ec;
							p.dx = (Seed.randVfx() * 2 - 1) * ray;
						}
					}
				}
				queue("greenBar", 100);
			case Cs.PAD_SHAKE:
				x += (Seed.rand() * 2 - 1) * 14;
				queue("pinkBar", 15);
		}

		// SIDE RECAL
		if (!flGo) {
			var r = ray + Cs.SIDE - 1;
			x = Num.mm(r, x, Cs.mcw - r);
		}

		super.update();
	}

	function move() {
		if (flGo) {
			x += 3;
			if (x > Cs.mcw + ray + 2)
				Game.me.leaveLevel();
			if (flProtect)
				removeProtection();
			return;
		}

		var inc:Null<Int> = null;
		if (KeyboardManager.isDown(KeyboardManager.LEFT))
			inc = -1;
		if (KeyboardManager.isDown(KeyboardManager.RIGHT))
			inc = 1;

		if (inc != null) {
			flMouse = false;
			x += inc * SPEED * moveFactor * Timer.tmod;
		}

		if (flMouse) {
			var c = (Game.me.mouseX() / Cs.mcw) * 2 - 1;
			x = Cs.mcw * (0.5 + moveFactor * c * 0.5);
		}

		// AUTO-PROTECT
		if (flProtect) {
			power = Math.max(power - 0.04, 0);
			displayPowerBar();
			if (power == 0) {
				removeProtection();
				skin.mid.smc._alpha = 50;
			}
		}
	}

	function initPower() {
		power = 1;
		displayPowerBar();
		skin.mid.smc._alpha = 100;
	}

	function updatePower() {
		if (power < 1) {
			power = Math.min(power + recovery * Timer.tmod, 1);
			displayPowerBar();
			if (power == 1)
				skin.mid.smc._alpha = 100;
		}
	}

	function displayPowerBar() {
		skin.mid.smc._xscale = 100 * power;
	}

	public function action() {
		switch (type) {
			case Cs.PAD_TIME:
				if (power == 1)
					flStop = true;
			case Cs.PAD_PROTECTION:
				if (power == 1)
					initProtection();
			case Cs.PAD_LASER:
				var cost = 0.2;
				if (power > cost) {
					power -= cost;
					for (i in 0...2) {
						var mc = Game.me.dm.empty(Game.DP_PARTS);
						var smc = new Mc("laserSmc", false);
						smc._x = -3;
						mc.addChild(smc);
						mc.smc = smc;
						mc.addChild(new Mc("laserTop", false));
						var shot = new alphabounce.shot.Laser(mc);
						shot.moveTo(x + (i * 2 - 1) * (ray - 9), y);
						shot.setVit(18);
						shot.updatePos();
					}
				}
		}
	}

	public function release() {
		switch (type) {
			case Cs.PAD_TIME:
				if (flStop) {
					flStop = false;
					skin.mid.smc._alpha = 50;
				}
		}
	}

	public function salve() {
		for (b in Game.me.balls)
			b.gluePoint = null;
		switch (type) {
			case Cs.PAD_TIME:
				if (flStop) {
					power = Math.max(power - 0.03, 0);
					displayPowerBar();
					if (power == 0)
						release();
				}
		}
	}

	function initProtection() {
		flProtect = true;
		mcProtection = Game.me.dm.attach("protection", Game.DP_PAD);
		mcProtection.stops = [6];
		mcProtection.removeAfter = true;
		mcProtection._y = y + 5;
		Game.me.dm.under(mcProtection);
	}

	function removeProtection() {
		flProtect = false;
		// gotoAndPlay("remove")
		if (mcProtection != null)
			mcProtection.gotoAndPlay(7);
	}

	public function setType(n:Int) {
		switch (type) {
			case Cs.PAD_GLUE:
				for (b in Game.me.balls)
					b.gluePoint = null;
			case Cs.PAD_TIME:
				flStop = false;
			case Cs.PAD_PROTECTION:
				removeProtection();
		}

		type = n;
		skin.mid.gotoAndStop(type + 1);
		skin.side0.gotoAndStop(type + 1);
		skin.side1.gotoAndStop(type + 1);
		switch (type) {
			case Cs.PAD_TIME:
				recovery = 0.01;
				initPower();
			case Cs.PAD_LASER:
				recovery = 0.007;
				initPower();
			case Cs.PAD_PROTECTION:
				recovery = 0.01;
				initPower();
		}
	}

	public function setRay(r:Float) {
		ray = r;
		var w = r - SIDE;
		skin.mid._xscale = w * 2;
		skin.mid._x = -w;
		skin.side0._x = -r;
		skin.side1._x = r;
	}

	// FX
	public function powerUp() {
		for (i in 0...24) {
			var p = new alphabounce.fx.LineUp(Game.me.dm.attach("lineUpGlow", Game.DP_PARTS));
			p.ys0 = 1 / 3;
			p.x = x + (Seed.randVfx() * 2 - 1) * ray;
			p.y = y;
			p.sleep = Seed.randVfx() * 5;
			p.timer = 10 + Seed.randVfx() * 20;
			p.weight = -(0.1 + Seed.randVfx() * 0.3);
			p.root.blendMode = pixi.core.Pixi.BlendModes.ADD;
			p.factor = 3;
		}
	}

	public function queue(link:String, alpha:Float) {
		var brush = new Mc(link, false);
		brush._yscale = 12 / 6 * 100;
		brush._xscale = ray * 2;
		brush._x = x - ray;
		brush._y = y;
		brush._alpha = alpha;
		Game.me.plasmaDraw(brush);
	}
}
