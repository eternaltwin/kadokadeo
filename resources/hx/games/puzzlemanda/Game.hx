package puzzlemanda;

import haxe.io.UInt16Array;
import kado.ReplayManager;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;
import pixi.filters.colormatrix.ColorMatrixFilter;
import puzzlemanda.Anim;
import puzzlemanda.MC.Plans;

enum DestroyType {
	SnakeEat;
	SnakeEatSuite;
	EndLevel;
}

class Const {
	public static var WIDTH_1 = KKApi.const(4);
	public static var WIDTH_2 = KKApi.const(6);
	public static var WIDTH_3 = KKApi.const(8);
	public static var WIDTH_4 = KKApi.const(10);

	public static var HEIGHT_1 = KKApi.const(2);
	public static var HEIGHT_2 = KKApi.const(4);
	public static var HEIGHT_3 = KKApi.const(6);
	public static var HEIGHT_4 = KKApi.const(8);

	public static var LENGTH_1 = KKApi.const(5);
	public static var LENGTH_2 = KKApi.const(6);
	public static var LENGTH_3 = KKApi.const(7);
	public static var LENGTH_4 = KKApi.const(8);

	public static var TIME = KKApi.const(2000);
	public static var TIME_COEF = 0.9;

	public static var BASIC_SYMBOLS = KKApi.const(5);
	public static var POINTS = KKApi.aconst([75, 100, 150, 200, 300, 2000, 5000, 15000]);
	public static var RPOINTS = KKApi.aconst([-75, -100, -150, -200, -300, -2000, -5000, -15000]);

	public static var BONUS_PROBA = KKApi.aconst([100, 20, 5, 1]);

	public static var ANIM_BLINK = {start: 10, end: 25};
	public static var ANIM_APPEAR = {start: 30, end: 40};

	public static var FRAME_HORI = 60;
	public static var FRAME_VERT = 61;
	public static var FRAME_BOTTOM_RIGHT = 62;
	public static var FRAME_BOTTOM_LEFT = 63;
	public static var FRAME_TOP_RIGHT = 64;
	public static var FRAME_TOP_LEFT = 65;

	public static var ANIM_SNAKE_STEP = 5;

	public static var DESTROY_ANIM_LENGTH = 30;
}

// Game.hx of the original (Haxe for Flash 8), line by line; the port's own parts are at the end
@:expose('GamePuzzleManda')
class Game implements kado.GameInterface {
	// Flash played Puzzle-Manda at 40 frames/s (the rate of the KadoKado loader that plays the game SWF) with
	// Timer.wantedFPS = 32
	public static inline var FLASH_FPS = 40;

	public static var DP_BG = 0;
	public static var DP_GRID = 2;
	public static var DP_CELL = 4;
	public static var DP_SNAKE = 6;
	public static var DP_PART = 8;

	// (mt.flash.Volatile: the anti-cheat of the original, plain variables)
	static var level:Int;
	static var levelStarted:Bool;
	static var globalLock:Bool;

	public static var levelEnded:Bool;
	public static var grid:Array<Array<Cell>>;
	public static var suite:Suite;

	public static var width:KKConst;
	public static var height:KKConst;
	public static var length:KKConst;

	public static var time:Null<Float>;
	public static var cTime:Float;

	public static var inst(default, null):Game;

	static var anim:Array<Anim>;
	static var animToAdd:Array<Anim>;

	var mcBg:MC;
	var mcGrid:MC;
	var mcTitle:MC;

	var barPlay:Bool;
	var levelClean:Bool;

	public static var dm:Plans;

	public static var cleanId:Int;

	// ---------------------------------------------------------------- port
	// The replay records what the mouse did to the game, not the mouse (long games): one event (one byte, packed
	// {k, x, y}) per click or hover that changed it, for the step being played, FLASH_BIT set when it happened on the
	// second Flash frame of the step:
	//   ACT_REINIT: a click cancels the snake (onRelease of a cell or of bg)
	//   ACT_OVER + d: the snake moves to the neighbour d of its head (Cell.DX / DY) by a rollOver
	//   ACT_FOLLOW + d: the same by the pointer the head follows (Cell.tryNeighbour, in Manager.main)
	//   ACT_START + i: a click starts the snake on the cell i (y * width + x)
	// Live: the button events (Buttons) and the pointer choose the action, recorded then applied (act); replay: the
	// events of the step at the same moments (the clicks and rollOvers before the Flash frame, the follow at its first
	// tryNeighbour). Both apply it with the rules of the original (locked, Suite.check).
	public static inline var ACT_REINIT = 0;
	public static inline var ACT_OVER = 1;
	public static inline var ACT_FOLLOW = 5;
	public static inline var ACT_START = 9;
	static inline var FLASH_BIT = 128;

