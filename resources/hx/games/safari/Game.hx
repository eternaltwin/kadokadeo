package safari;

import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import haxe.io.UInt16Array;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;
import pixi.filters.colormatrix.ColorMatrixFilter;
import safari.Entities;

// Safari (KadoKado, Motion-Twin): ported from the original sources (Manager, Game, Data, Car, Scroller, Entity,
// Mover and their subclasses of the safari folder) and the graphics of its SWF. A jeep rides through the jungle; its
// gatling gun shoots where the mouse points (button held) at the UFOs coming from the left. Three UFOs that get
// through and the mission is over. The game runs in the Flash pixels of the original (300 x 300), drawn x2.
@:expose('GameSafari')
class Game implements kado.GameInterface {
	public static inline var K = 2;

	public static var me:Game;

	public var depthMan:Plans;
	public var root:ASprite;
	public var mcs:Array<Mc>;

	public var scroller:Scroller;
	public var entityList:Array<Entity>;

	var spawnList:Array<Int>;

	var bulletPool:ASprite;
	var bullets:Mc;
	var bulletMask:Graphics;
	var bulletWidth:Float;
	var multiField:Digits;

	public var cross:Clip;

	var popUp:PopUp;

	public var car:Car;

	var ammo:Float;
	var coolDown:Float;

	var misses:Int;

	public var targets:Int;

	var maxTargets:Int;

	public var multi:Int;
	public var multiTimer:Float;

	var combo:Int;
	var comboPool:Int;

	public var kills:Int;

	var shots:Int;
	var goodShots:Int;
	var badShots:Int;
	var retroShots:Int;
	var lastBonus:Float;

	public var level:Float;

	var lastSpawnTimer:Float;
	var startTimer:Float;

	var optionList:Array<Float>;

	var fl_shoot:Bool;

	public var fl_gameRunning:Bool;
	public var fl_gameOver:Bool;
	public var fl_fast:Bool;

	var endTimer:Float = 0;
	var gameTimer:Float;

	// manager.root.onRelease (click on the start message)
	var onRelease:Bool;

	// timelines played by the code (bonus texts, "x2"), advanced once per frame
	public var anims:Array<{function advance():Bool;}>;

