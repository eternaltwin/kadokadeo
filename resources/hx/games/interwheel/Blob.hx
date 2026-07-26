package interwheel;

import mt.bumdum.Lib;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import mt.Timer;
import mt.bumdum.Phys;

class Blob extends Phys {
	public static var GROUND_SPEED = KadoKadeoManager.I(15);
	public static var RAY = KadoKadeoManager.I(8);
	public static var WEIGHT = KadoKadeoManager.S(0.5);
	public static var JUMP = KadoKadeoManager.I(12);

	public static var JUMP_SIDE_ANGLE = 0.77;

	var flClick:Bool;
	var flMouseRelease:Bool;
	var flRelease:Bool;
	var flWater:Bool;

	public var step:Int;

	var inst:Float;
	var blop:Float;
	var wet:Float;

	var ox:Float;
	var oy:Float;
	var vvx:Float;
	var vvy:Float;

	public var cw:Wheel;

	var wa:Float;

	public function new(mc:ASprite) {
		super(mc);
		mc.stopOnFrame = [19, 44, 59, 173];
		Cs.game.focus = cast {x: this.x, y: this.y};
		flRelease = true;
		flMouseRelease = true;
		flWater = false;
		frict = 1;
		wet = 0;
		vvx = 0;
		vvy = 0;
	}

	public function initStep(s) {
		switch (step) {
			case 1: //
				weight = 0;
				frict = 1;
				vx = 0;
				vy = 0;
			case 2:
				root._rotation = 0;
				Cs.game.focus = cast {x: this.x, y: this.y};
				vvx = 0;
				vvy = 0;
		}
		step = s;
		switch (step) {
			case 0: //
				vx = GROUND_SPEED;
				root.gotoAndStop(1);
			case 1: // FLY
				weight = WEIGHT;
				frict = 0.98;
				blop = 0.6;
			case 2: // GRAB
				var ba = getAng(cw) + 3.14;
				wa = Num.hMod(cw.a - ba, 3.14);
				root.gotoAndPlay(45);
				inst = 0;
				Cs.game.focus = cast {x: Cs.mcw / 2, y: cw.y - Cs.VIEW_WHEEL}; // upcast(cw)
				ox = x;
				oy = y;
			case 3:
				root.gotoAndPlay(20);
			case 4:
				var tmpX = x;
				var tmpY = y;
				root.removeMovieClip();
				root = Cs.game.dm.attach("mcBlob", Game.DP_PART);
				x = tmpX;
				y = tmpY;
				root.gotoAndPlay(103);
				frict = 0.8;
				weight = WEIGHT;
		}
	}

