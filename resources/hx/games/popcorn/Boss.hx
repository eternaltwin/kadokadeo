package popcorn;

import mt.bumdum.Lib.Num;
import mt.Timer;

class Boss extends Phys {
	static var FR_END_STD = 29;
	static var FR_START_LAUNCH = 31;
	static var FR_END_LAUNCH = 56;

	static var LIFE = 7;
	static var MARGIN = KadoKadeoManager.I(60);

	var invert:Float;

	var launch:Float;
	var frame:Float;
	var speed:Float;
	var popTimer:Float;
	var dif:Float;
	var showTimer:Float;
	var startTimer:Float;

	var escCoef:Float;

	public var escLim:Float;
	public var escPop:Float;

	var sens:Int;

	public var step:Int;
	public var animFrame:Map<String, Int> = new Map();

	var life:Int;
	var lifeList:Array<ASprite>;

	var invertColorFilter = new pixi.filters.colormatrix.ColorMatrixFilter();

	public function new(mc:ASprite) {
		mc = Cs.game.dm.attach("mcBoss", Game.DP_DECOR);
		super(mc);
		animFrame.set("launch", 31);
		animFrame.set("hitt", 58);
		animFrame.set("die", 65);
		animFrame.set("hello", 83);
		mc.onFrame.set(62, function() {
			mc.gotoAndStop(animFrame.get("hitt"));
		});
		mc.onFrame.set(96, function() {
			mc.gotoAndPlay(88);
		});
		mc.stopOnFrame = [81];

		invertColorFilter.matrix = [
			-1,  0,  0, 0, 255,
			 0, -1,  0, 0, 255,
			 0,  0, -1, 0, 255,
			 0,  0,  0, 1,   0
		];

		frame = 0;
		sens = 1;
		speed = KadoKadeoManager.I(4);
		popTimer = 0;

		x = Cs.mcw * 0.5;
		y = Cs.HEIGHT - KadoKadeoManager.I(250);

		step = 0;
		dif = 0;

		escCoef = KadoKadeoManager.S(0.08); // 0.06;
		escLim = KadoKadeoManager.S(0.08);
		escPop = 0;

		startTimer = 100;

		initLife();
	}

	public function initLife():Void {
		life = LIFE;
		lifeList = new Array();
		for (i in 0...life) {
			var mc = Cs.game.gdm.attach("mcHeart", 6);
			mc._x = KadoKadeoManager.I(12) + i * KadoKadeoManager.I(16);
			mc._y = KadoKadeoManager.I(13);
			mc.stop();
			lifeList.push(mc);
		}
	}

	override public function update():Void {
		super.update();
		if (invert != null) {
			invert--;
			if (invert < 0) {
				Cs.game.map.filters = [];
				Cs.game.bg.filters = [];
				invert = null;
			}
		}

		switch (step) {
			case 0: // STANDARD;

				if (startTimer < 0) {
					frame = (frame + 3 * Timer.tmod) % FR_END_STD;
					root.gotoAndStop(Std.int(frame) + 1);
					checkPop();
				} else {
					startTimer -= Timer.tmod;
					if (startTimer < 50) {
						if (root._currentframe < FR_END_LAUNCH) {
							root.gotoAndPlay(animFrame.get("hello"));
						} else {
							root.play();
						}
					} else {
						frame = (frame + 3 * Timer.tmod) % FR_END_STD;
						root.gotoAndStop(Std.int(frame) + 1);
					}
				}

				move();
			case 1: // LAUNCH START;
				launch = Math.min(launch + 5 * Timer.tmod, FR_END_LAUNCH);
				if (launch == FR_END_LAUNCH) {
					step = 2;
					var sp = Cs.game.genPopcorn(x - KadoKadeoManager.I(44) * (100 / root._xscale), y - KadoKadeoManager.I(34));
					sp.vx = sens * Seed.rand() * KadoKadeoManager.I(6);
				}
				root.gotoAndStop(Std.int(launch) + 1);
				move();
			case 2: // LAUNCH END;
				launch = Math.max(launch - 5 * Timer.tmod, FR_START_LAUNCH);
				if (launch == FR_START_LAUNCH) {
					step = 0;
					root._xscale = (Seed.random(2) * 2 - 1) * 100;
				}
				root.gotoAndStop(Std.int(launch) + 1);
				move();
				checkPop();
			case 3: // HIT;
				root.play();
				//
				root._visible = !root._visible;
				showTimer -= Timer.tmod;
				if (showTimer < 0) {
					step = 0;
					root._visible = true;
				}
				x = Num.mm(MARGIN, x, Cs.mcw - MARGIN);
				vy -= KadoKadeoManager.S(0.1);
			// y = Math.min(Cs.game.hero.y-24, y)
			case 4: // END;
				if (root._currentframe < FR_END_LAUNCH)
					root.gotoAndPlay(animFrame.get("die"));
				vy += KadoKadeoManager.S(0.5);
				// vy *= Math.pow(0.95,Timer.tmod)

				// if( y > Cs.HEIGHT+100 )kill();
		}
		dif += Timer.tmod;
		escPop += 0.00003;
	}

