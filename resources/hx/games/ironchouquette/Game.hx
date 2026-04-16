package ironchouquette;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchControlsMode;
import ironchouquette.elems.Base2;
import ironchouquette.elems.Base1;
import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.core.textures.RenderTexture;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite;
import pixi.core.Pixi.BlendModes;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.PixelHelper;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;

class ShotLayerSprite extends ASprite {
	public var dm:DepthManager;
}

class ShotsSprite extends ASprite {
	public var layer:Array<ShotLayerSprite>;
}

class PlasmaLayerSprite extends ASprite {
	public var bmp:RenderTexture;
	public var backBmp:RenderTexture;
	public var view:Sprite;
	public var blit:Sprite;
}

class PlasmaSprite extends ASprite {
	public var layer:Array<PlasmaLayerSprite>;
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

	static inline var JOYSTICK_DIGITAL_THRESHOLD = 0.2;
	static inline var TOUCH_ACTION_SACRIFICE = "touch_sacrifice";

	public static var DP_INTER = 12;
	public static var DP_PARTS = 10;
	public static var DP_SHOTS = 8;
	public static var DP_HERO = 9;
	public static var DP_BADS = 7;
	public static var DP_DRAW = 5;
	public static var DP_UNDERPARTS = 3;
	public static var DP_BG = 2;

	public static var SCROLL_SPEED = 0.0001 * Cs.NEW_GEN_SCALE; // 5//10;
	public static var SCROLL_SPEED_MAX = 6 * Cs.NEW_GEN_SCALE; // 5//10;
	public static var PLASMA_CACHE = 100 * Cs.NEW_GEN_SCALE;

	public static var PM = 1;

