package starfang;

import mt.bumdum.Lib.PointWithGetter;
import mt.bumdum.Part;
import kado.KadoKadeoManager;
import mt.bumdum.Lib.Num;
import common_haxe_avm1.KeyboardManager;
import mt.DepthManager;
import mt.Timer;

class Hero extends Phys {
	var flWarp:Bool;
	var flInvincible:Bool;
	var flBounce:Bool;

	// var cs:Int;
	// var csmulti:Int;
	var turnSpeed:Float;
	var speed:Float;
	var accel:Float;
	var angle:Float;
	var hyperThrustTimer:Float;

	var mainFlame:Float;
	var mainFlameTrg:Float;

	// var weapon:{selected:Int, cd:Float, power:Array<Int>}
	var weaponSelected:Int;
	var weaponCooldown:Float;
	var weaponPower:Array<Int>;

	// var weaponPower : mt.flash.PArray<Int>;
	// var secondary:{ammo:Float, selected:Int, cd:Float}
	public var secAmmo:Float;
	public var secSelected:Int;
	public var secCooldown:Float;

	var wings:Array<{mc:ASprite, flame:ASprite, trg:Float}>;

	var dm:DepthManager;
	var shieldDecal:Float;
	var concentration:Float;

	var magicBallList:Array<{
		mc:ASprite,
		pos:Float,
		max:Float,
		trg:Bads,
		sx:Float,
		sy:Float,
		opx:Float,
		opy:Float
	}>;
	var mcHyperThrust:ASprite;

	function new(mc) {
		super(mc);
		flBounce = true;
		flInvincible = false;
		flWarp = false;

		turnSpeed = 0.15;
		accel = 0.5;
		ray = 10;
		angle = 0;
		frict = 0.98;
		weaponSelected = 0;
		weaponCooldown = 0;
		weaponPower = new Array();
		for (i in 0...5)
			weaponPower.push(-1);
		weaponPower[0] = 0;

		secSelected = null;
		secAmmo = 10;
		secCooldown = 0;

		dm = new DepthManager(root);

		var body = cast(root);
		wings = [{mc: body.w0, flame: body.f0, trg: 0}, {mc: body.w1, flame: body.f1, trg: 0}];

		mainFlame = 0;
		mainFlameTrg = 0;
		shieldDecal = 0;
	}

	override function update() {
		super.update();
		if (flWarp) {
			checkWarp();
		} else {
			checkBounds();
		}
		updateWings();
		weaponCooldown -= Timer.tmod;
		secCooldown -= Timer.tmod;

		updateMagicBalls();
		updateHyperThrust();
		updateConcentration();
	}

	function updateConcentration() {
		if (concentration != null) {
			concentration -= 0.05 * Timer.tmod;
			for (i in 0...5 * Std.int(concentration)) {
				var p = new Part(Cs.game.dm.attach("partConcentrate", Game.DP_UNDERPARTS));
				p.x = x;
				p.y = y;
				p.vx = vx;
				p.vy = vy;
				p.root._rotation = Math.random() * 360;
				// mc._rotation = Math.random()*360
				if (concentration < 0)
					concentration = null;
			}
		}
	}

	function updateWings() {
		for (i in 0...wings.length) {
			var w = wings[i];
			var dr = w.trg - w.mc._rotation;
			w.mc._rotation += dr * 0.5 * Timer.tmod;
			var sens = i * 2 - 1;
			w.flame._xscale = -(w.mc._rotation) * sens * 4;
		}
		var df = mainFlameTrg - mainFlame;
		mainFlame += df * 0.3 * Timer.tmod;
		root.flame._xscale = mainFlame;
	}

	function control() {
		if (hyperThrustTimer == null)
			flInvincible = false;

		wings[0].trg = 0;
		wings[1].trg = 0;
		mainFlameTrg = 0;

		if (KeyboardManager.isDown(KeyboardManager.LEFT))
			turn(-1);
		if (KeyboardManager.isDown(KeyboardManager.RIGHT))
			turn(1);
		if (KeyboardManager.isDown(KeyboardManager.UP)) {
			thrust(0, 1);
			mainFlameTrg = 100;
			launchSparks(0, 2, 0);
		}
		if (KeyboardManager.isDown(KeyboardManager.SPACE))
			fireMain();
		if (KeyboardManager.isDown(KeyboardManager.DOWN) || KeyboardManager.isDown(KeyboardManager.CONTROL))
			fireSecondary();
	}