	public override function update() {
		flClick = MouseManager.isButtonDown(MouseManager.BUTTON_LEFT);

		switch (step) {
			case 0: //
				var m = Cs.SIDE + RAY;
				if (x < m || x > Cs.mcw - m) {
					x = Num.mm(m, x, Cs.mcw - m);
					vx = -vx;
				}
				if (checkPress()) {
					jump(-1.57);
				}
			case 1: // FLY

				var a = Math.atan2(vy, vx); // frame

				var frame = 60 + ((a + 3.14) / 6.28) * 40;
				root.gotoAndStop(Std.int(frame)); // check side

				var m = Cs.SIDE;
				if (x < m || x > Cs.mcw - m) {
					x = Num.mm(m, x, Cs.mcw - m);
					initStep(3); // vx *= -1
				}
				#if debug
				if (checkPress()) {
					jump(-1.58);
					vy = -KadoKadeoManager.I(16);
				}
				#end

				/*
					// check ground
					if( y > 0 ){
						y = 0;
						initStep(0);
						break;
					}
				 */

				// blop
				blop = Num.q(Math.max(0.07, blop * Math.pow(0.94, Timer.tmod)));
				if (Seed.randVfx() < blop) {
					var p = newPart();
					var fr = 0.4 + Seed.randVfx() * 0.4;
					p.x += (Seed.randVfx() * 2 - 1) * 3;
					p.y += (Seed.randVfx() * 2 - 1) * 3;
					p.vx = vx * fr;
					p.vy = vy * fr;

					p.setScale(50 + Seed.randVfx() * 50 + blop * 50);
					p.weight = 0.2 + Seed.randVfx() * 0.2;
				}

				// water
				if (flWater) {
					var fr = Math.pow(0.95, Timer.tmod);
					vx = Num.q(vx * fr);
					vy = Num.q(vy * fr);
				}

				//
				vvx = ox - x;
				vvy = oy - y;
				ox = x;
				oy = y;

			case 2:
				var a = cw.a - wa;
				x = Num.q(cw.x + Math.cos(a) * cw.ray);
				y = Num.q(cw.y + Math.sin(a) * cw.ray);
				root._rotation = a / 0.0174;
				inst = Num.q(Math.min(inst + 0.1 * Timer.tmod, 1));
				// var body = cast(root).bl;
				// var pince = cast(root).pince;
				if (checkPress())
					jump(a);
			case 3:
				vy = Num.q(vy + KadoKadeoManager.S(0.6));
				vy = Num.q(vy * Math.pow(0.92, Timer.tmod));
				if (checkPress()) {
					var sens = (x < Cs.mcw * 0.5) ? 1 : -1;
					jump(-1.57 + JUMP_SIDE_ANGLE * sens);
				}
			case 4:
				wet -= 0.02;
		}
		if (step == 2) {
			Cs.game.focus = cast {x: Cs.mcw / 2, y: cw.y - Cs.VIEW_WHEEL}; // upcast(cw)
		} else {
			Cs.game.focus = cast {x: this.x, y: this.y};
		}
		super.update();
		if (!(KeyboardManager.isDown(KeyboardManager.SPACE)))
			flRelease = true;
		if (!flClick)
			flMouseRelease = true;

		checkWater();
		if (flWater) {
			if (step != 4)
				wet = Num.q(wet + 0.015 * Timer.tmod);
			// vx*=Math.pow(0.98,Timer.tmod)
			if (vy > 0)
				vy = Num.q(vy * Math.pow(0.9, Timer.tmod));
			if (Seed.randVfx() < wet) {
				var p = new Part(Cs.game.dm.attach("partTache", Game.DP_OIL));
				p.x = x;
				p.y = y;
				p.vx = vx * 0.5 + (Seed.randVfx() * 2 - 1) * 1;
				p.vy = vy * 0.5 + (Seed.randVfx() * 2 - 1) * 0.5;
				p.setScale(100 + wet * 150 + Seed.randVfx() * 100);
			}
			if (Seed.randVfx() < wet) {
				var p = new Bubble(null);
				p.x = x + Seed.randVfx() * RAY;
				p.y = y + Seed.randVfx() * RAY;
				p.vy = vy * 0.8; //-Math.random()*2
			}
		} else {
			if (wet > 0) {
				wet = Num.q(Math.max(0, wet - 0.02 * Timer.tmod));

				if (Seed.randVfx() * 0.5 < wet) {
					var coef = 0.2 + Seed.randVfx() * 0.4;
					var p = new Part(Cs.game.dm.attach("partGoutte", Game.DP_OIL));
					p.x = x + (Seed.randVfx() * 2 - 1) * 6;
					p.y = y + (Seed.randVfx() * 2 - 1) * 6;
					p.vx = (vvx + vx) * coef;
					p.vy = (vvy + vy) * coef;
					p.timer = 10 + Seed.randVfx() * 10;
					p.fadeType = 0;
					p.setScale(60 + wet * 80 + Seed.randVfx() * 50);
				}
			}
		}
	}

	public function checkDeath() {
		if (wet > 1) {
			initStep(4);
			Cs.game.initStep(9);
		}
	}

	public function checkWater() {
		var flw = Num.q(y - RAY) > Num.q(Cs.game.water._y);

		if (flWater) {
			if (!flw) {
				Cs.game.stats.pl++;
			}
		} else {
			if (flw) {}
		}

		flWater = flw;
	}

	public function jump(a) {
		Cs.game.stats.jp++;
		flRelease = false;
		flMouseRelease = false;
		var max = 4;
		for (i in 0...max) {
			var dec = Seed.randVfx() * 2 - 1;
			var na = a + dec * 0.8;
			var sp = 8 - Math.abs(dec) * 6;
			var c = i / max;
			var p = newPart();
			p.vx = Math.cos(na) * sp;
			p.vy = Math.sin(na) * sp;
			p.setScale(50 + c * 100);
			p.timer = 10 + Seed.randVfx() * 30;
			p.weight = 0.2 + c * 0.2;
		}

		vx = Math.cos(a) * JUMP;
		vy = Math.sin(a) * JUMP;
		initStep(1);
		cw = null;
	}

	public function newPart() {
		var p = new Part(Cs.game.dm.attach("partOil", Game.DP_OIL));
		p.x = x;
		p.y = y;
		p.timer = 10 + Seed.randVfx() * 10;
		p.fadeType = 0;
		return p;
	}

	public function explode(ba) {
		var max = 32;
		for (i in 0...max) {
			var dec = Seed.randVfx() * 2 - 1;
			var na = ba + dec * 0.8;
			var sp = (14 - Math.abs(dec) * 8) * (0.3 + Seed.randVfx() * 0.7);
			var c = i / max;
			var p = newPart();
			p.vx = Math.cos(na) * sp;
			p.vy = Math.sin(na) * sp;
			p.setScale(50 + c * 150);
			p.timer = 10 + Seed.randVfx() * 20;
			p.weight = 0.2 + c * 0.2;
		}
		Cs.game.initStep(9);
		initStep(5);
		kill();
	}

	function checkPress() {
		return (flRelease && KeyboardManager.isDown(KeyboardManager.SPACE)) || (flClick && flMouseRelease);
	}
}