	var scene:ASprite;
	var isReplay:Bool;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: UInt16Array.fromArray([KeyboardManager.ARROW_LEFT, KeyboardManager.ARROW_RIGHT]),
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: UInt16Array.fromArray([MouseManager.BUTTON_LEFT]),
		});
		me = this;
		mcs = [];
		anims = [];
		this.isReplay = isReplay;
		Clip.flushRemoved();
		Entity.clearFilters();

		scene = root.createEmptyMovieClip("scene", 0);
		scene._xscale = scene._yscale = 100 * K;
		scene.updateState();
		this.root = scene.createEmptyMovieClip("world", 0);
		depthMan = new Plans(this.root);

		// like the Flash player, the game keeps the mouse while its button is held
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.addEventListener("pointerdown", onPointerDown);
		}

		gameTimer = 0;

		scroller = new Scroller(this);
		entityList = [];
		fl_shoot = false;
		fl_gameRunning = false;
		fl_gameOver = false;
		fl_fast = false;

		cross = depthMan.add(new Clip("cross"), Data.DP_INTERF);
		cross._visible = false;
		cross.getClip("center").scripted = true;

		initBulletPool();

		attachPopUp();
		startTimer = 65;
		onRelease = true;

		car = new Car(this);

		ammo = Data.AMMO;
		coolDown = 0;

		targets = 0;
		maxTargets = 0;
		misses = 0;
		multi = 1;
		multiTimer = 0;
		combo = 0;
		comboPool = 0;
		kills = 0;
		shots = 0;
		goodShots = 0;
		retroShots = 0;
		badShots = 0;
		level = 0.0;
		lastSpawnTimer = 0;
		lastBonus = 0;

		interfaceUpdate();
		initSpawner();
		warmShaders();
	}

	function onPointerDown(e:Dynamic) {
		try {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.setPointerCapture(e.pointerId);
		} catch (_:Dynamic) {}
	}

	// bulletPool: the bullets (20 in the picture) under a mask as wide as the ammo, and the multiplier " x5"
	function initBulletPool() {
		bulletPool = depthMan.empty(Data.DP_INTERF);
		bulletPool._x = Data.AMMO_X;
		bulletPool._y = Data.AMMO_Y;
		bulletPool.updateState();
		bullets = new Mc("bullets", false);
		bullets.updateState();
		bulletPool.addChild(bullets);
		bulletMask = new Graphics();
		bulletPool.addChild(bulletMask);
		bullets.mask = bulletMask;
		var b = Art.BOUNDS.get("bulletPool1");
		bulletWidth = b[2] - b[0];
		multiField = new Digits(Art.MU_FIELD, "muGlyph", Art.MU_CHARS, Art.MU_ADV, Art.MU_ASC, false);
		bulletPool.addChild(multiField);
	}

	function setMask(w:Float) {
		// mask (sprite 102 at 28.35, -8.5: a rectangle 0..10 x -12.5..12.5) of width w
		bulletMask.clear();
		bulletMask.beginFill(0xFFFFFF);
		bulletMask.drawRect(28.35, -8.5 - 12.5, Math.max(0, w), 25);
		bulletMask.endFill();
	}

	// *** DIVERS

	// DÉMARRAGE DU JEU
	function startGame() {
		startTimer = 0;
		clearRelease();
		mouseHide(true);
		car.enterGame();
		if (popUp != null) {
			popUp.removeMovieClip();
			popUp = null;
		}
		fl_gameRunning = true;
	}

	function mouseHide(hide:Bool) {
		if (isReplay)
			return;
		var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
		canvas.style.cursor = hide ? "none" : "";
	}

	// FIN DU JEU
	function endGame() {
		if (fl_gameOver)
			return;

		var p = {};
		Reflect.setField(p, "$r", retroShots);
		Reflect.setField(p, "$g", goodShots);
		Reflect.setField(p, "$b", badShots);
		KadoKadeoManager.kkm.gameOver(p);

		mouseHide(false);
		cross._visible = false;
		car.stopShoot();
		car.stableBodyY *= 0.7;
		fl_gameRunning = false;
		fl_gameOver = true;

		for (e in entityList.copy()) {
			if (e.removed)
				continue;
			if (e.fl_useless)
				e.kill();
			else if (e.mover != null)
				e.mover.dx += scroller.speed * 0.5;
		}
	}

	// ATTACH: POP-UP DE TEXTE (" Attaque imminente ", "Préparez-vous pour l'assaut !")
	function attachPopUp() {
		if (popUp != null)
			popUp.removeMovieClip();
		popUp = depthMan.add(new PopUp(), Data.DP_INTERF);
		popUp._x = 150;
		popUp._y = 90;
		popUp.updateState();
	}

	// RANDOM TMODDÉ
	function randomT(n:Float):Int {
		return Seed.random(Math.round(n * 1 / Timer.tmod));
	}

	// GESTION DES CIBLES
	function spawner() {
		// Spawn de rabbit-options
		while (optionList.length > 0 && level >= optionList[0]) {
			Option.attach(this, -20, Seed.random(170) + 50);
			optionList.splice(0, 1);
		}

		if (lastSpawnTimer > 0) {
			lastSpawnTimer -= Timer.tmod;
			if (lastSpawnTimer < 0)
				lastSpawnTimer = 0;
			return;
		}

		// Evolution du maxTargets
		maxTargets = Data.MIN_TARGETS + Math.floor(level);

		// Calcul de la chance d'apparition
		var chance = Data.PROBA_SPAWN * Timer.tmod * level * 0.5;
		chance += (maxTargets - targets) * (maxTargets - targets) * 5;
		if (targets == 0)
			chance *= 1000;

		if (targets < maxTargets && Seed.random(1000) <= chance) {
			lastSpawnTimer = Math.max(0, 8 - level * 2) + Seed.random(Std.int(Math.max(0, 20 - level * 2)));
			if (Seed.random(1000) <= Data.PROBA_BIG * Timer.tmod) {
				// Gros
				Big.attach(this, -40, Seed.random(120) + 30);
			} else {
				// Spawn d'un monstre de base au hasard
				var n = Math.min(spawnList.length - 1, Seed.random(spawnList.length) + level * 10);
				var id = spawnList[Math.round(n)];
				if (id == Data.DRONE) {
					Drone.attach(this, -20, Seed.random(170) + 50);
				} else if (id == Data.WARPER) {
					if (level > 1.5)
						Warper.attach(this, -20, Seed.random(170) + 50);
				}
			}
		}
	}

	// TUE TOUS LES BADS EN JEU
	function destroyAll() {
		for (e in entityList.copy()) {
			if (e.removed)
				continue;
			if (Std.isOfType(e, Target) && (cast e : Target).bonus != null) {
				Instant.attach(this, e.px + 15, e.py, Data.EXPLOSION);
				e.kill();
			}
		}
	}

	// INITIALISATION DES RÉPARTITIONS ALÉATOIRES
	function initSpawner() {
		spawnList = [];

		for (i in 0...Data.PROBA_DRONE)
			spawnList.push(Data.DRONE);
		for (i in 0...Data.PROBA_WARPER)
			spawnList.push(Data.WARPER);

		optionList = [];
		var l = 0.0;
		var total = 5 + Seed.random(3);
		for (i in 0...total) {
			l += Seed.random(25) / 10;
			optionList.push(l);
		}
	}

	// *** EVENTS

	function clearRelease() {
		onRelease = false;
	}

	// mouse listener of the original (onMouseDown / onMouseUp / onRelease of the root)
	function readInputs() {
		for (c in MouseManager.getFrameButtonChanges()) {
			if (c.button != MouseManager.BUTTON_LEFT)
				continue;
			if (c.isDown) {
				// the shot of a press goes where the pointer is now (a finger lands anywhere: the cross of the last
				// frame would be where the previous touch was)
				if (fl_gameRunning && !fl_gameOver)
					placeCross();
				mouseDown();
			} else {
				mouseUp();
				if (onRelease)
					startGame();
			}
		}
	}

	function mouseDown() {
		if (!fl_gameRunning || fl_gameOver)
			return;
		fl_shoot = true;
		shoot();
	}

	function mouseUp() {
		fl_shoot = false;
	}

	// *** ARMEMENT

	// TIR
	function shoot() {
		var x = cross._x;
		var y = cross._y;

		if (ammo < 1) {
			car.stopShoot();
			return;
		}

		car.shoot();

		if (coolDown > 0)
			return;

		ammo--;
		shots++;
		coolDown = Data.HEAT;

		// Cartouche
		Cartridge.attach(this, car.x + Data.CANON_X, car.y + Data.CANON_Y);

		// Cibleur
		var center = cross.getClip("center");
		center._rotation -= 30;
		center._xscale = 130 + Seed.randomVfx(100);
		center._yscale = center._xscale;
		var light = Seed.randomVfx(100) + 100;
		Entity.colorOf(cross.getClip("sub"), light);

		// Parcours des cibles
		var found = false;
		var i = entityList.length - 1;
		while (i >= 0) {
			var e = entityList[i];
			i--;
			if (e.removed)
				continue;
			if (e.fl_count && !e.fl_kill && x >= e.px - e.radius && x <= e.px + e.radius && y >= e.py - e.radius && y <= e.py + e.radius) {
				var dist = Math.sqrt((x - e.px) * (x - e.px) + (y - e.py) * (y - e.py));
				if (dist <= e.radius) {
					(cast e : Target).hit(1);
					found = true;
					break;
				}
			}
		}

		if (found) {
			goodShots++;
			return;
		}

		// (the original compares y to carRetro.x)
		var carRetro = {x: car.body._x + 17, y: car.body._y - 26};
		var distRetro = Math.sqrt((x - carRetro.x) * (x - carRetro.x) + (y - carRetro.x) * (y - carRetro.x));
		if (distRetro < 10) {
			retroShots++;
		} else {
			badShots++;
		}
	}

	// RECHARGEMENT
	function reload() {
		if (ammo < Data.AMMO) {
			ammo += Data.RELOAD * Timer.tmod;
			if (ammo > Data.AMMO)
				ammo = Data.AMMO;
		}
	}

	// MAIN: REFROIDISSEMENT CANON ET MULTI
	function interfaceUpdate() {
		var width = bulletWidth / 20;
		setMask(width * Math.floor(ammo));
		multiField.setText(" x" + multi);
	}

	// root._xmouse / root._ymouse (Flash pixels)
	function placeCross() {
		var x = Math.max(0, MouseManager.getX()) / K;
		var y = Math.max(0, MouseManager.getY()) / K;
		if (x != 0 && y != 0)
			cross._visible = true;
		cross._x = x;
		cross._y = y;
	}

	// MAIN: CIBLEUR
	function manageCross() {
		placeCross();
		Entity.colorOf(cross.getClip("sub"), 0);
		var center = cross.getClip("center");
		center._rotation += 15;

		var s = center._xscale;
		s += (100 - s) * 0.1;
		center._xscale = s;
		center._yscale = s;
	}

	// *** SCORES

	// GAIN DE POINTS
	public function getBonus(n:Int, label:String, x:Float, y:Float) {
		n = n * multi;

		if (label == null)
			label = "" + n;

		var mc = depthMan.add(new BonusMc(label), Data.DP_INTERF);
		mc._x = x;
		mc._y = y;
		mc.updateState();
		anims.push(mc);

		lastBonus = gameTimer;
		combo++;
		comboPool += n;
		KadoKadeoManager.kkm.addScore(n);
	}

	// GESTION DES COMBOS
	function manageCombos() {
		if (gameTimer - lastBonus > Data.COMBO_TIMER) {
			if (combo > 1) {
				getBonus(combo * Data.C25, combo + " hits", car.x + Data.CAR_WIDTH / 2, car.y - 70);
			}
			combo = 0;
			comboPool = 0;
		}
	}

	// AJOUTE UN MISS
	public function miss(id:Int) {
		if (fl_gameOver)
			return;
		var mc = depthMan.add(new Clip("miss"), Data.DP_INTERF);
		mc._x = 285 - misses * 30;
		mc._y = 15;
		mc.gotoAndStop(id + 1);
		mc.updateState();
		misses++;
		destroyAll();
		if (misses >= Data.MAX_MISSES)
			endGame();
	}

	// *** MAIN

	// MAIN DE GAME OVER
	function updateEnd() {
		scroller.speed = Math.max(4, scroller.speed * 0.95);
		endTimer -= Timer.tmod;

		if (car.x >= 100)
			car.dx -= 0.5 * Timer.tmod;
	}

	// one frame of the Flash player
	public function update(delta:Float) {
		Clip.flushRemoved();
		advanceClips();
		readInputs();

		gameTimer += Timer.tmod;

		// Scolling
		scroller.update();
		if (startTimer > 0) {
			startTimer -= Timer.tmod;
			if (startTimer <= 0)
				startGame();
		}

		if (fl_gameOver)
			updateEnd();

		if (fl_gameRunning) {
			if (multiTimer > 0) {
				multiTimer -= Timer.tmod;
				if (multiTimer <= 0) {
					multiTimer = 0;
					multi = 1;
				}
			}
			level += Data.LEVELING_SPEED * Timer.tmod;

			scroller.updateSpeed();

			// Cible
			manageCross();

			// Divers
			manageCombos();

			// Tir
			if (fl_shoot)
				shoot();
			else {
				car.stopShoot();
				reload();
			}
			if (coolDown > 0)
				coolDown -= Timer.tmod;
			interfaceUpdate();

			spawner();
		}

		// Updates d'entités
		var i = 0;
		while (i < entityList.length) {
			var e = entityList[i];
			if (!e.removed) {
				e.step();
				if (!e.removed)
					e.endStep();
			}
			if (e.removed) {
				entityList.splice(i, 1);
				i--;
			}
			i++;
		}

		car.update();
	}

	function advanceClips() {
		var i = 0;
		var n = mcs.length;
		while (i < n) {
			var m = mcs[i];
			if (m.dead || m.parent == null) {
				mcs[i] = mcs[n - 1];
				mcs.pop();
				n--;
				continue;
			}
			m.advance();
			i++;
		}
		var i = 0;
		while (i < anims.length) {
			if (!anims[i].advance()) {
				anims.splice(i, 1);
				continue;
			}
			i++;
		}
	}

	// the colour offsets of the original are colour matrix filters: their shader compiled at the start
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var holder = new Container();
		var s = new PixiSprite(Texture.WHITE);
		s.filters = [new ColorMatrixFilter()];
		holder.addChild(s);
		var m = new Graphics();
		m.beginFill(0xFFFFFF);
		m.drawRect(0, 0, 8, 8);
		m.endFill();
		var s2 = new PixiSprite(Texture.WHITE);
		holder.addChild(m);
		holder.addChild(s2);
		s2.mask = m;
		var rt:RenderTexture = (cast RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	public function destroy():Void {
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.removeEventListener("pointerdown", onPointerDown);
			canvas.style.cursor = "";
		}
		Clip.flushRemoved();
		mcs = [];
		anims = [];
	}
}