	function turn(sens) {
		if (hyperThrustTimer != null)
			return;
		var ec = 45;
		if (KeyboardManager.isDown(KeyboardManager.SPACE) && 1 == 0) {
			thrust(sens * 1.57, 0.5);
			ec = 70;
		} else {
			angle = Num.hMod(angle + sens * turnSpeed * Timer.tmod, 3.14);
			root._rotation = angle / 0.0174;
			thrust(sens, 0.25);
			launchSparks(sens * 0.95, 1, 0);
		}
		var n = Std.int((-sens + 1) * 0.5);
		wings[n].trg = ec * sens;
	}

	function updateWeapon(id) {
		weaponPower[id] = Std.int(Math.min(weaponPower[id] + 1, Cs.WEAPON_POWER_MAX));
		weaponSelected = id;
		concentration = 1;
		// Log.trace("("+csmulti+") "+cs );
	}

	function updateSecondary(id) {
		secAmmo = 100;
		secSelected = id;
		Cs.game.inter.update();
		concentration = 1;
	}

	function thrust(ma, power:Float) {
		vx += Math.cos(angle + ma) * accel * power * Timer.tmod;
		vy += Math.sin(angle + ma) * accel * power * Timer.tmod;
	}

	function hit(shot) {}

	function fireMain() {
		if (weaponCooldown > 0)
			return;
		var id = weaponSelected;
		var power = weaponPower[id];

		var cd:Float = 0;
		switch (id) {
			case 0:
				var ec = Math.min(0.2 + power * 0.2, 1.5);
				var max = power * 2 + 1;
				for (i in 0...max) {
					var a = ec * ((i / (max - 1)) * 2 - 1);
					if (max == 1)
						a = 0;
					var sp:Float = 6;
					var fr = 1;
					var t = 50;
					if (a != 0) {
						sp = 6 / (1 + Math.abs(a));
						fr = 2;
						t = 38;
					}
					var shot = newShot(fr, sp, a, ray + 15);
					shot.damage = 1;
					shot.timer = t;
					shot.orient();
				}
				cd = 18;

			case 1:
				var shot = newShot(4, 12, 0, ray + 8);
				shot.damage = 0.75;
				shot.bList = [4];
				shot.decal = Math.random() * 628;
				shot.queue = "queueRocket";
				shot.timer = 50 + Math.random() * 10;
				shot.a += Math.sin(shot.decal / 100) * 0.5;
				shot.orient();
				shot.ray = 8;
				shot.updatePos();
				cd = 11 / (2 + power);

			case 2:
				for (n in 0...2) {
					var sens = n * 2 - 1;
					var shot = newShot(5, 8, sens * 0.5, ray + 8);
					shot.orient();
					shot.ft = 2;
					shot.flWarp = true;
					shot.timer = 32;
					shot.ray = 6 + power * 3;
					shot.root._yscale = 100 + power * 50;
					shot.flPierce = true;
					shot.damage = 0.75 + power * 0.75;
					cd = 12;
				}

			case 3:
				var shot = newShot(7 + power, 7, (Math.random() * 2 - 1) * 0.2, ray + 6);
				var ec = 1;
				shot.timer = 12 + Math.random() * 10 + power * 5;
				shot.x += (Math.random() * 2 - 1) * ec;
				shot.y += (Math.random() * 2 - 1) * ec;
				shot.damage = 0.14 + power * 0.08;
				cd = 0;
				for (i in 0...power + 1) {
					var p = new Part(Cs.game.dm.attach("partLight", Game.DP_PARTS));
					var a = angle + (Math.random() * 2 - 1) * 0.2;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var r = ray + 5;
					var sp = 2 + Math.random() * 10;
					p.x = x + ca * r;
					p.y = y + sa * r;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.timer = 10 + Math.random() * 10;
					p.setScale(50 + Math.random() * 100);
				}

			case 4:
				var shot = newShot(12, 6, (Math.random() * 2 - 1) * 0.2, ray + 16);
				shot.timer = 36;
				// shot.damage = 1
				shot.ray = 9;
				shot.bList = [3];
				shot.ca = 0.08;
				shot.va = 0.1;
				shot.ft = 3;
				shot.orient();
				cd = 8 / (power + 1);

				for (i in 0...4) {
					var p = new Part(Cs.game.dm.attach("partBlackBall", Game.DP_PARTS));
					var a = angle + (Math.random() * 2 - 1) * 0.4;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var r = ray + 5;
					var sp = 1 + Math.random() * 5;
					p.x = x + ca * r;
					p.y = y + sa * r;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.fadeType = 0;
					p.timer = 10 + Math.random() * 10;
					p.setScale(10 + Math.random() * 40);
				}
				for (i in 0...2) {
					var p = new Part(Cs.game.dm.attach("partLight", Game.DP_PARTS));
					var a = angle + (Math.random() * 2 - 1) * 0.2;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var r = ray + 5;
					var sp = 1 + Math.random() * 5;
					p.x = x + ca * r;
					p.y = y + sa * r;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.timer = 10 + Math.random() * 10;
					p.setScale(50 + Math.random() * 100);
				}

				vx -= shot.vx * 0.1;
				vy -= shot.vy * 0.1;
		}
		weaponCooldown = cd;
	}

