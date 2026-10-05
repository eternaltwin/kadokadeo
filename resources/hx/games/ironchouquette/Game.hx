package ironchouquette;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchControlsMode;
import ironchouquette.elems.Base2;
import ironchouquette.elems.Base1;
import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.core.math.Matrix;
import pixi.core.Pixi.BlendModes;
import common_haxe_avm1.KeyboardManager;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;

class ShotLayerSprite extends ASprite {
	public var dm:DepthManager;
}

class ShotsSprite extends ASprite {
	public var layer:Array<ShotLayerSprite>;
}

@:expose('GameIronChouquette')
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
				label: "☄️",
				rightPx: 14,
				bottomPx: 14,
				size: 84,
				keyCode: KeyboardManager.SPACE,
			},
			{
				id: "sacrifice",
				label: "💀",
				rightPx: 22,
				bottomPx: 112,
				size: 70,
				action: TOUCH_ACTION_SACRIFICE,
			}
		],
	};

	static inline var TOUCH_ACTION_SACRIFICE = "touch_sacrifice";

	public static var DP_INTER = 12;
	public static var DP_PARTS = 10;
	public static var DP_SHOTS = 8;
	public static var DP_HERO = 9;
	public static var DP_BADS = 7;
	public static var DP_DRAW = 5;
	public static var DP_UNDERPARTS = 3;
	public static var DP_BG = 2;

	public static var SCROLL_SPEED = KadoKadeoManager.S(0.0001); // 5//10;
	public static var SCROLL_SPEED_MAX = KadoKadeoManager.S(6); // 5//10;
	public static var PLASMA_CACHE = KadoKadeoManager.S(100);
	// ColorTransform of the plasma layers at each step (multipliers, offsets 0..255), like the original
	static var PLASMA_MULT = [[1.0, 1, 1, 1], [0.95, 0.8, 0.8, 1]];
	static var PLASMA_OFF = [[-2.0, -2, -2, 0], [-10.0, -20, -20, -10]];

	public static var PM = 1;

	//
	public var stats:{
		k:Array<Array<Int>>, // kills (score)
		b:Array<Array<Int>>, // bonuses (and sacrifices)
		spk:Array<Int>, // special kills ([weapon0KillCount, weapon1KillCount, ...])
		sak:Array<Array<Array<Int>>>, // sacrifices kills per sacrifice per use
		/*
			(
				[
					[
						[sacrifice0KillCount1, sacrifice0ProjectileCount1],
						[sacrifice0KillCount2, sacrifice0ProjectileCount2],
					],
					[
						[sacrifice0KillCount1, sacrifice0ProjectileCount1],
						[sacrifice0KillCount2, sacrifice0ProjectileCount2],
					],
				]
			)
		 */
		mesc:Int, // max ennemy shot count (on screen)
		w:Array<Int>, // waves
	};

	public var gfxMode:Int;
	public var step:Int;
	public var lagTimer:Float;
	public var timer:Float;
	public var flashouille:Float;
	public var pq:Float;

	public var pList:Array<Part>;
	public var shotList:Array<Shot>;
	public var badsList:Array<Bads>;
	public var bonusList:Array<Bonus>;

	public var dm:DepthManager;
	public var hero:Hero;

	public var root:ASprite;
	public var bg:ASprite;
	public var shots:ShotsSprite;
	public var plasma:ASprite;
	public var plasmaLayers:Array<PlasmaLayer>;
	public var speedField:SpeedField;

	var plasmaMatrix = new Matrix();

	public var baseList:Array<ASprite>;

	public var bt:{trg:Float, timer:Float, val:Float};

	public var prevKeys:Map<Int, Bool>;

	public var knTurnRay:Float;
	public var knTurnDecal:Float;
	public var knTurnSpeed:Float;
	public var kidnappers:Array<Phys>;
	public var chouquette:Phys;
	public var frameId:Int;

	var pendingVirtualKeyUps:Array<{keyCode:Int, framesLeft:Int}>;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(14);
		replayKeys[0] = KeyboardManager.ARROW_RIGHT;
		replayKeys[1] = KeyboardManager.ARROW_DOWN;
		replayKeys[2] = KeyboardManager.ARROW_LEFT;
		replayKeys[3] = KeyboardManager.ARROW_UP;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.CONTROL;
		replayKeys[6] = KeyboardManager.SHIFT;
		replayKeys[7] = KeyboardManager.W;
		replayKeys[8] = KeyboardManager.Z;
		replayKeys[9] = KeyboardManager.A;
		replayKeys[10] = KeyboardManager.Q;
		replayKeys[11] = KeyboardManager.S;
		replayKeys[12] = KeyboardManager.D;
		replayKeys[13] = KeyboardManager.ENTER;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		Cs.game = this;
		dm = new DepthManager(root);
		this.root = root;

		pList = new Array();
		shotList = new Array();
		badsList = new Array();
		bonusList = new Array();
		frameId = 0;
		pendingVirtualKeyUps = [];

		bg = dm.attach("mcBg", DP_BG);

		lagTimer = 0;
		gfxMode = 4;

		stats = {
			k: [],
			b: [],
			spk: [0, 0, 0, 0, 0, 0],
			sak: [[], [], [], [], [], []],
			mesc: 0,
			w: [],
		};

		initStep(0);
		initKeyListener();
	}

	public function initStep(n:Int) {
		step = n;
		switch (n) {
			case 0:
				// CHOUQUETTE
				chouquette = new Phys(dm.attach("mcChouquette", DP_BADS));
				chouquette.x = Cs.mcw * 0.5 - KadoKadeoManager.I(5);
				chouquette.y = Cs.mch + KadoKadeoManager.I(10);
				chouquette.frict = 0.92;
				chouquette.root.loop = true;
				chouquette.root.play();
				untyped chouquette.zap = chouquette.root.attachMovie("mcChouquetteZap", "zap");
				untyped chouquette.zap.loop = true;
				untyped chouquette.zap.play();

				// KIDNAPPERS
				knTurnRay = KadoKadeoManager.I(10);
				knTurnDecal = 0;
				knTurnSpeed = 0;
				kidnappers = new Array();
				for (i in 0...3) {
					var sp = new Phys(dm.attach("mcKidnapper", DP_BADS));
					kidnappers.push(sp);
					sp.x = -KadoKadeoManager.I(100);
					sp.y = -KadoKadeoManager.I(100);
					sp.updatePos();
				}

				// BASE
				var pl = dm.attach("mcPlanet", DP_BG);
				pl._x = Cs.mcw;
				pl._y = KadoKadeoManager.I(160);
				baseList = [pl, new Base2(dm.empty(DP_BG)), new Base1(dm.empty(DP_PARTS))];

				// plasma pixel = 4 pixels of the game (2 of the original 300x300 game: its pq was 0.5)
				pq = 0.25;
				initPlasma();
				initShots();
			// initStep(1)
			case 1:
				hero = new Hero(dm.attach("mcHero", DP_HERO));
			case _:
		}
	}

	function updateMaxEnemyShotCount() {
		var count = 0;
		for (shot in shotList) {
			if (shot.flGood != true)
				count++;
		}
		if (count > stats.mesc) {
			stats.mesc = count;
		}
	}

	//
	public function update(delta:Float) {
		frameId++;
		updateKeyboard();
		flushPendingVirtualKeyUps();

		if (bt != null)
			updateBulletTime();
		updateFlash();
		updatePlasma();
		updateMaxEnemyShotCount();

		mt.bumdum.Sprite.updateAll();

		// trace({
		// 	pList: pList.length,
		// 	shotList: shotList.length,
		// 	badsList: badsList.length,
		// 	bonusList: bonusList.length
		// });

		//
		switch (step) {
			case 0:
				if (chouquette.y > Cs.mch * 0.5) {
					chouquette.vy -= KadoKadeoManager.S(0.3) * Timer.tmod;
				} else {
					initStep(1);
				}
				knTurnRay += KadoKadeoManager.S(0.35) * Timer.tmod;
				updateKidnappers();
				timer = 60;
			case 1:
				knTurnSpeed += 0.15 * Timer.tmod;
				if (timer > 0) {
					timer -= Timer.tmod;
				} else {
					chouquette.vy -= KadoKadeoManager.S(0.8) * Timer.tmod;
					if (chouquette.y < -KadoKadeoManager.I(100)) {
						while (kidnappers.length > 0)
							kidnappers.pop().kill();
						chouquette.kill();
						initStep(2);
					}
				}
				updateKidnappers();
				Stykades.update();
			case 2: // PLAY
				Stykades.update();
			case _:
		}

		// BG
		if (SCROLL_SPEED > 0)
			updateScroll();

		// GFXMODE
		updateGfxMode();

		flushPlasma();
	}

	public function updateKidnappers() {
		for (i in 0...kidnappers.length) {
			var k = kidnappers[i];
			var c = i / kidnappers.length;

			knTurnDecal = (knTurnDecal + knTurnSpeed * Timer.tmod) % 628;

			k.x = chouquette.x + Math.cos(knTurnDecal * 0.01 + c * 6.28) * knTurnRay;
			k.y = chouquette.y + Math.sin(knTurnDecal * 0.01 + c * 6.28) * knTurnRay;
		}
	}

	public function updateGfxMode() {
		if (lagTimer > 0) {
			lagTimer -= Timer.tmod;
		} else {
			lagTimer += Timer.tmod;
		}
	}

	//
	public function updateBulletTime() {
		var dif = bt.trg - bt.val;
		bt.val += dif * 0.1;
		if (Math.abs(dif) < 0.1)
			bt.val = bt.trg;
		Timer.tmod = bt.val;
		if (bt.timer-- <= 0)
			bt.trg = 1;
		if (bt.val == 1) {
			bt = null;
			bg.filters = [];
		} else {
			var fl:ColorMatrixFilter = cast Reflect.field(bg, "__percentColorFilter");
			if (fl == null) {
				fl = new ColorMatrixFilter();
				Reflect.setField(bg, "__percentColorFilter", fl);
			}
			// if(Cs.game.root.filters.length>0)return;
			var c = 1 - bt.val;
			var sat = 0.3;
			var inc = Seed.randVfx() * 15;
			fl.matrix = [
				1 + c * sat,           0,           0, 0, (inc + 200 * c) / 255,
				          0, 1 + c * sat,           0, 0,  (inc - 50 * c) / 255,
				          0,           0, 1 + c * sat, 0,  (inc - 50 * c) / 255,
				          0,           0,           0, 1,                     0
			];
			bg.filters = [fl];
		}
	}

	public function updateFlash() {
		if (flashouille != null) {
			var prc = Math.min(flashouille, 100);
			flashouille *= 0.6;
			if (flashouille < 2) {
				flashouille = null;
				prc = 0;
			}
			Col.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	// SHOTS
	public function initShots() {
		shots = cast dm.empty(DP_SHOTS);
		shots.layer = new Array();
		var dm = new DepthManager(shots);
		for (i in 0...3) {
			var mc:ShotLayerSprite = cast dm.empty(0);
			mc.dm = new DepthManager(mc);
			shots.layer.push(mc);
		}
	}

	// PLASMA
	// Two small bitmaps (game size * pq, plus PLASMA_CACHE above the screen) shown scaled up behind the game: things are
	// stamped into them (plasmaDraw) and they are blurred, faded and scrolled at every step. See PlasmaLayer.
	public function initPlasma() {
		plasma = dm.empty(DP_BG);
		plasmaLayers = [];
		var w = Std.int(Cs.mcw * pq);
		var h = Std.int((Cs.mch + PLASMA_CACHE) * pq);
		for (i in 0...2) {
			var layer = new PlasmaLayer(w, h, plasmaBlur(i, 1), i == 0);
			layer.view.y = -PLASMA_CACHE * pq;
			plasma.addChild(layer.view);
			plasmaLayers.push(layer);
		}
		plasma._xscale = 100 / pq;
		plasma._yscale = 100 / pq;
		speedField = new SpeedField(w, h);
	}

	// blur of the original (BlurFilter, in pixels of the bitmap), its pq being twice ours
	function plasmaBlur(i:Int, tmod:Float):Float {
		return i == 0 ? Math.max(4 * pq * tmod, 1.5) : Math.max(20 * pq * tmod, 1);
	}

	public function updatePlasma() {
		plasmaDraw(shots.layer[0], 0);

		var scroll = SCROLL_SPEED > 0.2 ? Std.int(SCROLL_SPEED * 3 * pq) : 0;
		for (i in 0...plasmaLayers.length)
			if (plasmaLayers[i] != null)
				plasmaLayers[i].step(plasmaBlur(i, Timer.tmod), PLASMA_MULT[i], PLASMA_OFF[i], scroll);

		speedField.step(hero != null && hero.weapons[Hero.WP_SPEED][0] > 0, plasmaBlur(0, Timer.tmod), scroll);
	}

	// the stamps of the step, drawn in the layers before the picture is shown
	function flushPlasma() {
		for (layer in plasmaLayers)
			if (layer != null)
				layer.flush();
	}

	public function plasmaDraw(mc:ASprite, n:Int) {
		var layer = plasmaLayers[n];
		if (layer == null || mc == null)
			return;
		var m = plasmaMatrix;
		m.identity();
		m.scale((mc._xscale / 100) * pq, (mc._yscale / 100) * pq);
		m.rotate(mc._rotation * 0.0174);
		m.translate((mc._x) * pq, (mc._y + PLASMA_CACHE) * pq);
		// BitmapData.draw(mc, m, ColorTransform(alpha offset -255 + _alpha * 2.55), mc.blendMode)
		layer.draw(mc, m, mc._alpha / 100, mc.blendMode);
		if (n == 0)
			speedField.draw(mc, m, mc._alpha / 100);
	}

	public function setPq(n) {
		pq = n;
		destroyPlasma();
		initPlasma();
	}

	function destroyPlasma() {
		if (plasmaLayers != null)
			for (layer in plasmaLayers)
				if (layer != null)
					layer.destroy();
		plasmaLayers = null;
		if (plasma != null)
			plasma.removeMovieClip();
		plasma = null;
	}

	// SCROLL
	public function updateScroll() {
		if (gfxMode < 3) {
			SCROLL_SPEED *= 0.95;
			if (SCROLL_SPEED < KadoKadeoManager.S(0.5))
				SCROLL_SPEED = 0;
		} else {
			if (step > 1) {
				SCROLL_SPEED = Math.min(SCROLL_SPEED + KadoKadeoManager.S(0.01) * Timer.tmod, SCROLL_SPEED_MAX);
			}
		}

		bg._y += SCROLL_SPEED;
		if (bg._y > 0) {
			// bg._y -= 1800 * Cs.NEW_GEN_SCALE;
			bg._y -= KadoKadeoManager.I(900);
			bg._prevState.y = bg._y - SCROLL_SPEED; // Hack to avoid weird scroll (interpolation) when the bg is repositionned
		}

		var i = 0;
		while (i < baseList.length) {
			var b = baseList[i];
			if (b._y == 0)
				b._y = Cs.mch;
			b._y += SCROLL_SPEED;
			if (b._y > Cs.mch + KadoKadeoManager.I(100)) {
				b.removeMovieClip();
				baseList.splice(i, 1);
				continue;
			}
			i++;
		}
	}

	// KEY
	public function initKeyListener() {
		prevKeys = new Map();
	}

	public function isKeyJustPressed(code:Int):Bool {
		var down = KeyboardManager.isDown(code);
		var wasDown = prevKeys.exists(code) ? prevKeys.get(code) : false;
		prevKeys.set(code, down);
		return down && !wasDown;
	}

	public function updateKeyboard() {
		if (hero == null)
			return;

		#if debug
		for (n in 96...107) {
			if (isKeyJustPressed(n))
				hero.addWeapon(n - 96);
		}
		for (n in 49...54) {
			if (isKeyJustPressed(n)) {
				hero.addBox();
			}
		}
		for (n in 54...59) {
			if (isKeyJustPressed(n)) {
				var bonus = new Bonus(null);
				bonus.x = Seed.rand() * Cs.mcw;
				bonus.y = -bonus.ray;
			}
		}
		#end

		if (isKeyJustPressed(KeyboardManager.CONTROL) || isKeyJustPressed(KeyboardManager.SHIFT)) {
			hero.sacrifice(null);
		}
	}

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

	public function onTouchAction(action:String):Void {
		switch (action) {
			case TOUCH_ACTION_SACRIFICE:
				queueVirtualTap(KeyboardManager.CONTROL);
			case _:
		}
	}

	function queueVirtualTap(keyCode:Int):Void {
		KeyboardManager.setKeyDown(keyCode);
		pendingVirtualKeyUps.push({
			keyCode: keyCode,
			framesLeft: 2
		});
	}

	function flushPendingVirtualKeyUps():Void {
		if (pendingVirtualKeyUps.length == 0) {
			return;
		}

		var keep:Array<{keyCode:Int, framesLeft:Int}> = [];
		for (entry in pendingVirtualKeyUps) {
			entry.framesLeft--;
			if (entry.framesLeft <= 0) {
				KeyboardManager.setKeyUp(entry.keyCode);
			} else {
				keep.push(entry);
			}
		}
		pendingVirtualKeyUps = keep;
	}

	public function destroy():Void {
		SCROLL_SPEED = KadoKadeoManager.S(0.0001);
		Stykades.monsterLevel = 0;
		Stykades.waveTimer = 150;
		Stykades.nextWave = 300;
		Stykades.dif = 0;
		Stykades.nextBonus = 300;
		Stykades.FL_CREATE_LOCK = false;
		Bonus.NB = 0;

		destroyPlasma();
		if (bg != null)
			bg.filters = [];
		if (root != null)
			Col.setPercentColor(root, 0, 0xFFFFFF);

		Cs.game = null;
	}
}
