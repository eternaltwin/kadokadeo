package starfang;

import pixi.core.math.Point;
import mt.bumdum.Lib.PointWithGetter;
import mt.bumdum.Part;
import kado.KadoKadeoManager;
import mt.bumdum.Lib.Num;
import common_haxe_avm1.KeyboardManager;
import mt.DepthManager;
import mt.Timer;

class Hero extends Phys {
	var flWarp:Bool;

	public var flInvincible:Bool;
	public var flBounce:Bool;

	// var cs:Int;
	// var csmulti:Int;
	public var turnSpeed:Float;
	public var speed:Float;
	public var accel:Float;
	public var angle:Float;
	public var hyperThrustTimer:Float;

	public var mainFlame:Float;
	public var mainFlameTrg:Float;

	// var weapon:{selected:Int, cd:Float, power:Array<Int>}
	var weaponSelected:Int;
	var weaponCooldown:Float;
	var weaponPower:Array<Int>;

	// var weaponPower : mt.flash.PArray<Int>;
	// var secondary:{ammo:Float, selected:Int, cd:Float}
	public var secAmmo:Float;
	public var secSelected:Int;
	public var secCooldown:Float;

	public var wings:Array<{mc:ASprite, flame:ASprite, trg:Float}>;

	var flame:ASprite;

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

	public function new(mc) {
		super(mc);
		flBounce = true;
		flInvincible = false;
		flWarp = false;
		mc.attachMovie("mcHeroBody", "mcHeroBody", 2);
		var eye = mc.attachMovie("mcHeroEye", "mcHeroEye", 4);
		eye._x = 8.5 * Cs.NEW_GEN_SCALE;
		flame = mc.attachMovie("flame", "flame", 1);
		flame._x = -11 * Cs.NEW_GEN_SCALE;
		flame.loop = true;
		flame.play();

		turnSpeed = 0.15;
		accel = 0.5 * Cs.NEW_GEN_SCALE;
		ray = 10 * Cs.NEW_GEN_SCALE;
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
		wings = [
			{mc: root.attachMovie("wing0", "wing0", 3), flame: root.attachMovie("flame", "wing0flame", 1), trg: 0},
			{mc: root.attachMovie("wing1", "wing1", 3), flame: root.attachMovie("flame", "wing1flame", 1), trg: 0}
		];
		// wings[0].mc._visible = false;
		wings[0].mc.pivot = new Point(7.5 * Cs.NEW_GEN_SCALE, 0);
		wings[0].mc._x = 6.5 * Cs.NEW_GEN_SCALE;
		wings[0].mc._y = -1 * Cs.NEW_GEN_SCALE;
		wings[0].flame._x = 10 * Cs.NEW_GEN_SCALE;
		wings[0].flame._y = -1 * Cs.NEW_GEN_SCALE;
		wings[0].flame._rotation = 25;
		wings[0].flame.scale.set(0.47, 0.63);
		wings[0].flame.loop = true;
		wings[0].flame.play();
		wings[1].mc.pivot = new Point(7.5 * Cs.NEW_GEN_SCALE, 0);
		wings[1].mc._x = 6.5 * Cs.NEW_GEN_SCALE;
		wings[1].mc._y = 1 * Cs.NEW_GEN_SCALE;
		wings[1].flame._x = 10 * Cs.NEW_GEN_SCALE;
		wings[1].flame._y = 1 * Cs.NEW_GEN_SCALE;
		wings[1].flame._rotation = -25;
		wings[1].flame.scale.set(0.47, -0.63);
		wings[1].flame.loop = true;
		wings[1].flame.play();

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
				p.root.play();
				p.root._rotation = Cs.rand() * 360;
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
		flame._xscale = mainFlame;
	}

	public function control() {
		if (hyperThrustTimer == null)
			flInvincible = false;

		wings[0].trg = 0;
		wings[1].trg = 0;
		mainFlameTrg = 0;

		if (KeyboardManager.isDown(KeyboardManager.LEFT)
			|| KeyboardManager.isDown(KeyboardManager.Q)
			|| KeyboardManager.isDown(KeyboardManager.A))
			turn(-1);
		if (KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D))
			turn(1);
		if (KeyboardManager.isDown(KeyboardManager.UP)
			|| KeyboardManager.isDown(KeyboardManager.Z)
			|| KeyboardManager.isDown(KeyboardManager.W)) {
			thrust(0, 1);
			mainFlameTrg = 100;
			launchSparks(0, 2, 0);
		}
		if (KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(KeyboardManager.ENTER))
			fireMain();
		if (KeyboardManager.isDown(KeyboardManager.DOWN)
			|| KeyboardManager.isDown(KeyboardManager.S)
			|| KeyboardManager.isDown(KeyboardManager.CONTROL))
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