	public function move():Void {
		// HORIZONTAL
		speed += KadoKadeoManager.S(0.003); // 0.001;
		var tvx = sens * speed;
		var dvx = tvx - vx;
		vx += dvx * 0.2 * Timer.tmod;

		if (x > Cs.mcw - MARGIN || x < MARGIN) {
			x = Num.mm(MARGIN, x, Cs.mcw - MARGIN);
			vx = 0;
			sens *= -1;
		}

		// VERTICAL
		var hy = Math.min(Cs.game.hero.y, Cs.game.ly);
		var ty = Math.max(hy - KadoKadeoManager.I(215), KadoKadeoManager.I(100));
		var dy = ty - y;
		var boost = dy * escCoef; // 0.06;
		var acc = Math.min(escLim, Math.abs(boost));
		vy += Num.mm(-acc, boost * Timer.tmod, acc);
	}

	public function checkPop():Void {
		popTimer -= Timer.tmod;
		while (popTimer <= 0) {
			var rnd = Math.max(12 - dif * 0.004, 3);

			if (Seed.rand() * rnd < 1) {
				step = 1;
				if (launch == null)
					launch = 0;
			}
			popTimer += 3;
		}
	};

	public function hit():Void {
		var piou = Cs.game.hero;

		var a = getAng({x: piou.x, y: piou.y});
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		vx -= ca * KadoKadeoManager.I(10);
		vy -= sa * KadoKadeoManager.I(10);
		piou.vx = ca * KadoKadeoManager.I(5);
		piou.vy = sa * KadoKadeoManager.I(5);

		// UPDATE LIFE
		life--;
		escCoef += KadoKadeoManager.S(0.02);
		escLim += KadoKadeoManager.S(0.03);
		for (i in 0...lifeList.length) {
			var mc = lifeList[i];
			var frame = 1;
			if (i >= life)
				frame = 2;
			mc.gotoAndStop(frame);
		}

		Cs.game.stats.e.push(2);
		Cs.game.stats.bhf.push(KadoKadeoManager.kkm.replay.getCurrentFrame());
		// S
		if (life > 0) {
			step = 3;
			launch = null;
			showTimer = 70;
			Cs.game.setScore(x, y, Cs.SCORE_HIT, 150);
			root.gotoAndStop(animFrame.get("hitt"));
			invert = 3;
			Cs.game.map.filters = [invertColorFilter];
			Cs.game.bg.filters = [invertColorFilter];
		} else {
			step = 4;
			Cs.game.setScore(x, y, Cs.SCORE_BOSS, 280);
			showTimer = 100;
			// var sc = SCORE_HIT
		}
	}
}