	public static var me(get, never):Game;

	var root:ASprite;

	public var isReplay(default, null):Bool;

	var buttons:Buttons;
	var title:TitleText;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	// the score of KKApi, nothing after the game over
	var over:Bool = false;
	var onPointerDown:Dynamic;
	var handCursor:Bool = false;
	// the Flash frame of the step being played (0, 1)
	var flashIndex:Int = 0;
	// replay: the actions of the step not applied yet
	var replayActions:Array<Int> = [];

	// the mouse in the game's root (_xmouse / _ymouse, Flash pixels; live games only)
	public var mouseX(default, null):Float = 0;
	public var mouseY(default, null):Float = 0;

	#if debug
	// test harness: what the game went through (window.__over)
	public var stats = {starts: 0, eaten: 0, rollOvers: 0, tries: 0, reinits: 0, bonus: 0, levels: 0};

	// what the game went through, frame by frame (window.__events)
	public function event(s:String) {
		var l:Array<String> = untyped js.Browser.window.__events;
		if (l == null)
			untyped js.Browser.window.__events = l = [];
		l.push(frameCount + " " + s);
	}
	#end

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});
		// statics of the original (the SWF was loaded again for every game)
		MC.clearAll();
		Clip.reset();
		Sprite.spriteList = [];
		time = null;
		cTime = 0;
		grid = null;
		suite = null;
		cleanId = 0;
		// mt.Timer before its first update (Manager.init creates the game before the first Manager.main)
		Timer.tmod = 1;
		Timer.deltaT = 1;
		Clip.deferring = true;
		// like the Flash player, a pressed button keeps the mouse while the button is held (its release outside the game
		// is still seen); a finger: the touch mode (the replay has the actions it made)
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			onPointerDown = function(e:Dynamic) {
				try {
					canvas.setPointerCapture(e.pointerId);
				} catch (_:Dynamic) {}
				if (e.pointerType == "touch")
					buttons.touch = true;
			};
			canvas.addEventListener("pointerdown", onPointerDown);
		}

		// the original's 300x300 pixels, drawn x2
		root = mc.createEmptyMovieClip("scene", 0);
		root._xscale = root._yscale = 100 * Clip.K;
		root.updateState();

		/*
			Cell.dmanager = new mt.DepthManager( mc.createEmptyMovieClip("a",5) );
			Suite.dmanager = new mt.DepthManager( mc.createEmptyMovieClip("b",10) );
			var dmanager = new mt.DepthManager( mc.createEmptyMovieClip("c",15) );
			mcBg = cast dmanager.attach("bg",1);
			mcBg.bar.stop();
		 */
		dm = new Plans(root);
		mcBg = dm.attach("bg", DP_BG);
		mcBg.onRelease = onRelease;
		// port: bg is a button (onRelease): its shape covers the stage
		mcBg.hit = function(x, y) return x >= 0 && x < 300 && y >= -0.25 && y < 300;

		level = 0;
		globalLock = false;

		inst = this;
		anim = new Array();
		animToAdd = new Array();

		buttons = new Buttons(dm, [DP_CELL, DP_BG]);

		levelUp();

		// (a colour transform of the whole game, commented out in the original)

		Clip.deferring = false;
		Clip.runLater();
		MC.displayAll(1);
		title.display();
		// Flash shows the first picture after the first frame (Manager.init, then Manager.main)
		root.visible = false;
		warmShaders();
	}

	function onRelease() {
		if (!locked() && suite.started())
			act(ACT_REINIT);
	}

	public function cleanLevel() {
		cleanId = Seed.random(Std.int(Math.min(5, level * 0.5)));
		if (suite != null)
			suite.kill();
		if (grid != null)
			for (a in grid)
				for (c in a)
					c.kill();
		levelClean = true;
	}

	public function levelUp() {
		level++;
		levelStarted = false;
		levelEnded = false;
		levelClean = false;

		mcBg.subGotoAndStop("bar", 1);
		barPlay = false;

		initConst();
		initGrid();
		initSuite();
		#if debug
		stats.levels = level;
		#end
	}

	public static function locked():Bool {
		return globalLock || anim.length > 0 || animToAdd.length > 0;
	}

	public function onEndAnim() {
		if (!levelStarted)
			levelStarted = true;
		if (levelEnded) {
			if (levelClean)
				levelUp();
			else
				cleanLevel();
		}
		suite.tryNext();
	}

	function initConst() {
		if (level < 3) {
			width = Const.WIDTH_1;
			height = Const.HEIGHT_1;
			length = Const.LENGTH_1;
		} else if (level < 8) {
			width = Const.WIDTH_2;
			height = Const.HEIGHT_2;
			length = Const.LENGTH_2;
		} else if (level < 30) {
			width = Const.WIDTH_3;
			height = Const.HEIGHT_3;
			length = Const.LENGTH_3;
		} else {
			width = Const.WIDTH_4;
			height = Const.HEIGHT_4;
			length = Const.LENGTH_4;
		}

		if (time == null)
			time = KKApi.val(Const.TIME);
		else
			time *= Const.TIME_COEF;

		cTime = time;
	}

	function initGrid() {
		grid = new Array();

		for (i in 0...KKApi.val(height)) {
			grid[i] = new Array();
			for (j in 0...KKApi.val(width)) {
				var v = Seed.random(KKApi.val(Const.BASIC_SYMBOLS));
				grid[i][j] = new Cell(j, i, v);
			}
		}

		if (mcGrid == null) {
			mcGrid = dm.attach("back", DP_GRID);
			mcTitle = dm.attach("title", DP_GRID);
			// GlowFilter(blur 3, color 0x995DCA, strength 5) pushed in mcTitle.filters: drawn at run time, around the
			// picture of the title and its text (TitleText)
			title = new TitleText(mcTitle);
		}
		var m = 8;
		mcGrid._x = Cell.getX(0) - m;
		// (getX for the y and the height: the original's)
		mcGrid._y = Cell.getX(0) - m;
		mcGrid._xscale = (Cell.getX(KKApi.val(width)) - mcGrid._x) + m;
		mcGrid._yscale = (Cell.getX(KKApi.val(height)) - mcGrid._y) + m;

		mcGrid._x += -15;
		mcGrid._y += 43;

		mcTitle._x = mcGrid._x;
		mcTitle._y = mcGrid._y;

		// vat tf : flash.TextField = Reflect.field(mcTitle,"field");
		title.text = "NIVEAU " + level;
	}

	function initSuite() {
		suite = new Suite();

		// get first
		var cur = grid[Seed.random(KKApi.val(height))][Seed.random(KKApi.val(width))];
		cur.chained = true;
		suite.add(cur);

		for (i in 1...KKApi.val(length)) {
			cur = cur.randomNeighbour();
			if (cur == null)
				break;
			cur.chained = true;
			suite.add(cur);
		}
		suite.clean();

		var type:Null<Int> = null;
		do {
			var t = 0;
			for (a in Const.BONUS_PROBA)
				t += KKApi.val(a);
			var r = Seed.random(t);

			var tType = 0;
			for (a in Const.BONUS_PROBA) {
				r -= KKApi.val(a);
				if (r < 0) {
					type = tType;
					break;
				}
				tType++;
			}
			if (type == null) {
				type = 0;
			}

			if (type > 0) {
				// on a un fruit de la suite qui doit être upgradé en bonus
				var c = suite.list[Seed.random(suite.list.length)];
				if (c.symbol >= KKApi.val(Const.BASIC_SYMBOLS)) {
					type = 0;
				} else {
					c.symbol = KKApi.val(Const.BASIC_SYMBOLS) + type - 1;
					#if debug
					stats.bonus++;
					#end
				}
			}
		} while (type > 0);

		for (a in grid)
			for (c in a)
				c.display();

		suite.display();
	}

	public static function addAnim(a:Anim) {
		animToAdd.push(a);
	}

	// update() of the original (Manager.main, once per Flash frame)
	function main() {
		if (animToAdd.length > 0) {
			for (a in animToAdd)
				anim.push(a);
			animToAdd = new Array();
		}

		suite.update();
		if (anim.length > 0) {
			var animToRemove = new Array();
			// (an index loop that reads the length at each turn, like the original's)
			var i = 0;
			while (i < anim.length) {
				var a = anim[i];
				i++;
				if (a.play())
					animToRemove.push(a);
			}

			for (a in animToRemove)
				anim.remove(a);

			if (anim.length == 0 && animToAdd.length == 0)
				onEndAnim();
		}

		if (anim.length == 0 && animToAdd.length == 0)
			suite.tryNext();

		if (levelStarted && !levelEnded) {
			cTime -= Timer.deltaT * 24;
			if (cTime <= 0) {
				// (KKApi.gameOver(null), called again on every frame after: once here)
				gameOver();
				globalLock = true;
			}
		}

		mcBg.setSub("bar", null, null, Math.max(0, cTime * 100 / time));
		if (cTime < 200 && !barPlay) {
			barPlay = true;
			var bar = mcBg.sub("bar");
			if (bar != null)
				bar.play();
		}

		// (a kill removes the sprite from the list: the next one waits until the next frame, like the original's loop)
		var i = 0;
		while (i < Sprite.spriteList.length) {
			var p = Sprite.spriteList[i];
			i++;
			p.update();
		}
	}

	public function destroyAnim(mc:MC, type:DestroyType) {
		switch (type) {
			case EndLevel:
				var max = Std.int(Math.min(3, 120 / Sprite.spriteList.length));
				for (i in 0...max) {
					var p = new Phys(dm.attach("partDifuse", DP_PART));
					p.x = mc._x;
					p.y = mc._y;
					var a = Seed.randVfx() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var speed = 0.5 + Seed.randVfx() * 4;
					p.vx = ca * speed;
					p.vy = sa * speed;
					p.timer = 5 + Seed.randVfx() * 10;
					p.fadeLimit = 5;
					p.fadeType = 0;
					p.root.blendAdd();
					// Col.setPercentColor(p.root, 100, colour): a solid colour (the picture is white)
					p.root.setColour((Seed.randomVfx(255) << 16) | (Seed.randomVfx(255) << 8) | Seed.randomVfx(255), 0);
					p.setScale(100 + Seed.randomVfx(50));

					p.vr = (Seed.randVfx() * 2 - 1) * 12;
					// Col.setColor( p.root, 100, 0xFF0000 );
				}
			case SnakeEat:
				for (i in 0...6) {
					var p = new Phys(dm.attach("partFruit", DP_PART));

					var a = Seed.randVfx() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var speed = 0.5 + Seed.randVfx() * 3;
					if (mc.subFrame("symbol") > 5) {
						p.root.blendAdd();
						p.setScale(150 + Seed.randomVfx(150));
						speed += 1.5;
					}
					p.x = mc._x + ca * 12;
					p.y = mc._y + sa * 12;
					p.vx = ca * speed;
					p.vy = sa * speed;
					p.timer = 10 + Seed.randVfx() * 10;
					p.fadeType = 0;
					p.root.gotoAndStop(Std.int(mc.subFrame("symbol")));
					p.vr = (Seed.randVfx() * 2 - 1) * 20;
					// (Filt.glow(p.root, 3, 1, 0): baked in the pictures of partFruit)
				}
				var onde = dm.attach("partOnde", DP_PART);
				onde.blendAdd();
				onde._x = mc._x;
				onde._y = mc._y;
				#if debug
				stats.eaten++;
				#end
			case SnakeEatSuite:
		}

		//
		mc._visible = false;
	}

	// DONE - Detruire le fruit quand il commence a etre mangé appeler "destroyAnim" dans cell dans le tableau ET dans la suite
	// DONE - faire clignoter la barre quand il n'y a plus beaucoup de temps
	// DONE - le clique de retour doit marcher n'importe ou
	// - si c'est possible, jouer l'anim de retour du serpent ( rapide > 1 frame = 1 case )
	// DONE - anim de fin de tableau : couper le temps, jouer "destroyAnim" sur tous les fruits en décalé
	// DONE - quand le serpent bouge : - l'empecher de suivre la souris, assigner la bonne direction a la variable "rot"
	// DONE - quand le serpent est a l'arret : l'empecher de tourner sa tete a +- de 90° par rapport a sa direction d'origine si ca pose problème laisse moi juste l'angle de sa derniere direction prise dans une variable et je m'en occupe.
	// ---------------------------------------------------------------- port: the grid
	// grid[y][x], null out of the grid (Flash reads undefined there, grid[-1][x] included)
	public static function cellAt(x:Int, y:Int):Cell {
		if (y < 0 || y >= grid.length)
			return null;
		var row = grid[y];
		return x < 0 || x >= row.length ? null : row[x];
	}

	// trigonometry whose result changes the game: rounded to 1/65536 (the same in every browser)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}

	// ---------------------------------------------------------------- port: KadoKadeo step, 5 Flash frames every 4 steps
	public function update(delta:Float) {
		var changes = [];
		if (isReplay) {
			replayActions = [];
			for (e in KadoKadeoManager.kkm.replay.consumeEvents()) {
				var ev:Dynamic = e;
				replayActions.push((ev.k << 6) | (ev.x << 3) | ev.y);
			}
		} else {
			// _xmouse / _ymouse: the mouse of the step, in Flash pixels
			mouseX = Math.max(0, MouseManager.getX()) / Clip.K;
			mouseY = Math.max(0, MouseManager.getY()) / Clip.K;
			for (c in MouseManager.getFrameButtonChanges())
				if (c.button == MouseManager.BUTTON_LEFT)
					changes.push(c.isDown);
		}
		flashIndex = 0;
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame(changes);
			changes = [];
			flashIndex++;
		}
		MC.displayAll(frameAcc / 4);
		title.display();
		setHandCursor(!over && buttons.handCursor());
	}

	// one Flash frame: the mouse events since the last one, the timelines advance, then Manager.main (tmod ~0.8: Timer
	// settles on 32 / 40; deltaT: 1 / 40 s), then the frame scripts the code triggered
	function flashFrame(changes:Array<Bool>) {
		frameCount++;
		Timer.tmod = 32 / FLASH_FPS;
		Timer.deltaT = 1 / FLASH_FPS;
		Clip.deferring = true;
		if (isReplay) {
			var a:Null<Int>;
			while ((a = takeAction(false)) != null)
				applyAction(a);
		} else
			buttons.frame(mouseX, mouseY, changes);
		Clip.deferring = false;
		Clip.runLater();
		MC.frameStart();
		Clip.deferring = true;
		main();
		Clip.deferring = false;
		Clip.runLater();
		root.visible = true;
	}

	// ---------------------------------------------------------------- port: score, game over
	public function addScore(n:KKConst) {
		if (over)
			return;
		KadoKadeoManager.kkm.addScore(KKApi.val(n));
	}

	function gameOver() {
		if (over)
			return;
		#if debug
		untyped js.Browser.window.__over = debugState();
		#end
		KadoKadeoManager.kkm.gameOver({});
		over = true;
		setHandCursor(false);
	}

	#if debug
	public function debugState():Dynamic {
		var cells = [];
		if (grid != null)
			for (a in grid)
				for (c in a)
					cells.push(c.chained ? "x" : Std.string(c.symbol));
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			level: level,
			time: time,
			cTime: Math.round(cTime * 1000) / 1000,
			cells: cells.join(""),
			anims: anim.length,
			stats: haxe.Json.stringify(stats)
		};
	}
	#end

	// ---------------------------------------------------------------- port: replay events (see ACT_REINIT)
	// live: the action chosen by the mouse, recorded for the step being played and applied now (the follow has no
	// moment of its own: the pointer held)
	public function act(a:Int) {
		var v = a | (flashIndex > 0 ? FLASH_BIT : 0);
		var replay = KadoKadeoManager.kkm.replay;
		var follow = a >= ACT_FOLLOW && a < ACT_START;
		replay.recordEvent({k: v >> 6, x: (v >> 3) & 7, y: v & 7}, replay.getCurrentFrame(), follow ? ReplayManager.PHASE_NONE : null);
		applyAction(a);
	}

	// replay: the follow of the Flash frame (Cell.tryNeighbour)
	public function replayFollow() {
		var a = takeAction(true);
		if (a != null)
			applyAction(a);
	}

	// replay: the next action of the Flash frame being played, a follow or a click / rollOver
	function takeAction(follow:Bool):Null<Int> {
		for (i in 0...replayActions.length) {
			var v = replayActions[i];
			var a = v & (FLASH_BIT - 1);
			if ((v >= FLASH_BIT ? 1 : 0) == flashIndex && (a >= ACT_FOLLOW && a < ACT_START) == follow) {
				replayActions.splice(i, 1);
				return a;
			}
		}
		return null;
	}

	// the action, with the rules of the original's handlers (Cell.onClic / onRollOver / tryNeighbour, onRelease of bg)
	function applyAction(a:Int) {
		if (locked())
			return;
		if (a == ACT_REINIT) {
			if (suite.started()) {
				#if debug
				stats.reinits++;
				event("reinit");
				#end
				suite.reinit();
			}
			return;
		}
		if (a >= ACT_START) {
			var w = KKApi.val(width);
			var c = cellAt((a - ACT_START) % w, Std.int((a - ACT_START) / w));
			if (c != null && !suite.started() && suite.check(c)) {
				#if debug
				stats.starts++;
				event("start " + c.x + "," + c.y);
				#end
				suite.next(c);
			}
			return;
		}
		var l = suite.last();
		var n = l == null ? null : l.neighbour((a - ACT_OVER) % 4);
		if (n != null && suite.check(n)) {
			#if debug
			if (a >= ACT_FOLLOW)
				stats.tries++;
			else
				stats.rollOvers++;
			event((a >= ACT_FOLLOW ? "try " : "over ") + n.x + "," + n.y);
			#end
			suite.next(n);
		}
	}

	// ---------------------------------------------------------------- port: mouse
	// the hand cursor of the Flash buttons (live games only: the cursor of the page)
	function setHandCursor(on:Bool) {
		if (isReplay || on == handCursor)
			return;
		handCursor = on;
		var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
		if (canvas != null)
			canvas.style.cursor = on ? "pointer" : "";
	}

	// ---------------------------------------------------------------- port: display
	static function get_me():Game {
		return inst;
	}

	public function stageRoot():ASprite {
		return root;
	}

	// The first use of a filter compiles its shader (tens of ms of freeze): the glow of the title, the blur of the
	// blinking fruit and the colour matrices are drawn once now, off screen
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var holder = new Container();
		var s = new PixiSprite(Texture.WHITE);
		s.filters = [new FlashGlow(3, 3, 5, 0x995DCA), new FlashBlur(10, 10, 1), new ColorMatrixFilter()];
		holder.addChild(s);
		var rt:Dynamic = (cast RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			if (canvas != null)
				canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		setHandCursor(false);
		MC.clearAll();
		Clip.reset();
		Sprite.spriteList = [];
		time = null;
		grid = null;
		suite = null;
		if (inst == this)
			inst = null;
	}
}