// ---------------------------------------------------------------- start message
// popUp: its sub (box and texts) fading in on 13 frames, then stopped
class PopUp extends ASprite {
	var f:Int;
	var sub:Mc;

	public function new() {
		super();
		sub = new Mc("popUpSub", false);
		addChild(sub);
		f = 1;
		show();
		Game.me.anims.push(this);
	}

	function show() {
		sub._alpha = Art.POPUP_ALPHA[f - 1] * 100;
	}

	public function advance():Bool {
		if (parent == null)
			return false;
		if (f < Art.POPUP_ALPHA.length) {
			f++;
			show();
		}
		return true;
	}
}

// "bonus": the score of a kill (sub > field) going up, staying, then sliding to the left while fading (32 frames)
class BonusMc extends ASprite {
	var f:Int;
	var sub:ASprite;

	public function new(label:String) {
		super();
		sub = new ASprite();
		addChild(sub);
		var t = new Digits(Art.BN_FIELD, "bnGlyph", Art.BN_CHARS, Art.BN_ADV, Art.BN_ASC, true);
		t.setText(label);
		sub.addChild(t);
		f = 1;
		show();
	}

	function show() {
		var t = Art.BONUS_TRACK[f - 1];
		sub._x = t[0];
		sub._y = t[1];
		sub._xscale = t[2] * 100;
		sub._yscale = t[3] * 100;
		sub._alpha = t[4] * 100;
	}

