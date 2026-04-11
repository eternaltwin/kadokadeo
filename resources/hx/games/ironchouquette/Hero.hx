package ironchouquette;

import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.KKApi;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;
import pixi.core.Pixi.BlendModes;

class OndeSprite extends ASprite {
	public var list:Array<Bads>;
}

class LaserRayListSprite extends ASprite {
	public var vr:Float;
	public var t:Float;
}

class LaserRaySprite extends ASprite {
	public var t:Float;
	public var ray:ASprite;
	public var dm:DepthManager;
	public var list:Array<LaserRayListSprite>;
}

class BlackHoleSpritePart extends Part {
	public var black:Float;
	public var mask:ASprite;
}

class BlackHoleSprite extends ASprite {
	public var vr:Float;
	public var step:Int;
	public var list:Array<BlackHoleSpritePart>;
}

class Hero extends Phys {
	public inline static var WP_PLASMA = 0;
	public inline static var WP_SIDER = 1;
	public inline static var WP_LASER = 2;
	public inline static var WP_SPEED = 3;
	public inline static var WP_VOID = 4;
	public inline static var WP_MISSILE = 5;

	public static var RAY = 8 * Cs.NEW_GEN_SCALE;
	public static var INVINCIBLE_RAY = 32 * Cs.NEW_GEN_SCALE;

	var reactorPosOnFrame:Array<Array<{x:Float, y:Float}>> = [
		[{x: 34, y: 13}, {x: 51, y: 13}],
		[{x: 33, y: 13}, {x: 52, y: 13}],
		[{x: 32, y: 13}, {x: 53, y: 13}],
		[{x: 30, y: 13}, {x: 54, y: 13}],
		[{x: 28, y: 13}, {x: 56, y: 13}],
		[{x: 26, y: 13}, {x: 58, y: 13}],
		[{x: 24, y: 13}, {x: 60, y: 13}],
		[{x: 22, y: 13}, {x: 62, y: 13}],
		[{x: 20, y: 13}, {x: 64, y: 13}],
		[{x: 17, y: 13}, {x: 66, y: 13}],
		[{x: 20, y: 13}, {x: 64, y: 13}],
		[{x: 22, y: 13}, {x: 62, y: 13}],
		[{x: 24, y: 13}, {x: 60, y: 13}],
		[{x: 26, y: 13}, {x: 58, y: 13}],
		[{x: 28, y: 13}, {x: 56, y: 13}],
		[{x: 30, y: 13}, {x: 54, y: 13}],
		[{x: 32, y: 13}, {x: 53, y: 13}],
		[{x: 33, y: 13}, {x: 52, y: 13}],
		[{x: 34, y: 13}, {x: 51, y: 13}],
		[{x: 35, y: 13}, {x: 50, y: 13}],
	];

	var flame1:ASprite;
	var flame2:ASprite;

	public var flControl:Bool;

	public var slotMax:Int;
	public var speed:Float;
	public var rollX:Float;
	public var rollY:Float;
	public var invincibleTimer:Float;

	public var dm:DepthManager;

	// LASER
	public var laserStartAngle:Float;
	public var laserTrg:Bads;
	public var laserFlip:Int;
	public var laserList:Array<Array<Float>>;
	public var laserRay:LaserRaySprite;

	// SONIC BOOM
	public var onde:OndeSprite;
	public var blackHole:BlackHoleSprite;

	public var boxes:Array<ASprite>;
	public var slots:Array<Int>;
	public var cslots:Array<Int>;
	public var weapons:Array<Array<Dynamic>>;
	public var cweapons:Array<Array<Int>>;

	public var lastLaser:ASprite;

	public function new(mc) {
		super(mc);
		flame1 = mc.attachMovie("mcFlame", "flame1", -1);
		flame2 = mc.attachMovie("mcFlame", "flame2", -1);
		flame1.loop = true;
		flame1.play();
		flame2.loop = true;
		flame2.play();
		updateFlamePos();

		ray = RAY;
		speed = 3.6 * Cs.NEW_GEN_SCALE;
		frict = 0.6;

		laserStartAngle = 0;
		laserFlip = 0;

		rollX = 0;
		rollY = 0;

		slots = [];
		cslots = [];
		weapons = [];
		cweapons = [];
		boxes = new Array();
		for (i in 0...3)
			addBox();
		for (i in 0...6) {
			weapons[i] = [(i == 0) ? 1 : 0, 0];
			cweapons[i] = [(i == 0) ? 1 : 0, 0];
		}

		dm = new DepthManager(root);
		flControl = false;
		root.gotoAndStop(10);

		x = Cs.mcw * 0.5 - 5 * Cs.NEW_GEN_SCALE;
		y = Cs.mch + ray;
	}

