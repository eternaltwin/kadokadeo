package elloninthedark;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchControlsMode;
import common_haxe_avm1.KeyboardManager;
import mt.DepthManager;
import pixi.core.graphics.Graphics;

typedef PlanInfo = {mc:ASprite, c:Float, flScroll:Bool, frame:Int};

@:expose('GameEllonInTheDark')
class Game implements kado.GameInterface {
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.JOYSTICK,
		joystick: {
			x: 0.18,
			y: 0.8,
			radius: 84,
			deadZone: 0.18,
			dynamicCenter: true,
		},
		buttons: [
			{
				id: "shoot",
				label: "✨",
				rightPx: 14,
				bottomPx: 14,
				size: 84,
				keyCode: KeyboardManager.SPACE,
			}
		],
	};

	// ZQSD / WASD move like the arrows, Enter shoots like Space and Control
	public static var KEY_ALIASES = KeyboardManager.ALIASES_MOVE.concat(KeyboardManager.ALIASES_ENTER_SPACE);

	public static var DP_INTER = 3;
	public static var DP_PLAN = 1;

	//
	public static var DP_PARTS = 10;
	public static var DP_SHOT = 7;
	public static var DP_HERO = 6;
	public static var DP_DRAW = 5;
	public static var DP_MONSTER = 4;
	public static var DP_BONUS = 3;
	public static var DP_UNDERPARTS = 2;

	//
	static var FORCE_BONUS = [1000, 6000, 12000];

	// "mcPlan" frames: parallax coefficient ((_height - mch) / MY in the original) and repeating plans
	static var PLAN_C = [0, 0.14625, 0.18125, 0.16, 0.235, 0.40125, 0.955, 2.4675, 2.7275, 3.02];
	static var PLAN_PERIODIC = [false, true, false, false, true, true, true, false, false, false];
	static var KANJI_RUN_POS = [-11.4, 256.95];
	static var KANJI_SIT_POS = [379.2, 327.25];

	//
	public var stats:{k:Array<Int>, b:Array<Int>, d:Null<Float>};

	public var dif:Float;
	public var monsterLevel:Float;
	public var phaseTimer:Float;

	var planList:Array<PlanInfo>;

	public var sList:Array<Sprite>;
	public var pList:Array<Part>;
	public var badsList:Array<Bads>;

	public var dm:DepthManager;
	public var mdm:DepthManager;

	public var hero:Hero;

	public var root:ASprite;

	var map:ASprite;
	var draw:ASprite;

	public var drawing:Graphics;

	var forceBonus:Array<Int>;

	// state of the decor timeline scripts (init() of the mcPlan frames)
	var craneDone:Bool;
	var craneNotFirst:Bool;
	var kanjiWasHere:Bool;
	var kanjiRunDone:Bool;
	var kanjiRun:ASprite;
	var kanjiRunFrame:Int;
	var kanjiSit:ASprite;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(6);
		replayKeys[0] = KeyboardManager.UP;
		replayKeys[1] = KeyboardManager.DOWN;
		replayKeys[2] = KeyboardManager.LEFT;
		replayKeys[3] = KeyboardManager.RIGHT;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.CONTROL;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		Cs.game = this;
		Cs.bact = 0;
		dm = new DepthManager(root);
		this.root = root;

		sList = new Array();
		pList = new Array();
		badsList = new Array();
		forceBonus = FORCE_BONUS.copy();

		craneDone = false;
		craneNotFirst = false;
		kanjiWasHere = false;
		kanjiRunDone = false;
		kanjiRunFrame = 0;

		initPlans();

		hero = new Hero(mdm.empty(DP_HERO));
		hero.x = KadoKadeoManager.I(150);
		hero.y = KadoKadeoManager.I(150);

		draw = mdm.empty(DP_DRAW);
		drawing = draw.getGraphics();

		dif = 0;
		phaseTimer = 0;
		monsterLevel = 0;
		//
		stats = {
			k: [for (i in 0...23) 0],
			b: [],
			d: null
		};
	}

	function initPlans() {
		planList = new Array();
		for (i in 0...PLAN_C.length) {
			var mc = createPlan(i + 1);
			var c = PLAN_C[i];
			if (c > 1 && map == null) {
				map = dm.empty(DP_PLAN);
				mdm = new DepthManager(map);
				planList.push({
					mc: map,
					c: 1,
					flScroll: false,
					frame: 0
				});
				dm.over(mc);
			}
			if (i > 0)
				mc._x = -KadoKadeoManager.I(1500);
			planList.push({
				mc: mc,
				c: c,
				flScroll: true,
				frame: i + 1
			});
		}
	}

	function createPlan(f:Int):ASprite {
		var mc = dm.empty(DP_PLAN);
		mc.attachMovie("plan" + f, "plan", 1);
		if (PLAN_PERIODIC[f - 1]) {
			// one period (300px) is stored, the original 600px wide drawing repeats it
			var p = mc.attachMovie("plan" + f, "plan2", 2);
			p._x = Cs.mcw * 2;
		}
		switch (f) {
			case 5:
				kanjiRun = mc.attachMovie("kanjiRun", "kanji", 3);
				kanjiRun.loop = true;
				kanjiRun._visible = false;
			case 9:
				kanjiSit = mc.attachMovie("kanjiSit", "kanji", 3);
				kanjiSit._x = KadoKadeoManager.S(KANJI_SIT_POS[0]);
				kanjiSit._y = KadoKadeoManager.S(KANJI_SIT_POS[1]);
				kanjiSit._visible = false;
			case _:
		}
		return mc;
	}

	// init() functions of the mcPlan frames, called each time a plan loops
	function initPlan(info:PlanInfo) {
		var mc = info.mc;
		switch (info.frame) {
			case 3:
				if (Seed.randomVfx(8) == 0 && !craneDone && craneNotFirst) {
					mc._visible = true;
					craneDone = true;
				} else {
					mc._visible = false;
				}
				craneNotFirst = true;
			case 4:
				mc._visible = Seed.randomVfx(8) == 0;
			case 5:
				if (!kanjiRunDone && kanjiWasHere) {
					kanjiRun._visible = true;
					kanjiRun.play();
					kanjiRunFrame = 1;
					kanjiRunDone = true;
				} else {
					kanjiRun._visible = false;
					kanjiRun.stop();
					kanjiRunFrame = 0;
				}
			case 8:
				mc._visible = Seed.randomVfx(10) == 0;
			case 9:
				if (Seed.randomVfx(10) == 0) {
					mc._visible = true;
					if (!kanjiWasHere && Seed.randomVfx(30) == 0) {
						kanjiSit._visible = true;
						kanjiWasHere = true;
					} else {
						kanjiSit._visible = false;
					}
				} else {
					mc._visible = false;
				}
			case 10:
				mc._visible = Seed.randomVfx(25) == 0;
			case _:
		}
	}

	// timeline of the kanji clip (plan 5): runs along its path then stop()
	function updateKanji() {
		if (kanjiRunFrame <= 0)
			return;
		var p = Data.KANJI_PATH[kanjiRunFrame - 1];
		kanjiRun._x = KadoKadeoManager.S(KANJI_RUN_POS[0] + p[0]);
		kanjiRun._y = KadoKadeoManager.S(KANJI_RUN_POS[1] + p[1]);
		kanjiRun._xscale = p[2] * 100;
		kanjiRun._yscale = p[3] * 100;
		if (kanjiRunFrame < Data.KANJI_PATH.length)
			kanjiRunFrame++;
	}

	public function update(delta:Float) {
		drawing.clear();
		updateScroll();
		updateKanji();

		// SPRITE
		var list = sList.copy();
		for (i in 0...list.length) {
			list[i].update();
		}

		// DIF
		dif += Timer.tmod * 6;
		var lim = Math.pow(dif * 0.005, 0.65);
		while (monsterLevel < lim) {
			newWave();
		}
	}

	function updateScroll() {
		for (i in 0...planList.length) {
			var info = planList[i];
			var y = -((hero.ray + hero.y) / (Cs.GL - 2 * hero.ray)) * (Cs.MY * info.c);
			var ty = Math.min(Math.max(-Cs.MY * info.c, y), 0);
			if (info.flScroll) {
				info.mc._x -= info.c * Cs.SCROLL_SPEED * Timer.tmod;
				if (info.mc._x < -Cs.mcw * 2) {
					info.mc._x += Cs.mcw * 2;
					// no interpolation across the loop
					if (info.mc._prevState != null)
						info.mc._prevState.x += Cs.mcw * 2;
					initPlan(info);
				}
			}
			info.mc._y = ty;
		}
	}

	// GEN
	function newWave() {
		// CARRIER
		if (Seed.random(16) == 0 || (forceBonus.length > 0 && dif > forceBonus[0])) {
			genWave(7);
			return;
		}
		// MEDUSA
		if (dif > 24000 && Seed.random(3) == 0) {
			genWave(9);
			return;
		}

		// GOLGOTH
		if (dif > 16000 && Seed.random(5) == 0) {
			genWave(6);
			return;
		}

		// FROG
		if (dif > 12000 && Seed.random(7) == 0) {
			genWave(5);
			return;
		}

		// DRAGON
		if (dif > 10000 && Seed.random(10) == 0) {
			genWave(4);
			return;
		}

		// BACTERY
		if (dif > 10000 && Seed.random(5) == 0) {
			genWave(8);
			return;
		}

		// RUNNER
		if (dif > 8000 && Seed.random(4) == 0) {
			genWave(3);
			return;
		}

		// ONDULATORS
		if (dif > 6000 && Seed.random(4) == 0) {
			genWave(2);
			return;
		}

		// LEADER WAVE
		if (dif > 4000 && Seed.random(4) == 0) {
			genWave(1);
			return;
		}
		// BASE WAVE
		genWave(0);
	}

	function genWave(id:Int) {
		switch (id) {
			case 0:
				var wave = new Wave(null);
				for (i in 0...8) {
					var b = new Drone(mdm.attach("mcBat1", DP_MONSTER));
					wave.addBads(b);
					b.root.gotoAndPlay(i + 1);
				}
			case 1:
				var wave = new Wave(null);
				for (i in 0...8) {
					var b = new Drone(mdm.attach(i == 0 ? "mcBat2" : "mcBat1", DP_MONSTER));
					if (i == 0)
						b.setLeader();
					wave.addBads(b);
				}
			case 2:
				var m = KadoKadeoManager.I(30);
				var trg = {x: 0.0, y: m + Seed.rand() * (Cs.mch - 2 * m)};
				for (i in 0...8) {
					var b = new Drone(mdm.attach("mcOndulator", DP_MONSTER));
					b.trg = trg;
					b.decal = i * 50;
					b.x = Cs.mcw + KadoKadeoManager.I(40) + i * (b.ray + KadoKadeoManager.I(20));
					b.vx = -KadoKadeoManager.S(1.5);
					b.setSens(-1);
					b.bList.push(2);
					b.setOndulator();
				}
			case 3:
				new Runner(mdm.empty(DP_MONSTER));
			case 4:
				var leader:Dragon = null;
				for (i in 0...12) {
					var b = new Dragon(mdm.empty(DP_MONSTER));
					if (i == 0) {
						b.x = Cs.mcw + KadoKadeoManager.I(20);
						b.y = Seed.rand() * Cs.GL;
						b.setLeader();
						leader = b;
					} else {
						b.leader = leader;
						b.x = leader.x;
						b.y = leader.y;
						leader.qList.push(b);
					}
				}
				mdm.over(leader.root);
			case 5:
				new Frog(mdm.empty(DP_MONSTER));
			case 6:
				new Golgoth(mdm.empty(DP_MONSTER));
			case 7:
				if (forceBonus.length > 0 && dif > forceBonus[0])
					forceBonus.shift();
				new Carrier(mdm.attach("mcCarrier", DP_MONSTER));
			case 8:
				new Bactery(mdm.attach("mcBactery", DP_MONSTER));
			case 9:
				new Medusa(mdm.attach("mcMedusa", DP_MONSTER));
		}
	}

	//
	public function spawnScore(x:Float, y:Float, score:Int) {
		new ScorePopup(x, y, score);
	}

	// TOUCH: joystick -> arrow keys (polled and recorded like the keyboard)
	public function pollTouchControls():Void {
		var joystick = KadoKadeoManager.kkm.getTouchJoystickState();
		if (joystick == null) {
			return;
		}

		// 8 directions snapped by the joystick (with hysteresis: no flicker between two directions)
		var axisX = joystick.active ? joystick.dirX : 0;
		var axisY = joystick.active ? joystick.dirY : 0;

		setDirectionalKey(KeyboardManager.LEFT, axisX < 0);
		setDirectionalKey(KeyboardManager.RIGHT, axisX > 0);
		setDirectionalKey(KeyboardManager.UP, axisY < 0);
		setDirectionalKey(KeyboardManager.DOWN, axisY > 0);
	}

	inline function setDirectionalKey(keyCode:Int, down:Bool):Void {
		if (down) {
			KeyboardManager.setKeyDown(keyCode);
		} else {
			KeyboardManager.setKeyUp(keyCode);
		}
	}

	public function destroy():Void {
		Cs.bact = 0;
		Cs.game = null;
	}
}