	public function advance():Bool {
		f++;
		if (f >= 32 || Art.BONUS_TRACK[f - 1] == null) {
			removeMovieClip();
			return false;
		}
		show();
		return true;
	}
}

// "displayBonus" of a rabbit: the star turning (clip) and the text " x2 " (two grey shadows, the white one)
class DisplayBonus extends ASprite {
	var clip:Clip;
	var txt:ASprite;

	public function new(text:String) {
		super();
		clip = new Clip("displayBonus");
		addChild(clip);
		txt = new ASprite();
		addChild(txt);
		for (i in 0...3) {
			var d = i == 2 ? new Digits(Art.DB_FIELDS[i], "dbGlyph", Art.DB_CHARS, Art.DB_ADV, Art.DB_ASC, true) : new Digits(Art.DB_FIELDS[i],
				"dbgGlyph", Art.DBG_CHARS, Art.DBG_ADV, Art.DBG_ASC, true);
			d.setText(text);
			txt.addChild(d);
		}
		show();
	}

	function show() {
		var t = Art.DB_TRACK[clip.frame - 1];
		if (t == null) {
			txt._visible = false;
			return;
		}
		txt._visible = true;
		txt._x = t[0];
		txt._y = t[1];
		txt._xscale = t[2] * 100;
		txt._yscale = t[3] * 100;
		txt._alpha = t[4] * 100;
	}