	public function updateFlamePos() {
		var frame = this.root._currentframe - 1;
		var poses = reactorPosOnFrame[frame];
		flame1._x = poses[0].x - root._width * 0.5;
		flame1._y = poses[0].y;
		flame2._x = poses[1].x - root._width * 0.5;
		flame2._y = poses[1].y;
	}

	public override function update() {
		super.update();
		updateFlamePos();

		if (flControl) {
			control();
			updateShoot();
		} else {
			y -= 0.8 * Cs.NEW_GEN_SCALE * Timer.tmod;
		}

		if (onde != null)
			updateOnde();
		if (laserRay != null)
			updateLaserRay();
		if (blackHole != null)
			updateBlackHole();
		if (invincibleTimer != null)
			updateInvincible();

		if (!flControl && Stykades.dif > 56) {
			Game.SCROLL_SPEED += 2.4 * Cs.NEW_GEN_SCALE;
			flControl = true;
		}

		// CHECK CHEAT
		for (i in 0...6) {
			if (weapons[i][0] != cweapons[i][0])
				KKApi.flagCheater();
		}
		for (i in 0...slots.length) {
			if (slots[i] != cslots[i])
				KKApi.flagCheater();
		}

		// TODO: getCheat does not exist
		// if (boxes.getCheat())
		// 	KKApi.flagCheater();
	}

	public function updateInvincible() {
		invincibleTimer -= Timer.tmod;

		Col.setPercentColor(root, 70 + Math.cos(invincibleTimer * 0.5) * 20, 0xFFFFFF);

		var size = Math.min(invincibleTimer / 50, 1);
		// PARTS

		var p = new Part(Cs.game.dm.attach("partInvincibility", Game.DP_UNDERPARTS));
		var a = Cs.rand() * 6.28;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		var r = 0;
		var sp = 1.5 + Cs.rand() * 1.5;
		p.x = x;
		p.y = y - 6 * Cs.NEW_GEN_SCALE;
		p.vx = ca * sp;
		p.vy = sa * sp + 4 * Cs.NEW_GEN_SCALE;
		p.plasmaId = 1;
		p.timer = 10;
		p.fadeType = 0;
		p.root.blendMode = BlendModes.ADD;
		p.setScale((150 + Cs.rand() * 100) * size);

		if (invincibleTimer < 0) {
			invincibleTimer = null;
			ray = RAY;
			Col.setPercentColor(root, 0, 0xFFFFFF);
		}
		var pdm = new DepthManager(p.root);

		//
		if (Cs.rand() * 3 < 1) {
			var mc = pdm.attach("mcLaserLight", 0);
			mc._rotation = Cs.rand() * 360;
			mc._xscale = 100 + Cs.rand() * 100;
			mc._yscale = 50 + Cs.rand() * 100;
		}
	}