	function fireSecondary() {
		if (secCooldown > 0 || secAmmo == 0)
			return;

		var cd:Float = null;
		var am = null;
		switch (secSelected) {
			case 0:
				for (n in 0...2) {
					for (i in 0...4) {
						newRocket(1.5 + i * 1.5, n * 2 - 1, 12 + i * 2);
					}
				}
				cd = 60;
				am = 16.5;

			case 1:
				flInvincible = true;
				var mc = dm.attach("mcShield", 2);
				shieldDecal = (shieldDecal + 63 * Timer.tmod) % 628;
				var a = shieldDecal / 100; // Math.random()*6.28;
				var ec = 16;
				mc._xscale = 100 + Math.cos(a) * ec;
				mc._yscale = 100 + Math.sin(a) * ec;
				cd = 0;
				am = Timer.tmod;

			case 2:
				magicBallList = new Array();
				for (i in 0...Cs.game.badsList.length) {
					var b:PointWithGetter = Cs.game.badsList[i];
					var mc = Cs.game.dm.attach("mcMagicBall", Game.DP_SHOT);
					mc._x = x;
					mc._y = y;
					magicBallList.push({
						sx: x,
						sy: y,
						opx: x,
						opy: y,
						mc: mc,
						trg: Cs.game.badsList[i],
						pos: 0,
						max: getDist(b),
					});
				}
				cd = 50;
				am = 34;

			case 3: // TELEPORT;

				var ghost = Cs.game.dm.attach("mcGhost", Game.DP_UNDERPARTS);
				ghost._x = x;
				ghost._y = y;
				ghost._rotation = root._rotation;
				var nx = null;
				var ny = null;
				var ntry = 0;
				while (true) {
					var flBreak = true;
					nx = Math.random() * Cs.mcw;
					ny = Math.random() * Cs.mch;
					for (i in 0...Cs.game.badsList.length) {
						var b = Cs.game.badsList[i];
						if (b.getDist({x: nx, y: ny}) < 150 - ntry * 2) {
							flBreak = false;
						}
					}
					if (flBreak)
						break;
					ntry++;
				}
				x = nx;
				y = ny;
				cd = 40;
				am = 50;

			case 4: // HYPERTHRUST;
				hyperThrustTimer = 60;
				var sp = 26;
				vx = Math.cos(angle) * sp;
				vy = Math.sin(angle) * sp;
				mcHyperThrust = dm.attach("mcHyperThrust", 1);
				flInvincible = true;
				flBounce = false;
				flWarp = true;
				cd = hyperThrustTimer + 10;
				am = 25;

			case 5: // SWARM;
				var shot = newShot(6, 10, 0, ray + 10);
				shot.timer = 100;
				shot.root.sub.gotoAndPlay(Std.string(Std.random(5) + 1));
				cd = 0;
				am = 0.5;
		}
		secAmmo = Math.max(secAmmo - am, 0);
		secCooldown = cd;
		Cs.game.inter.update();
	}

	function updateMagicBalls() {
		var i = magicBallList.length - 1;
		while (i >= 0) {
			var info = magicBallList[i];
			var dx = info.trg.x - info.sx;
			var dy = info.trg.y - info.sy;
			info.pos += 8 * Timer.tmod;
			var c = info.pos / info.max;
			if (c < 1) {
				info.mc._x = info.sx + dx * c;
				info.mc._y = info.sy + dy * c - Math.sin(c * 3.14) * 60;

				var ddx = info.mc._x - info.opx;
				var ddy = info.mc._y - info.opy;

				var mc = Cs.game.dm.attach("queueMagicBall", Game.DP_PARTS);
				mc._x = info.mc._x;
				mc._y = info.mc._y;
				mc._xscale = Math.sqrt(ddx * ddx + ddy * ddy);
				mc._rotation = Math.atan2(ddy, ddx) / 0.0174;

				info.opx = info.mc._x;
				info.opy = info.mc._y;

				if (Std.random(2) == 0) {
					var p = new Part(Cs.game.dm.attach("partMagicSpark", Game.DP_PARTS));
					p.x = info.mc._x;
					p.y = info.mc._y;
					p.setScale(40 + Math.random() * 150);
					p.timer = 10 + Math.random() * 10;
					p.vx = ddx * 0.1;
					p.vy = ddy * 0.1;
					p.fadeType = 0;
				}
			} else {
				info.trg.explode();
				magicBallList.splice(i--, 1);
				info.mc.removeMovieClip();
				continue;
			}
			i--;
		}
	}