// title.field (a text field in the device font Impact, 12 px, white): "NIVEAU n", glyphs drawn from the font in the
// picture of the title, under the purple glow the code puts on the title (FlashGlow on the clip)
class TitleText {
	var mc:MC;
	var glyphs:Array<PixiSprite> = [];
	var tex:Array<Texture>;
	var glow:FlashGlow;
	var shown:String = null;

	public var text:String = "";

	public function new(mc:MC) {
		this.mc = mc;
		tex = Tex.get("glyph");
		glow = new FlashGlow(3, 3, 5, 0x995DCA);
		mc.clip.filters = [glow];
	}

	// texture pixels of the title clip per Flash pixel: K (its pictures at resolution 1)
	public function display() {
		if (text == shown || mc.removed)
			return;
		shown = text;
		for (g in glyphs)
			g.destroy();
		glyphs = [];
		var x = Data.TITLE_X;
		for (i in 0...text.length) {
			var k = Data.TITLE_CHARS.indexOf(text.charAt(i));
			if (k < 0)
				continue;
			if (text.charAt(i) != " ") {
				var g = new PixiSprite(tex[k]);
				g.anchor.copyFrom(tex[k].defaultAnchor);
				g.x = x * Clip.K;
				g.y = Data.TITLE_BASE * Clip.K;
				g.tint = Data.TITLE_COLOR;
				mc.clip.addChild(g);
				glyphs.push(g);
			}
			x += Data.TITLE_ADV[k];
		}
	}
}