	public function advance():Bool {
		if (clip.parent == null || !clip.visible) {
			removeMovieClip();
			return false;
		}
		show();
		return true;
	}
}

// text of a field drawn with the glyphs of the SWF font ([left, width, top] of the field, centred or left aligned)
class Digits extends ASprite {
	var field:Array<Float>;
	var anim:String;
	var chars:String;
	var adv:Array<Float>;
	var asc:Float;
	var centred:Bool;
	var text:String;

	public function new(field:Array<Float>, anim:String, chars:String, adv:Array<Float>, asc:Float, centred:Bool) {
		super();
		this.field = field;
		this.anim = anim;
		this.chars = chars;
		this.adv = adv;
		this.asc = asc;
		this.centred = centred;
		text = null;
	}

	public function setText(s:String) {
		if (s == text)
			return;
		text = s;
		removeChildren();
		var width = 0.0;
		var space = adv[0] * 0.3;
		for (i in 0...s.length) {
			var k = chars.indexOf(s.charAt(i));
			width += k >= 0 ? adv[k] : space;
		}
		var pen = centred ? field[0] + (field[1] - width) / 2 : field[0];
		var base = field[2] + asc;
		for (i in 0...s.length) {
			var k = chars.indexOf(s.charAt(i));
			if (k < 0) {
				pen += space;
				continue;
			}
			if (s.charAt(i) != " ") {
				var g = new Mc(anim, false);
				g.gotoAndStop(k + 1);
				g._x = pen;
				g._y = base;
				g.updateState();
				addChild(g);
			}
			pen += adv[k];
		}
	}
}