	function updateHyperThrust() {
		if (hyperThrustTimer != null) {
			hyperThrustTimer -= Timer.tmod;
			if (hyperThrustTimer < 0) {
				hyperThrustTimer = null;
				mcHyperThrust.gotoAndPlay("death");

				// Log.trace(mcHyperThrust)
				// flInvincible = false;
				flBounce = true;
				flWarp = false;
			}
		}
	}

	//
	function newShot(frame, speed:Float, ang:Float, dist:Float) {
		if (ang == null)
			ang = 0;
		if (dist == null)
			dist = ray;
		var shot = new Shot(Cs.game.dm.attach("mcShot", Game.DP_SHOT));
		shot.root.gotoAndStop(Std.string(frame));
		var a = angle + ang;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		shot.x = x + ca * dist;
		shot.y = y + sa * dist;
		shot.vx = ca * speed;
		shot.vy = sa * speed;
		shot.flGood = true;
		shot.damage = 1;
		shot.speed = speed;
		shot.a = a;
		return shot;
	}

	function newRocket(speed, side, sleep) {
		var shot = newShot(3, speed, side * 1.8, ray);
		shot.thruster = {
			vx: Math.cos(angle) * 0.8,
			vy: Math.sin(angle) * 0.8,
			sleep: sleep,
		}
		shot.frict = 0.95;
		shot.damage = 1;
		shot.root._rotation = root._rotation;
		shot.ray = 8;
		shot.timer = 80 + sleep;
		shot.ft = 1;
		shot.flWarp = true;
		downcast(shot.root.sub).compt = 1 + sleep;

		return shot;
	}

	function newPlasmaWave() {}

	function explode() {
		fxOnde(ray * 2 + 20);
		throwDebris(10, 1);
		kill();
	}

	override function kill() {
		while (magicBallList.length > 0)
			magicBallList.pop().mc.removeMovieClip();

		/*
			for (i in 0...weaponPower.length) {

				var n = weaponPower.length-(i+1);
				var a = weaponPower[n];
				if(n>0)a++;

				var unit = Math.floor( Math.pow( csmulti, (n+1) )  );
				var b = Math.floor( cs/unit ) ;
				cs -= b*unit;
				if(a!=b)KKApi.flagCheater();

			}
		 */

		Cs.game.hero = null;
		KadoKadeoManager.kkm.gameOver(Cs.game.stats);

		super.kill();
	}

	//
	function checkBounds() {
		var c = -0.75;
		if (x < ray || x > Cs.mcw - ray) {
			vx *= c;
			x = Num.mm(ray, x, Cs.mcw - ray);
		}
		if (y < ray || y > Cs.mch - ray) {
			vy *= c;
			y = Num.mm(ray, y, Cs.mch - ray);
		}
	}

	function launchSparks(ang, max, vvx) {
		for (i in 0...max) {
			var p = new Part(Cs.game.dm.attach("partSpark", Game.DP_UNDERPARTS));
			var r = (ray + 5 + i * 4);
			var ca = Math.cos((angle - 3.14) + ang);
			var sa = Math.sin((angle - 3.14) + ang);

			p.x = x + ca * r;
			p.y = y + sa * r;

			//*
			var a = Math.random() * 6.28;
			var d = Math.random() * 16;
			var dx = Math.cos(a) * d;
			var dy = Math.sin(a) * d;
			p.x += dx;
			p.y += dy;
			p.root.sub._x -= dx + (Math.random() * 2 - 1) * 2;
			p.root.sub._y -= dy + (Math.random() * 2 - 1) * 2;
			//*/

			p.vx = ca * 1.5 * max; //-(vx*0.5+vvx)
			p.vy = sa * 1.5 * max; //-vy*0.5

			p.vr = 20 * (Math.random() * 2 - 1);
			p.timer = 10 + Math.random() * 10;
		}
	}
}