	//
	public var stats:{
		k:Array<Array<Int>>,
		b:Array<Array<Int>>
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
	public var plasma:PlasmaSprite;

	public var baseList:Array<ASprite>;

	public var bt:{trg:Float, timer:Float, val:Float};

	public var prevKeys:Map<Int, Bool>;

	public var knTurnRay:Float;
	public var knTurnDecal:Float;
	public var knTurnSpeed:Float;
	public var kidnappers:Array<Phys>;
	public var chouquette:Phys;
	public var frameId:Int;
	public var plasmaSample:PixelHelper;
	public var plasmaSampleRate:Int;

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
		plasmaSampleRate = 3;
		pendingVirtualKeyUps = [];

		bg = dm.attach("mcBg", DP_BG);

		lagTimer = 0;
		gfxMode = 4;

		stats = {
			k: [],
			b: []
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
				chouquette.x = Cs.mcw * 0.5 - 5 * Cs.NEW_GEN_SCALE;
				chouquette.y = Cs.mch + 10 * Cs.NEW_GEN_SCALE;
				chouquette.frict = 0.92;
				chouquette.root.loop = true;
				chouquette.root.play();
				untyped chouquette.zap = chouquette.root.attachMovie("mcChouquetteZap", "zap");
				untyped chouquette.zap.loop = true;
				untyped chouquette.zap.play();

				// KIDNAPPERS
				knTurnRay = 10 * Cs.NEW_GEN_SCALE;
				knTurnDecal = 0;
				knTurnSpeed = 0;
				kidnappers = new Array();
				for (i in 0...3) {
					var sp = new Phys(dm.attach("mcKidnapper", DP_BADS));
					kidnappers.push(sp);
					sp.x = -100 * Cs.NEW_GEN_SCALE;
					sp.y = -100 * Cs.NEW_GEN_SCALE;
					sp.updatePos();
				}

				// BASE
				var pl = dm.attach("mcPlanet", DP_BG);
				pl._x = Cs.mcw;
				pl._y = 160 * Cs.NEW_GEN_SCALE;
				baseList = [pl, new Base2(dm.empty(DP_BG)), new Base1(dm.empty(DP_PARTS))];

				//
				pq = 0.5;
				initPlasma();
				initShots();
			// initStep(1)
			case 1:
				hero = new Hero(dm.attach("mcHero", DP_HERO));
			case _:
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

		// SPRITE
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
					chouquette.vy -= 0.3 * Cs.NEW_GEN_SCALE * Timer.tmod;
				} else {
					initStep(1);
				}
				knTurnRay += 0.35 * Cs.NEW_GEN_SCALE * Timer.tmod;
				updateKidnappers();
				timer = 60;
			case 1:
				knTurnSpeed += 0.15 * Timer.tmod;
				if (timer > 0) {
					timer -= Timer.tmod;
				} else {
					chouquette.vy -= 0.8 * Cs.NEW_GEN_SCALE * Timer.tmod;
					if (chouquette.y < -100 * Cs.NEW_GEN_SCALE) {
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
			var inc = Cs.rand() * 15;
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
	public function initPlasma() {
		plasma = cast dm.empty(DP_BG);
		plasma.layer = new Array();
		var dm = new DepthManager(plasma);
		for (i in 0...2) {
			var mc:PlasmaLayerSprite = cast dm.empty(0);
			mc.bmp = RenderTexture.create(Std.int(Cs.mcw * pq), Std.int((Cs.mch + PLASMA_CACHE) * pq));
			mc.backBmp = RenderTexture.create(Std.int(Cs.mcw * pq), Std.int((Cs.mch + PLASMA_CACHE) * pq));
			mc.view = mc.attachBitmap(mc.bmp, 0);
			mc.blit = new Sprite(mc.bmp);
			mc.blit.blendMode = BlendModes.NORMAL;
			plasma.layer.push(mc);
			mc._y = -PLASMA_CACHE * pq;

			if (i == 0)
				mc.blendMode = BlendModes.ADD;
			// if(i==1)mc.blendMode = BlendModes.OVERLAY;
		}
		plasma._xscale = 100 / pq;
		plasma._yscale = 100 / pq;
	}

	public function updatePlasma() {
		plasmaDraw(shots.layer[0], 0);

		for (i in 0...plasma.layer.length) {
			if (plasma.layer[i] != null) {
				var layer = plasma.layer[i];
				var src = layer.bmp;
				var dst = layer.backBmp;
				switch (i) {
					case 0:
						var blp = Math.max(2 * pq * Timer.tmod, 1.5);
						processPlasmaLayer(layer, src, dst, blp, 0xFFFFFF, 0.985);
					case 1:
						var blp = Math.max(10 * pq * Timer.tmod, 1);
						processPlasmaLayer(layer, src, dst, blp, 0xF2CCCC, 0.92);

					case _:
				}
			}
		}

		if (plasma.layer[0] != null && frameId % plasmaSampleRate == 0) {
			plasmaSample = PixelHelper.extract(plasma.layer[0].bmp);
		}
	}

	function processPlasmaLayer(layer:PlasmaLayerSprite, src:RenderTexture, dst:RenderTexture, blur:Float, tint:Int, decayAlpha:Float):Void {
		if (layer.blit == null)
			layer.blit = new Sprite(src);
		layer.blit.texture = src;
		layer.blit.tint = tint;

		var scrollY = SCROLL_SPEED > 0.2 ? Std.int(SCROLL_SPEED * 3 * pq) : 0;
		var r = Math.max(1, Std.int(blur));

		layer.blit.alpha = decayAlpha * 0.40;
		var m = new Matrix();
		m.translate(0, scrollY);
		renderToTexture(layer.blit, dst, m, true);

		layer.blit.alpha = decayAlpha * 0.15;
		m = new Matrix();
		m.translate(r, scrollY);
		renderToTexture(layer.blit, dst, m, false);

		m = new Matrix();
		m.translate(-r, scrollY);
		renderToTexture(layer.blit, dst, m, false);

		m = new Matrix();
		m.translate(0, r + scrollY);
		renderToTexture(layer.blit, dst, m, false);

		m = new Matrix();
		m.translate(0, -r + scrollY);
		renderToTexture(layer.blit, dst, m, false);

		layer.bmp = dst;
		layer.backBmp = src;
		if (layer.view != null)
			layer.view.texture = layer.bmp;
	}

	inline function renderToTexture(object:Dynamic, texture:RenderTexture, matrix:Matrix, clear:Bool):Void {
		KadoKadeoManager.kkm.renderer.render(object, cast {renderTexture: texture, clear: clear, transform: matrix});
	}

	public function plasmaDraw(mc:ASprite, n:Int) {
		if (plasma.layer[n] == null)
			return;
		var bmp = plasma.layer[n].bmp;

		var m = new Matrix();
		m.scale((mc._xscale / 100) * pq, (mc._yscale / 100) * pq);
		m.rotate(mc._rotation * 0.0174);
		m.translate((mc._x) * pq, (mc._y + PLASMA_CACHE) * pq);

		// Commented while converting to pixi:
		// var ct = new flash.geom.ColorTransform(1, 1, 1, 1, 0, 0, 0, -255 + mc._alpha * 2.55);
		// var b = mc.blendMode;
		// bmp.draw(mc, m, ct, b, null, false);

		/* PIXI VERSION COMMENT: Exemple Haxe (Pixi) pour l’équivalent de ColorTransform : */
		var f = new pixi.filters.colormatrix.ColorMatrixFilter();
		var a = mc.alpha; // 0..1 en Pixi
		// Matrice identité + offset sur alpha (dernière valeur)
		f.matrix = [
			1, 0, 0, 0,   0,
			0, 1, 0, 0,   0,
			0, 0, 1, 0,   0,
			0, 0, 0, 1, a - 1
		];
		mc.filters = [f];
		bmp.draw(mc, m);
	}

	public function plasmaPoint(x, y, color) {
		trace('TODO: plasmaPoint', x, y, color);
		// TODO:
		// var bmp = plasma.layer[0].bmp;
		// bmp.setPixel32(Std.int(x), Std.int(y), color);
	}

	public function setPq(n) {
		pq = n;
		plasma.removeMovieClip();
		initPlasma();
	}

	// SCROLL
	public function updateScroll() {
		if (gfxMode < 3) {
			SCROLL_SPEED *= 0.95;
			if (SCROLL_SPEED < 0.5 * Cs.NEW_GEN_SCALE)
				SCROLL_SPEED = 0;
		} else {
			if (step > 1) {
				SCROLL_SPEED = Math.min(SCROLL_SPEED + 0.01 * Cs.NEW_GEN_SCALE * Timer.tmod, SCROLL_SPEED_MAX);
			}
		}

		bg._y += SCROLL_SPEED;
		if (bg._y > 0) {
			// bg._y -= 1800 * Cs.NEW_GEN_SCALE;
			bg._y -= 2700;
			bg._prevState.y = bg._y - SCROLL_SPEED; // Hack to avoid weird scroll (interpolation) when the bg is repositionned
		}

		var i = 0;
		while (i < baseList.length) {
			var b = baseList[i];
			if (b._y == 0)
				b._y = Cs.mch;
			b._y += SCROLL_SPEED;
			if (b._y > Cs.mch + 100 * Cs.NEW_GEN_SCALE) {
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
			if (isKeyJustPressed(n))
				hero.addBox();
		}
		for (n in 54...59) {
			if (isKeyJustPressed(n)) {
				var bonus = new Bonus(null);
				bonus.x = Cs.rand() * Cs.mcw;
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

		var axisX = 0;
		var axisY = 0;
		if (joystick.active) {
			if (joystick.nx <= -JOYSTICK_DIGITAL_THRESHOLD) {
				axisX = -1;
			} else if (joystick.nx >= JOYSTICK_DIGITAL_THRESHOLD) {
				axisX = 1;
			}
			if (joystick.ny <= -JOYSTICK_DIGITAL_THRESHOLD) {
				axisY = -1;
			} else if (joystick.ny >= JOYSTICK_DIGITAL_THRESHOLD) {
				axisY = 1;
			}
		}

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
		SCROLL_SPEED = 0.0001 * Cs.NEW_GEN_SCALE;
		Stykades.monsterLevel = 0;
		Stykades.waveTimer = 150;
		Stykades.nextWave = 300;
		Stykades.dif = 0;
		Stykades.nextBonus = 300;
		Stykades.FL_CREATE_LOCK = false;
		Bonus.NB = 0;

		if (bg != null)
			bg.filters = [];
		if (root != null)
			Col.setPercentColor(root, 0, 0xFFFFFF);

		Cs.game = null;
	}
}