	public function control() {
		var boost = weapons[3][0];
		var sp = Math.min(speed + boost * 1.6 * Cs.NEW_GEN_SCALE, 10 * Cs.NEW_GEN_SCALE) * Timer.tmod;

		// MOVE
		var mx:Float = 0;
		var my:Float = 0;
		var bent = 0.25;
		if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
			mx -= sp;
			laserStartAngle -= bent;
			rollX -= Timer.tmod * 5;
		}
		if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
			mx += sp;
			laserStartAngle += bent;
			rollX += Timer.tmod * 5;
		}
		if (KeyboardManager.isDown(KeyboardManager.UP)) {
			my -= sp;
			rollY -= Timer.tmod * 3.5;
		}
		if (KeyboardManager.isDown(KeyboardManager.DOWN)) {
			my += sp;
			rollY += Timer.tmod * 3.5;
		}
		rollX *= 0.6;
		rollY *= Math.pow(0.87, Timer.tmod);
		laserStartAngle *= Math.pow(0.94, Timer.tmod);

		// BOOST

		if (boost > 0) {
			var max = 2;
			for (k in 0...max) {
				var coef = k / max;
				var mc = Cs.game.dm.attach("mcSpeed", Game.DP_PARTS);
				mc._x = x + mx * coef;
				mc._y = y + (my + Game.SCROLL_SPEED) * coef;
				mc._xscale = (120 + boost * 40) * 1.7;
				//
				mc._yscale = mc._xscale;
				mc.gotoAndStop(boost);
				// mc.blendMode = BlendModes.ADD
				Cs.game.plasmaDraw(mc, 0);

				for (i in 0...3) {
					var a = Cs.rand() * 6.28;
					var ray = (20 + Cs.rand() * 50) * Cs.NEW_GEN_SCALE;
					mc._x = x + Math.cos(a) * ray;
					mc._y = y + Math.sin(a) * ray;
					mc._xscale = 100 + Cs.rand() * 150;
					mc._yscale = mc._xscale;
					Cs.game.plasmaDraw(mc, 0);
				}

				mc.removeMovieClip();
			}

			var r = ray * (((60 + boost * 40) * 1.7) / 100) * 1.3;
			for (i in 0...boost) {
				var p = new Part(Cs.game.dm.attach("partSparkSpeed", Game.DP_UNDERPARTS));
				p.x = x + (Cs.rand() * 2 - 1) * r;
				p.y = y + (Cs.rand() * 2 - 1) * r;
				p.setScale(10 + Cs.rand() * (15 + boost * 5));
				p.root.gotoAndPlay(Cs.random(p.root._totalframes) + 1);
				// TODO: uncomment
				// downcast(p.root).compt = 100;
				p.vy = Game.SCROLL_SPEED;
				p.timer = 20 + Cs.rand() * 10;
			}
		}

		x += mx;
		y += my;

		// GFX
		var frame = 1 + Std.int(Num.mm(0, 10 + rollX, 20));
		root.gotoAndStop(frame);

		// COL
		checkBounds();
	}

	// WEAPON
	public function addWeapon(id) {
		if (slots.length == boxes.length) {
			sacrifice(0);
		}
		weapons[id][0]++;
		cweapons[id][0]++;
		slots.push(id);
		cslots.push(id);
		updateBoxes();
	}

	public function addBox() {
		var mc = Cs.game.dm.attach("mcSlot", Game.DP_INTER);
		var m = 8 * Cs.NEW_GEN_SCALE;
		mc._x = m;
		mc._y = Cs.mch - (m + boxes.length * (m + 5 * Cs.NEW_GEN_SCALE));
		mc.stop();
		boxes.push(mc);
	}

	public function updateBoxes() {
		for (i in 0...boxes.length) {
			var id = slots[i];
			if (id == null)
				id = -1;
			boxes[i].gotoAndStop(id + 2);
		}
	}

	public function sacrifice(n) {
		if (slots.length == 0)
			return;
		if (n == null)
			n = slots.length - 1;
		var id = slots[n];
		weapons[id][0]--;
		cweapons[id][0]--;
		slots.splice(n, 1);
		cslots.splice(n, 1);
		updateBoxes();

		Cs.game.stats.b.push([Std.int(Stykades.dif), 100 + id]);
		switch (id) {
			case Hero.WP_PLASMA:
				var shot = newShot(0, 14, 18);
				shot.ray = 50 * Cs.NEW_GEN_SCALE;
				shot.damage = 50;
				shot.flPierce = true;
				shot.bList.push(11);
			// shot.vr = (Math.random()*2-1)*10
			case Hero.WP_SIDER:
				if (onde != null)
					onde.removeMovieClip();
				onde = cast Cs.game.dm.attach("mcSonicBoom", Game.DP_UNDERPARTS);
				onde.list = new Array();
				onde._x = x;
				onde._y = y;
				onde._xscale = 80;
				onde._yscale = onde._xscale;
			case Hero.WP_VOID:
				if (blackHole == null) {
					blackHole = cast Cs.game.dm.attach("mcBlackHole", Game.DP_UNDERPARTS);
					blackHole.list = new Array();
					blackHole._x = x;
					blackHole._y = y;
					blackHole.step = 0;
					blackHole._xscale = 10;
					blackHole._yscale = 10;
					blackHole.vr = 10;

					var list:Array<Phys> = new Array();
					for (b in Cs.game.badsList)
						list.push(b);
					for (s in Cs.game.shotList)
						list.push(s);

					while (list.length > 0) {
						var b = list.pop();
						if (b.flash != null) {
							b.flash = 0;
							b.updateFlash();
						}
						var p = new BlackHoleSpritePart(b.root);
						p.x = b.x;
						p.y = b.y;
						p.vx = b.vx;
						p.vy = b.vy;
						p.frict = 0.94;
						p.ray = b.ray;
						p.black = 0;
						p.root.stop();
						b.root = null;
						b.kill();
						blackHole.list.push(p);
					}
				}

			/*
				while( blackHole.list.length<150 ){
					var p =  downcast(new Part(Cs.game.dm.attach("partBlackHole",Game.DP_PARTS)));
					p.x = Math.random()*Cs.mcw;
					p.y = Math.random()*Cs.mch;
					p.ray2 = 14;
					p.frict = 0.94;
					blackHole.list.push(p);
				}
			 */
			case Hero.WP_SPEED:
				if (laserRay == null) {
					laserRay = cast Cs.game.dm.attach("mcBigLaser", Game.DP_UNDERPARTS);
					laserRay.blendMode = BlendModes.ADD;
					laserRay._xscale = 0;
					laserRay.dm = new DepthManager(laserRay);
					laserRay.list = new Array();
					for (i in 0...12) {
						var mc:LaserRayListSprite = cast laserRay.dm.attach("mcLaserRay", 0);
						mc._rotation = Cs.rand() * 360;
						mc._xscale = 100 + Cs.rand() * 100;
						mc._yscale = 100 + Cs.rand() * 500;
						mc.t = 10 + Cs.rand() * 50;
						mc.blendMode = BlendModes.ADD;
						mc.vr = (Cs.rand() * 2 - 1) * 5;
						laserRay.list.push(mc);
					}
					laserRay.t = 80;
				}

			case Hero.WP_LASER:
				invincibleTimer = 300;
				ray = INVINCIBLE_RAY; // ADD;

			case Hero.WP_MISSILE:
				var max = 12;
				for (i in 0...max) {
					var shot = newMissile(6.28 * i / max);
					shot.sleep = 6;
					shot.timer = 60;
				}
			case null:
				Cs.game.bt = {trg: 0.3, timer: 100, val: 1};
			case _:
		}
		// CLEAN SHOOT
		var list = Cs.game.shotList.copy();
		for (i in 0...list.length) {
			var shot = list[i];
			if (shot.flGood != true)
				shot.kill();
		}
		//
		Cs.game.flashouille = 100;
		Cs.game.lagTimer = -70;
		Stykades.nextWave = 100;
	}

	public function updateShoot() {
		var flFire = KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(18) || KeyboardManager.isDown(13);

		if (lastLaser != null && lastLaser._visible)
			lastLaser.removeMovieClip();

		for (i in 0...6) {
			var a = weapons[i];
			if (a[0] > 0) {
				if (a[1] > 0)
					a[1] = Std.int(a[1] - Timer.tmod);
				while (flFire && a[1] <= 0 && blackHole == null && laserRay == null) {
					switch (i) {
						case 0: // PLASMA
							switch (a[0]) {
								case 1:
									var shot = newShot(0, 12, 14);
									shot.ray = 6 * Cs.NEW_GEN_SCALE;
									shot.damage = 1;
								case 2:
									for (n in 0...2) {
										var shot = newShot(0, 12, 14);
										shot.ray = 6 * Cs.NEW_GEN_SCALE;
										shot.x = x + (n * 2 - 1) * 5 * Cs.NEW_GEN_SCALE;
										shot.damage = 1;
									}
								case 3:
									{
										var shot = newShot(0, 15, 14);
										shot.ray = 8 * Cs.NEW_GEN_SCALE;
										shot.setScale(150);
										shot.damage = 2;
										shot.flPierce = true;
									}
									for (n in 0...2) {
										var sens = n * 2 - 1;
										var shot = newShot(sens * 0.15, 12, 14);
										shot.ray = 8 * Cs.NEW_GEN_SCALE;
										shot.x = x + sens * 5 * Cs.NEW_GEN_SCALE;
										shot.damage = 1;
									}
								case _:
									{
										var shot = newShot(0, 15, 14);
										shot.ray = (4 + a[0]) * Cs.NEW_GEN_SCALE;
										shot.setScale(100 + a[0] * 25);
										shot.damage = 1 + (a[0] * 0.5);
										shot.flPierce = true;
									}
									for (n in 0...2) {
										var sens = n * 2 - 1;
										for (k in 0...Std.int(a[0] * 0.5)) {
											var shot = newShot(sens * (0.15 + k * 0.15), 12 - (k * 1.5), 14);
											shot.ray = 8 * Cs.NEW_GEN_SCALE;
											shot.x = x + sens * (5 + k * 5) * Cs.NEW_GEN_SCALE;
											shot.damage = 1;
										}
									}
							}
							a[1] += 8;

						case 5: // MISSILES
							for (n in 0...2) {
								var sens = n * 2 - 1;
								for (k in 0...a[0]) {
									var c = (k / (a[0] - 1)) - 0.5;
									if (a[0] == 1)
										c = 0;
									var ec = 0.5 + a[0] * 0.2;

									var shot = newMissile(sens * 1.9 + ec * c);
								}
							}
							a[1] += 40; // 50;

						case 1: // SIDER
							for (n in 0...2) {
								var max = Std.int(Math.min(a[0], 6));
								for (k in 0...max) {
									var sens = n * 2 - 1;

									var c = (k / (max - 1)) - 0.5;
									if (max == 1)
										c = 0;
									var ec = 0.3 + a[0] * 0.1;

									var shot = newShot(sens * (1.57 - rollY * 0.05) + ec * c, 14, 16);
									shot.damage = 0.85;
									// shot.root._xscale = sens*100
									shot.x += sens * 14 * Cs.NEW_GEN_SCALE;
									shot.y += 16 * Cs.NEW_GEN_SCALE;
									shot.orient();
									shot.updatePos();

									if (k > 1 && k < max - 1) {
										shot.setScale(150);
										shot.damage = 1.5;
										shot.speed = 18 * Cs.NEW_GEN_SCALE;
										shot.updateVit();
										shot.x += sens * 6 * Cs.NEW_GEN_SCALE;
									}
								}
							}
							a[1] += 5;

						case 2: // LASER

							// SEEK
							if (laserTrg == null || laserTrg.flDeath) {
								var dist = 1 / 0;
								laserTrg = cast {
									get_x: function() {
										return x;
									},
									get_y: function() {
										return -20 * Cs.NEW_GEN_SCALE;
									},
									ray: 10 * Cs.NEW_GEN_SCALE,
									damage: null,
									flDeath: true,
									shieldLim: null
								};
								for (n in 0...Cs.game.badsList.length) {
									var b = Cs.game.badsList[n];
									var d = getDist({x: b.x, y: b.y});
									if (d < dist) {
										laserTrg = b;
										dist = d;
									}
								}
							}

							// CREATE LIST
							var op = [x, y - 6];
							var list = [op];
							var angle = -1.57;
							if (!laserTrg.flDeath)
								angle += laserStartAngle;
							var va = 0.1;
							var ca = 0.1;
							var sp = 7 * Cs.NEW_GEN_SCALE;
							var tr = 0;

							while (true) {
								var dx = laserTrg.x - op[0];
								var dy = laserTrg.y - op[1];
								var ta = Math.atan2(dy, dx);
								var da = Num.hMod(ta - angle, 3.14);
								angle += Num.mm(-va, da * ca, va);
								var nx = op[0] + Math.cos(angle) * sp;
								var ny = op[1] + Math.sin(angle) * sp;
								if (laserTrg.shieldLim != null) {
									var dist = Cs.getDist({x: Std.int(laserTrg.x), y: Std.int(laserTrg.y)}, {x: Std.int(nx), y: Std.int(ny)});
									if (dist < laserTrg.shieldLim) {
										angle = Cs.getAng({x: Std.int(nx), y: Std.int(ny)}, {x: Std.int(laserTrg.x), y: Std.int(laserTrg.y)})
											+ laserStartAngle * 0.2;
										ca = 0.5;
										va = 10;
									}
								}

								var np = [nx, ny];
								list.push(np);
								op = np;

								if (Math.abs(dx) + Math.abs(dy) < laserTrg.ray * 0.5) {
									break;
								}
								if (tr++ > 100)
									break;

								ca = Math.min(ca + 0.01, 1);
								va += 0.01;
							}

							// DRAW
							//*
							laserFlip = (laserFlip + 1) % 2;
							var s0 = 12 + (a[0] + laserFlip * 2) * 3 * Cs.NEW_GEN_SCALE;
							var s1 = 1 + (a[0] + laserFlip) * 2.5 * Cs.NEW_GEN_SCALE;
							var mc = Cs.game.dm.empty(Game.DP_PARTS);

							mc.lineStyle(s0, 0xFF0000, 30);
							mc.moveTo(list[0][0], list[0][1]);
							for (n in 1...list.length) {
								var p = list[n];
								mc.lineTo(p[0], p[1]);
							}

							mc.lineStyle(s1, 0xFFFFFF, 100);
							mc.moveTo(list[0][0], list[0][1]);
							for (n in 1...list.length) {
								var p = list[n];
								mc.lineTo(p[0], p[1]);
							}
							//*/

							//*
							var ba = 2;
							var br = 2;
							var ra = 3 * Cs.NEW_GEN_SCALE + s1;
							mc.lineStyle(1, 0xFFFFFF, 100);
							for (n in 0...3) {
								var k = 0;
								var st = Cs.random(list.length - 3);
								mc.moveTo(list[st][0], list[st][1]);
								while (Cs.random(k) == 0) {
									k++;
									st = Std.int(Math.min(st + ba + Cs.random(br), list.length - 1));
									var px = list[st][0] + (Cs.rand() * 2 - 1) * ra;
									var py = list[st][1] + (Cs.rand() * 2 - 1) * ra;
									mc.lineTo(px, py);
								}
								st = Std.int(Math.min(st + ba + Cs.random(br), list.length - 1));
								mc.lineTo(list[st][0], list[st][1]);
							}
							//*/

							//*
							if (Cs.game.gfxMode >= 1) {
								mc.blendMode = BlendModes.ADD;
								Cs.game.plasmaDraw(mc, 1);
								mc.removeMovieClip();
							} else {
								lastLaser = mc;
							}
							//*/
							laserList = list;

							a[1] = 0.1;
						case 4: // VOID BALLS

							var shot = newShot((Cs.rand() * 2 - 1) * (0.3 + a[0] * 0.15), 10, 17);
							shot.damage = 1.2;
							shot.orient();
							// shot.plasmaId = 1
							shot.bList.push(4);
							shot.speed = 12 * Cs.NEW_GEN_SCALE;
							shot.decal = Cs.rand() * 628;

							a[1] += 18 / (a[0] * 4);
						case 3: // SPEED UP
							a[1] = 0.1;
						case _:
					}
				}
			}
		}

		if (!flFire) {
			laserTrg = null;
			laserList = null;
		}
	}

	// SPECIAL
	public function updateLaserRay() {
		laserRay._x = x;
		laserRay._y = y;
		if (laserRay.t >= 10) {
			laserRay._xscale += 32 * Timer.tmod;
		} else {
			if (laserRay.t < 0 && laserRay._currentframe == 1)
				laserRay.play();
		}
		laserRay._xscale *= Math.pow(0.9, Timer.tmod);
		laserRay.t -= Timer.tmod;

		var i = 0;
		while (i < laserRay.list.length) {
			var mc = laserRay.list[i];
			var dr = Num.hMod(-90 - mc._rotation, 180);

			mc._rotation += mc.vr + dr * 0.03 * Timer.tmod;
			mc._xscale += 10;
			mc.t -= Timer.tmod;

			if (laserRay.t < 10) {
				mc._yscale *= 0.6;
			}

			if (mc.t < 10) {
				mc._alpha = mc.t * 10;
				if (mc.t < 0) {
					mc.removeMovieClip();
					laserRay.list.splice(i, 1);
					continue;
				}
			}

			/*
				var lim = 100;
				mc._rotation +=Num.mm(-lim,dr*0.2*Timer.tmod,lim);
				mc._xscale *= 1.05;
				mc._yscale *= 0.95;
				if(Math.abs(dr)<2){
					mc.removeMovieClip();
					laserRay.list.splice(i--,1);
				}
				// */
			i++;
		}

		while (laserRay.list.length < Math.min(12, laserRay.t * 0.5)) {
			var mc:LaserRayListSprite = cast laserRay.dm.attach("mcLaserRay", 0);
			mc._rotation = Cs.rand() * 360;
			mc._xscale = 100 + Cs.rand() * 100;
			mc._yscale = 100 + Cs.rand() * 1000;
			mc.t = 10 + Cs.rand() * 60;
			mc.blendMode = BlendModes.ADD;
			mc.vr = (Cs.rand() * 2 - 1) * 5;
			laserRay.list.push(mc);
		}
		if (laserRay.t > 0) {
			for (b in Cs.game.badsList) {
				if (b == null)
					continue;
				if (Math.abs(b.x - x) < (8 * Cs.NEW_GEN_SCALE * laserRay._xscale / 100) + b.ray && b.y < y) {
					b.damage(2.5 * Timer.tmod);
				}
			}
		} else {
			if (laserRay.t < -10) {
				laserRay.removeMovieClip();
				laserRay = null;
			}
		}
	}

	public function updateOnde() {
		onde._xscale *= 1.25;
		onde._yscale = onde._xscale;

		for (i in 0...Cs.game.badsList.length) {
			var b = Cs.game.badsList[i];
			var flStrike = true;
			for (n in 0...onde.list.length) {
				if (b == onde.list[n]) {
					flStrike = false;
					break;
				}
			}

			if (flStrike && b.getDist({x: onde._x, y: onde._y}) < onde._xscale * 0.5) {
				b.damage(5);
				onde.list.push(b);
			}
		}

		if (onde._xscale > Cs.mcw * 2) {
			onde.removeMovieClip();
			onde = null;
		}
	}

	public function updateBlackHole() {
		blackHole.vr *= 1.05;
		blackHole._rotation += 12 * Timer.tmod;

		var acc = 1;
		var bh = {x: blackHole._x, y: blackHole._y}
		var flAllMasked = true;

		var i = 0;
		while (i < blackHole.list.length) {
			var p = blackHole.list[i];

			if (p.mask != null) {
				p.vx *= 1.2;
				p.vy *= 1.2;

				p.black = Math.min(p.black + 8 * Timer.tmod, 100);
				Col.setPercentColor(p.root, p.black, 0);

				if (p.getDist(bh) > blackHole._xscale * 0.5 * Cs.NEW_GEN_SCALE + p.ray) {
					p.mask.removeMovieClip();
					p.kill();
					blackHole.list.splice(i, 1);
					continue;
				}
			} else {
				flAllMasked = false;

				var a = p.getAng(bh);
				p.vx += Math.cos(a) * acc * Timer.tmod;
				p.vy += Math.sin(a) * acc * Timer.tmod;

				if (p.getDist(bh) < blackHole._xscale * 0.5 * Cs.NEW_GEN_SCALE - p.ray) {
					p.mask = Cs.game.dm.empty(Game.DP_BADS);
					p.mask.getGraphics().beginFill(0xFF0000, 1).drawCircle(0, 0, 50 * Cs.NEW_GEN_SCALE);
					p.mask._x = bh.x;
					p.mask._y = bh.y;
					p.mask._xscale = blackHole._xscale;
					p.mask._yscale = blackHole._yscale;
					p.root.mask = p.mask;
				}
			}
			i++;
		}
		// Log.setColor(0xFF0000)
		// trace(blackHole.step);
		switch (blackHole.step) {
			case 0 | 2:
				var ts = (blackHole.step == 0) ? 150 : 0;
				var ds = ts - blackHole._xscale;
				blackHole._xscale += ds * 0.3;
				if (Math.abs(ds) <= 1) {
					blackHole.step++;
					blackHole._xscale = ts;
				}
				blackHole._yscale = blackHole._xscale;

				for (i in 0...blackHole.list.length) {
					var p = blackHole.list[i];
					if (p.mask != null) {
						p.mask._xscale = blackHole._xscale;
						p.mask._yscale = blackHole._yscale;
					}
				}
			case 1:
				if (flAllMasked)
					blackHole.step = 2;
			case 3:
				if (blackHole.list.length == 0) {
					blackHole.removeMovieClip();
					blackHole = null;
				}
			case _:
		}
	}

	//
	public function newShot(a:Float, speed:Float, skin:Int) {
		a -= 1.57;
		var shot = new Shot(null);
		shot.setSkin(skin, 1);
		shot.a = a;
		shot.flGood = true;
		shot.x = x;
		shot.y = y - 20 * Cs.NEW_GEN_SCALE;
		shot.vx = Math.cos(a) * speed * Cs.NEW_GEN_SCALE;
		shot.vy = Math.sin(a) * speed * Cs.NEW_GEN_SCALE;

		return shot;
	}

	public function newMissile(a) {
		var shot = newShot(a, 4, 15);
		shot.root.stop();
		shot.y += 10 * Cs.NEW_GEN_SCALE;
		shot.ray = 8 * Cs.NEW_GEN_SCALE;
		shot.damage = 2;
		shot.speed = 4 * Cs.NEW_GEN_SCALE;
		shot.accel = {inc: 0.5 * Cs.NEW_GEN_SCALE, max: 16 * Cs.NEW_GEN_SCALE}
		shot.va = 0.2;
		shot.ca = 0.1;
		shot.orient();
		shot.queue = "mcQueueStandard";
		shot.bList.push(3);
		shot.timer = 120;
		return shot;
	}

	//
	public function hit(shot) {
		explode();
	}

	public function explode() {
		// PARTS
		for (i in 0...12) {
			var p = new Part(Cs.game.dm.attach("mcExploPart", Game.DP_PARTS));
			p.setScale(20 + Cs.rand() * 30);
			var a = Cs.rand() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var ray = 8 * Cs.NEW_GEN_SCALE;
			var sp = 6 + Cs.rand() * 6;
			p.x = x + ca * ray;
			p.y = y + sa * ray;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.plasmaId = 1;
			p.timer = 10 + Cs.rand() * 30;
			p.frict = 0.96;
			p.root.blendMode = BlendModes.ADD;
			p.root._rotation = Cs.rand() * 360;
			p.root.play();
		}
		// TRACE
		for (i in 0...6) {
			var mc = Cs.game.dm.attach("mcExploTrace", Game.DP_PARTS);
			mc._x = x + (Cs.rand() * 2 - 1) * ray;
			mc._y = y + (Cs.rand() * 2 - 1) * ray;
			mc._xscale = 150 + Cs.rand() * 150;
			mc._yscale = mc._xscale;
			mc._rotation = Cs.rand() * 360;
			mc.blendMode = BlendModes.ADD;
			mc.onFrame.set(3, function() {
				Cs.game.plasmaDraw(mc, 1);
				mc.removeMovieClip();
			});
			mc.gotoAndPlay(Cs.random(3) + 1);
		}
		// ONDE
		var mc = Cs.game.dm.attach("mcOnde", Game.DP_UNDERPARTS);
		mc._x = x;
		mc._y = y;
		mc._xscale = 150;
		mc._yscale = 150;
		mc.play();

		kill();
	}

	public override function kill() {
		// Cs.game.hero = cast {x: x, y: y};
		KadoKadeoManager.kkm.gameOver(Cs.game.stats);
		if (lastLaser != null) {
			lastLaser.removeMovieClip();
		}
		if (onde != null) {
			onde.removeMovieClip();
		}
		if (laserRay != null) {
			laserRay.removeMovieClip();
		}
		super.kill();
	}

	public function checkBounds() {
		var c = -0.3;
		if (x < ray || x > Cs.mcw - ray) {
			vx *= c;
			x = Num.mm(ray, x, Cs.mcw - ray);
		}
		if (y < ray || y > Cs.mch - ray) {
			vy *= c;
			y = Num.mm(ray, y, Cs.mch - ray);
		}
	}
}

// LE RAYON d'INVICIBILITE A ETE CORRIGE
// FREQUENCE DE TIR ORANGE DIMINUE
// DEGAT DU TIR ORANGE AUGMENTE
// FEQUENCE DE TIR BLEU ( MISSILES ) AUGMENTE DE 20%
// AUGMENTATION DE LA ZONE DE L AURA ROSE