	public function updateWeapon(id) {
		weaponPower[id] = Std.int(Math.min(weaponPower[id] + 1, Cs.WEAPON_POWER_MAX));
		weaponSelected = id;
		concentration = 1;
		// Log.trace("("+csmulti+") "+cs );
	}

	public function updateSecondary(id) {
		secAmmo = 100;
		secSelected = id;
		Cs.game.inter.update();
		concentration = 1;
	}

	function thrust(ma, power:Float) {
		vx += Math.cos(angle + ma) * accel * power * Timer.tmod;
		vy += Math.sin(angle + ma) * accel * power * Timer.tmod;
	}

	public function hit(shot) {}

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
					var sp:Float = 6 * Cs.NEW_GEN_SCALE;
					var fr = 1;
					var t = 50;
					if (a != 0) {
						sp = 6 * Cs.NEW_GEN_SCALE / (1 + Math.abs(a));
						fr = 2;
						t = 38;
					}
					var shot = newShot(fr, sp, a, ray + 15 * Cs.NEW_GEN_SCALE);
					shot.root.loop = true;
					shot.damage = 1;
					shot.timer = t;
					shot.orient();
				}
				cd = 18;

			case 1:
				var shot = newShot(4, 12 * Cs.NEW_GEN_SCALE, 0, ray + 8 * Cs.NEW_GEN_SCALE);
				shot.root.onFrame.set(8, function() {
					shot.root.gotoAndPlay(4);
				});
				shot.damage = 0.75;
				shot.bList = [4];
				shot.decal = Cs.rand() * 628;
				shot.queue = "queueRocket";
				shot.timer = 50 + Cs.rand() * 10;
				shot.a += Math.sin(shot.decal / 100) * 0.5;
				shot.orient();
				shot.ray = 8 * Cs.NEW_GEN_SCALE;
				shot.updatePos();
				cd = 11 / (2 + power);

			case 2:
				for (n in 0...2) {
					var sens = n * 2 - 1;
					var shot = newShot(5, 8 * Cs.NEW_GEN_SCALE, sens * 0.5, ray + 8 * Cs.NEW_GEN_SCALE);
					shot.root.stopOnFrame = [7];
					shot.root.onFrame.set(13, function() {
						shot.kill();
					});
					shot.orient();
					shot.ft = 2;
					shot.flWarp = true;
					shot.timer = 32;
					shot.ray = (6 + power * 3) * Cs.NEW_GEN_SCALE;
					shot.root._yscale = 100 + power * 50;
					shot.flPierce = true;
					shot.damage = 0.75 + power * 0.75;
					cd = 12;
				}

			case 3:
				var shot = newShot(7 + power, 7 * Cs.NEW_GEN_SCALE, (Cs.rand() * 2 - 1) * 0.2, ray + 6 * Cs.NEW_GEN_SCALE);
				var ec = 1 * Cs.NEW_GEN_SCALE;
				shot.timer = 12 + Cs.rand() * 10 + power * 5;
				shot.x += (Cs.rand() * 2 - 1) * ec;
				shot.y += (Cs.rand() * 2 - 1) * ec;
				shot.damage = 0.14 + power * 0.08;
				cd = 0;
				for (i in 0...power + 1) {
					var p = new Part(Cs.game.dm.attach("partLight", Game.DP_PARTS));
					var a = angle + (Cs.rand() * 2 - 1) * 0.2;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var r = ray + 5 * Cs.NEW_GEN_SCALE;
					var sp = (2 + Cs.rand() * 10) * Cs.NEW_GEN_SCALE;
					p.x = x + ca * r;
					p.y = y + sa * r;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.timer = 10 + Cs.rand() * 10;
					p.setScale(50 + Cs.rand() * 100);
				}

			case 4:
				var shot = newShot(12, 6 * Cs.NEW_GEN_SCALE, (Cs.rand() * 2 - 1) * 0.2, ray + 16 * Cs.NEW_GEN_SCALE);
				shot.timer = 36;
				// shot.damage = 1
				shot.ray = 9 * Cs.NEW_GEN_SCALE;
				shot.bList = [3];
				shot.ca = 0.08;
				shot.va = 0.1;
				shot.ft = 3;
				shot.orient();
				cd = 8 / (power + 1);

				for (i in 0...4) {
					var p = new Part(Cs.game.dm.attach("partBlackBall", Game.DP_PARTS));
					var a = angle + (Cs.rand() * 2 - 1) * 0.4;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var r = ray + 5 * Cs.NEW_GEN_SCALE;
					var sp = (1 + Cs.rand() * 5) * Cs.NEW_GEN_SCALE;
					p.x = x + ca * r;
					p.y = y + sa * r;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.fadeType = 0;
					p.timer = 10 + Cs.rand() * 10;
					p.setScale(10 + Cs.rand() * 40);
				}
				for (i in 0...2) {
					var p = new Part(Cs.game.dm.attach("partLight", Game.DP_PARTS));
					var a = angle + (Cs.rand() * 2 - 1) * 0.2;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var r = ray + 5 * Cs.NEW_GEN_SCALE;
					var sp = (1 + Cs.rand() * 5) * Cs.NEW_GEN_SCALE;
					p.x = x + ca * r;
					p.y = y + sa * r;
					p.vx = ca * sp;
					p.vy = sa * sp;
					p.timer = 10 + Cs.rand() * 10;
					p.setScale(50 + Cs.rand() * 100);
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
				mc.removeOnFrame = 5;
				mc.play();
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
					mc.play();
					mc.loop = true;
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
						max: getDist({x: b.x, y: b.y}),
					});
				}
				cd = 50;
				am = 34;

			case 3: // TELEPORT;

				var ghost = Cs.game.dm.attach("mcGhost", Game.DP_UNDERPARTS);
				ghost.play();
				ghost.removeOnFrame = 7;
				ghost._x = x;
				ghost._y = y;
				ghost._rotation = root._rotation;
				var nx = null;
				var ny = null;
				var ntry = 0;
				while (true) {
					var flBreak = true;
					nx = Cs.rand() * Cs.mcw;
					ny = Cs.rand() * Cs.mch;
					for (i in 0...Cs.game.badsList.length) {
						var b = Cs.game.badsList[i];
						if (b.getDist({x: nx, y: ny}) < 150 * Cs.NEW_GEN_SCALE - ntry * 2 * Cs.NEW_GEN_SCALE) {
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
				var sp = 26 * Cs.NEW_GEN_SCALE;
				vx = Math.cos(angle) * sp;
				vy = Math.sin(angle) * sp;
				mcHyperThrust = dm.attach("mcHyperThrust", 1);
				mcHyperThrust.onFrame.set(8, function() {
					mcHyperThrust.gotoAndPlay(6);
				});
				mcHyperThrust.removeOnFrame = 19;
				mcHyperThrust.play();
				flInvincible = true;
				flBounce = false;
				flWarp = true;
				cd = hyperThrustTimer + 10;
				am = 25;

			case 5: // SWARM;
				var shot = newShot(6, 10 * Cs.NEW_GEN_SCALE, 0, ray + 10 * Cs.NEW_GEN_SCALE);
				shot.timer = 100;
				shot.root.gotoAndPlay(Cs.random(5) + 1);
				shot.root.loop = true;
				cd = 0;
				am = 0.5;
		}
		secAmmo = Math.max(secAmmo - am, 0);
		secCooldown = cd;
		Cs.game.inter.update();
	}

	function updateMagicBalls() {
		if (magicBallList == null)
			return;
		var i = magicBallList.length - 1;
		while (i >= 0) {
			var info = magicBallList[i];
			var dx = info.trg.x - info.sx;
			var dy = info.trg.y - info.sy;
			info.pos += 8 * Cs.NEW_GEN_SCALE * Timer.tmod;
			var c = info.pos / info.max;
			if (c < 1) {
				info.mc._x = info.sx + dx * c;
				info.mc._y = info.sy + dy * c - Math.sin(c * 3.14) * 60 * Cs.NEW_GEN_SCALE;

				var ddx = info.mc._x - info.opx;
				var ddy = info.mc._y - info.opy;

				var mc = Cs.game.dm.attach("queueMagicBall", Game.DP_PARTS);
				mc.removeOnFrame = 16;
				mc.play();
				mc._x = info.mc._x;
				mc._y = info.mc._y;
				mc._xscale = Math.sqrt(ddx * ddx + ddy * ddy);
				mc._rotation = Math.atan2(ddy, ddx) / 0.0174;

				info.opx = info.mc._x;
				info.opy = info.mc._y;

				if (Cs.random(2) == 0) {
					var p = new Part(Cs.game.dm.attach("partMagicSpark", Game.DP_PARTS));
					p.root.loop = true;
					p.root.play();
					p.x = info.mc._x;
					p.y = info.mc._y;
					p.setScale(40 + Cs.rand() * 150);
					p.timer = 10 + Cs.rand() * 10;
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
				mcHyperThrust.gotoAndPlay(9);

				// Log.trace(mcHyperThrust)
				// flInvincible = false;
				flBounce = true;
				flWarp = false;
			}
		}
	}

	//
	function newShot(frame:Int, speed:Float, ang:Float, dist:Float) {
		if (ang == null)
			ang = 0;
		if (dist == null)
			dist = ray;
		var shot = new Shot(Cs.game.dm.attach("mcShot" + frame, Game.DP_SHOT));
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
		shot.root.play();
		return shot;
	}

	function newRocket(speed:Float, side, sleep) {
		var shot = newShot(3, speed * Cs.NEW_GEN_SCALE, side * 1.8, ray);
		shot.thruster = {
			vx: Math.cos(angle) * 0.8 * Cs.NEW_GEN_SCALE,
			vy: Math.sin(angle) * 0.8 * Cs.NEW_GEN_SCALE,
			sleep: sleep,
		}
		shot.frict = 0.95;
		shot.damage = 1;
		shot.root._rotation = root._rotation;
		shot.ray = 8 * Cs.NEW_GEN_SCALE;
		shot.timer = 80 + sleep;
		shot.ft = 1;
		shot.flWarp = true;
		var compt = 1 + sleep;
		shot.root.onFrame.set(2, function() {
			compt--;
			if (compt > 0) {
				shot.root.gotoAndPlay(1);
			}
		});
		shot.root.stopOnFrame = [6];

		return shot;
	}

	function newPlasmaWave() {}

	public function explode() {
		fxOnde(ray * 2 + 20 * Cs.NEW_GEN_SCALE);
		throwDebris(10, 1);
		kill();
	}

	override function kill() {
		while (magicBallList != null && magicBallList.length > 0)
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

	public function launchSparks(ang, max, vvx:Float) {
		for (i in 0...max) {
			var p = new Part(Cs.game.dm.attach("partSpark", Game.DP_UNDERPARTS));
			var r = (ray + 5 * Cs.NEW_GEN_SCALE + i * 4 * Cs.NEW_GEN_SCALE);
			var ca = Math.cos((angle - 3.14) + ang);
			var sa = Math.sin((angle - 3.14) + ang);

			p.x = x + ca * r;
			p.y = y + sa * r;

			//*
			var a = Cs.rand() * 6.28;
			var d = Cs.rand() * 16 * Cs.NEW_GEN_SCALE;
			var dx = Math.cos(a) * d;
			var dy = Math.sin(a) * d;
			p.x += dx;
			p.y += dy;
			p.root._x -= dx + (Cs.rand() * 2 - 1) * 2 * Cs.NEW_GEN_SCALE;
			p.root._y -= dy + (Cs.rand() * 2 - 1) * 2 * Cs.NEW_GEN_SCALE;
			p.root.play();
			//*/

			p.vx = ca * 1.5 * Cs.NEW_GEN_SCALE * max; //-(vx*0.5+vvx)
			p.vy = sa * 1.5 * Cs.NEW_GEN_SCALE * max; //-vy*0.5

			p.vr = 20 * (Cs.rand() * 2 - 1);
			p.timer = 10 + Cs.rand() * 10;
		}
	}
}
