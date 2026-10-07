package phagocytoz;

import haxe.io.UInt16Array;
import kado.ReplayManager;
import common_haxe_avm1.display.ASprite;
import phagocytoz.cell.Hero;
import phagocytoz.cell.Hunter;
import phagocytoz.cell.Neutral;
import phagocytoz.cell.Survivor;

enum GameStep {
	PLAY;
	GAMEOVER;
	TITLE;
	FADE(sens:Int);
}

/**
 * Phagocytoz (KadoKado, archive folder Fragocytoz): Haxe 2 for Flash 9 (AS3), 30 frames/s. The mouse steers the
 * hero cell, a press pushes it towards the mouse; eat the smaller cells, avoid the bigger hunters; a phase ends when
 * the hero is the last cell.
 */
@:expose('GamePhagocytoz')
class Game implements kado.GameInterface {
	// Phagocytoz played at 30 Flash frames/s (the KadoKado AS3 loader, loader9.swf)
	public static inline var FLASH_FPS = 30;
	// the original's 300 x 300 pixels, drawn x2
	public static inline var K = 2;

	public static var mcw = 300;
	public static var mch = 300;

	public static var BASE_RAY = 9;

	public var elements:Array<Element>;
	public var cells:Array<Cell>;
	public var hero:Cell;

	public var lvl:Level;
	public var dif:Int;
	public var timer:Int;
	public var pink:Rect;

	public var click:Bool;
	public var step:GameStep;

	public var dm:DepthManager;
	public var root:MovieClip;

	public static var me:Game;

	// port
	var isReplay:Bool;
	var stage:ASprite;
	// Flash frames owed, in 16ths of a step (15 per step)
	var frameAcc:Int = 16;
	var frameCount:Int = 0;
	var over:Bool = false;
	var mouseWasDown:Bool = false;
	var onPointerDown:Dynamic->Void = null;
	#if debug
	// test harness: errors the Flash player would have swallowed, events of the game
	public var flashErrors:Array<String> = [];
	public var stats = {
		eaten: 0,
		phases: 0,
		cellsLeft: 0
	};
	#end

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		// the mouse is not recorded (long games): only the push, as events (readControls)
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});
		// one page plays several games and replays: the statics start again
		resetStatics();
		// the root of the display list (flash.Lib.current), drawn x2
		stage = mc.createEmptyMovieClip("scene", 0);
		stage._xscale = stage._yscale = 100 * K;
		stage.updateState();
		var r = new MovieClip(-1);
		stage.addChild(r.view);
		// like the Flash player, a pressed button keeps the mouse until it is released (KadoKadeo releases the buttons
		// when the pointer leaves the canvas)
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			onPointerDown = function(e:Dynamic) {
				try {
					canvas.setPointerCapture(e.pointerId);
				} catch (_:Dynamic) {}
			};
			canvas.addEventListener("pointerdown", onPointerDown);
		}
		init(r);
		// Manager.init, then the loader calls Manager.main at once: the first frame, with no playhead moved
		flashFrame(false);
		display(1);
		warmShaders();
	}

	function resetStatics() {
		Sprite.resetAll();
		MovieClip.resetAll();
		me = null;
		mt.Timer.tmod = 1;
	}

	// the original's constructor
	function init(mc:MovieClip) {
		me = this;
		root = mc;
		dm = new DepthManager(root);

		initBg();

		// BUT (its MOUSE_DOWN / MOUSE_UP: pollMouse)
		var but = new Rect(0, 0, mcw, mch, 0, 0);
		dm.add(but, 15);

		// pink
		pink = new Rect(0, 0, mcw, mch, 0xFF00FF);
		dm.add(pink, 5);
		pink.visible = false;
		pink.alpha = 0;
		pink.blendMode = "add";

		//
		elements = [];

		dif = 0;
		teq = 0;

		setTitle();
	}

	var bg:Sprite;

	public var bgScroller:Sprite;

	public function initBg() {
		bg = new Sprite();

		bgScroller = new Sprite();
		bgScroller.x = mcw * 0.5;
		bgScroller.y = mch * 0.5;
		bgScroller.addChild(bg);

		dm.add(bgScroller, 0);

		// the brush (a 0x1C1D42 rectangle of 600 x 600 and McBg 3 x 3) drawn x2 into a BitmapData of 1200 x 1200 shown at
		// 1 / 2: baked by the asset script (BG)
		var sc = 2;
		var bmc = new MovieClip.Bitmap("BG");
		bmc.scaleX = 1 / sc;
		bmc.scaleY = 1 / sc;
		bg.addChild(bmc);
	}

	public function updateBg() {
		if (hero == null)
			return;
		var c = 0.2;
		bg.x -= hero.vx * c;
		bg.y -= hero.vy * c;
		// (McBg every mcw x mch: a jump of a tile shows the same picture)
		bg.moveWrapped(Num.sMod(bg.x + mcw * 1.5, mcw) - mcw * 1.5, Num.sMod(bg.y + mch * 1.5, mch) - mch * 1.5, mcw, mch);
	}

	// (bgCell: another background of the original, never called)

	public function mouseDown(e:Dynamic) {
		click = true;
	}

	public function mouseUp(e:Dynamic) {
		click = false;
	}

	// LEVEL
	public function initPlay() {
		mouseUp(null);
		step = PLAY;
		timer = 0;
		//
		var dd = dif;
		if (dif > 5)
			dd = 5;

		// LEVEL
		if (lvl != null)
			lvl.kill();
		lvl = new Level();
		dm.add(lvl, 1);
		cells = [];

		// HERO
		hero = new Hero(BASE_RAY);
		hero.vx = 0;
		hero.vy = 0;
		lvl.focus = hero;

		// HERO GUARDS
		var max = 7 - dd;
		var dst = 70;
		for (i in 0...max) {
			var a = i / max * 6.28;
			var c = new Neutral(BASE_RAY * 0.7);
			c.x = hero.x + Num.q(Math.cos(a)) * dst;
			c.y = hero.y + Num.q(Math.sin(a)) * dst;
		}

		// CELLS
		var max = 150 - dif * 3;
		if (max < 50)
			max = 50;

		for (i in 0...max) {
			var ray = BASE_RAY * 0.7 + Num.q(Math.pow(1 - i / max, 10 - dd)) * (150 - dd * 10);
			new Neutral(ray);
		}

		// ALIENS
		for (i in 0...40)
			new Survivor(BASE_RAY * 0.75);

		var max = Std.int(Math.pow(2, dd + 1));
		for (i in 0...max)
			new Hunter(BASE_RAY * 0.8);
	}

	var coef:Float;
	var teq:Float;

	// the original's update(): Manager.main, once per Flash frame (mt.Timer.tmod: about 32 / 30 at 30 frames/s, the
	// fraction dropped by int(teq * 5) / 5: one updateGame per frame; tmod is 1 here)
	function origUpdate() {
		teq += mt.Timer.tmod;

		var mod = 5;
		teq = Std.int(teq * mod) / mod;

		var max = 3;
		while (teq > 0) {
			teq--;
			updateGame();
			if (max-- == 0)
				teq = 0;
		}
	}

	public function updateGame() {
		if (pink.alpha > 0) {
			pink.alpha *= 0.95;
			pink.visible = true;
			if (pink.alpha < 0.01) {
				pink.alpha = 0;
				pink.visible = false;
			}
		}

		switch (step) {
			case FADE(sens):
				fader.alpha = Num.mm(0, fader.alpha + sens * 0.1, 1);
				if (fader.alpha == 1) {
					fader.visible = false;
					setTitle();
				}
				if (fader.alpha == 0) {
					fader.visible = false;
					step = PLAY;
				}

				updatePlay();

			case TITLE:
				timer++;
				if (timer == 50) {
					initPlay();
					title.play();
				}

			case PLAY:
				updatePlay();
				if (cells.length == 1)
					finish();
				else if (hero.dead)
					gameover();

			case GAMEOVER:
				updatePlay();
		}

		// CELLS (mt.bumdum9.Sprite.spriteList: the game creates none)

		// ELEMENTS
		var a = elements.copy();
		for (sp in a)
			sp.update();
	}

	function updatePlay() {
		timer++;
		var a = cells.copy();
		for (c in a)
			c.update();
		updateCellCols();
		if (lvl != null)
			lvl.scroll();
		updateBg();
	}

	// FADE
	var fader:Rect;

	function finish() {
		dif++;
		#if debug
		stats.phases++;
		#end
		fade(1);
	}

	function fade(sens:Int) {
		step = FADE(sens);
		if (fader == null) {
			fader = new Rect(0, 0, mcw, mch, 0);
			dm.add(fader, 9);
		}
		fader.visible = true;
		fader.alpha = 1;
		if (sens == 1)
			fader.alpha = 0;
	}

	var title:Gfx.McTitle;

	function setTitle() {
		step = TITLE;
		title = new Gfx.McTitle();
		title.phase.field.text = "phase #" + (dif + 1);
		title.addFrameScript(36, endTitle);
		dm.add(title, 2);
		timer = 0;
	}

	function endTitle() {
		title.parent.removeChild(title);
		fade(-1);
	}

	// GAMEOVER
	public function gameover() {
		step = GAMEOVER;
		// KKApi.gameOver({})
		if (!over) {
			over = true;
			#if debug
			untyped js.Browser.window.__over = debugState();
			#end
			KadoKadeoManager.kkm.gameOver({});
		}
	}

	// PLAY
	public function updateCellCols() {
		var a = cells.copy();
		for (i in 0...a.length) {
			var c = a[i];
			for (n in (i + 1)...a.length)
				c.checkCols(a[n]);
			c.updatePos();
		}
	}

	// ================================================================ port
	// KKApi.addScore: nothing after the end of the game
	public function addScore(v:KKConst) {
		if (over)
			return;
		KadoKadeoManager.kkm.addScore(KKApi.val(v));
		#if debug
		stats.eaten++;
		#end
	}

	// the first use of a filter compiles its shader (a frozen frame): the blur and glows of the title, the glows of the
	// arrow and of the scores, the additive pictures, drawn once now
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var holder = new pixi.core.display.Container();
		var t = Tex.get("S10")[0];
		var a = new pixi.core.sprites.Sprite(t);
		a.filters = [new FlashFilter(4, 4, 1, false)];
		holder.addChild(a);
		var b = new pixi.core.sprites.Sprite(t);
		var gl = new FlashFilter(4, 4, 1, true, 0xFFFFFF, 0.5);
		gl.blendMode = pixi.core.Pixi.BlendModes.ADD;
		b.filters = [gl];
		holder.addChild(b);
		var d = new pixi.core.sprites.Sprite(t);
		d.blendMode = pixi.core.Pixi.BlendModes.ADD;
		holder.addChild(d);
		var rt:Dynamic = (cast pixi.core.textures.RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	// a step of KadoKadeo (32 per second): the push, then 15 Flash frames every 16 steps, then the picture one Flash
	// frame late
	public function update(delta:Float) {
		if (isReplay) {
			for (e in KadoKadeoManager.kkm.replay.consumeEvents()) {
				var ev:Dynamic = e;
				applyControl((ev.k << 6) | (ev.x << 3) | ev.y);
			}
		} else
			readControls();
		frameAcc += 15;
		while (frameAcc >= 16) {
			frameAcc -= 16;
			flashFrame();
		}
		display(frameAcc / 16);
	}

	// one Flash frame: the playheads move, then Manager.main (tmod 1), the frame scripts, then the state shown
	function flashFrame(advance:Bool = true) {
		Sprite.clearGhosts();
		DisplayObject.flashFrame++;
		mt.Timer.tmod = 1;
		mt.Timer.deltaT = 1 / FLASH_FPS;
		if (advance)
			MovieClip.advanceAll(root);
		try {
			origUpdate();
		} catch (e:FlashError) {
			// the Flash player stops the code of the frame and goes on with the next one
			#if debug
			flashErrors.push(frameCount + ": " + e.msg);
			#end
		}
		try {
			MovieClip.runScripts();
		} catch (e:FlashError) {
			#if debug
			flashErrors.push(frameCount + ": " + e.msg);
			#end
		}
		root.snapshotTree();
		frameCount++;
		#if debug
		if (frameCount % 15 == 0 || over)
			untyped js.Browser.window.__state = debugState();
		#end
	}

	// ---------------------------------------------------------------- controls (replay events)
	// The mouse counts only by the push: `click`, and the direction of the mouse from the hero while it is on (Hero.update).
	// Recorded as events of one byte (packed {k, x, y}) for the step being played, applied on the same step:
	// 0 = release, v >= 1 = pushing, the direction (DIRS directions) changed by unzig(v - 1). Live and replay push in the
	// recorded direction (at most 180 / DIRS degrees off the mouse).
	public static inline var DIRS = 255;

	// the push direction (0..DIRS - 1) and its angle (radians)
	var pushDir:Int = 0;

	public var pushAngle(default, null):Float = 0;
	// the direction the arrow shows (a picture only): live, the mouse; replay, the push
	public var aimAngle(default, null):Float = 0;

	// live: the MOUSE_DOWN / MOUSE_UP events of `but` (the 300 x 300 transparent button over the game): the changes of
	// the button over it; a button released out of it gives no MOUSE_UP (Flash: the hero keeps pushing until the next
	// press). The direction: the mouse in the hero's picture, as it was placed at the end of the last frame
	// (sprite.mouseX / mouseY).
	function readControls() {
		var down = MouseManager.isButtonDown(MouseManager.BUTTON_LEFT);
		var over = mouseX() < mcw && mouseY() < mch;
		var want = click;
		if (down && !mouseWasDown && over)
			want = true;
		else if (!down && mouseWasDown && over)
			want = false;
		mouseWasDown = down;

		var dir = pushDir;
		if (hero != null && !hero.dead) {
			var m = hero.sprite.globalToLocal(mouseX(), mouseY());
			aimAngle = Math.atan2(m.y, m.x);
			dir = Std.int(Math.round(aimAngle / (Math.PI * 2) * DIRS));
			dir = ((dir % DIRS) + DIRS) % DIRS;
		}

		if (!want) {
			if (click)
				sendControl(0, null);
			return;
		}
		var d = (((dir - pushDir) % DIRS) + DIRS) % DIRS;
		if (d > DIRS >> 1)
			d -= DIRS;
		// (a press: the moment of the input; a turn: a continuous aim, no moment)
		if (!click || d != 0)
			sendControl(d >= 0 ? d * 2 + 1 : -d * 2, click ? ReplayManager.PHASE_NONE : null);
	}

	function sendControl(v:Int, phase:Null<Int>) {
		var replay = KadoKadeoManager.kkm.replay;
		replay.recordEvent({k: v >> 6, x: (v >> 3) & 7, y: v & 7}, replay.getCurrentFrame(), phase);
		applyControl(v);
	}

	function applyControl(v:Int) {
		if (v == 0) {
			mouseUp(null);
			return;
		}
		var n = v - 1;
		var d = (n & 1) == 0 ? n >> 1 : -((n + 1) >> 1);
		pushDir = (((pushDir + d) % DIRS) + DIRS) % DIRS;
		pushAngle = Num.q(pushDir * Math.PI * 2 / DIRS);
		if (isReplay)
			aimAngle = pushAngle;
		mouseDown(null);
	}

	function display(f:Float) {
		root.syncTree(f, [1, 1, 1], [0, 0, 0, 0], false, false, false);
		root.applyView(f, false, false);
	}

	// the root of the PIXI picture (x2)
	public function stageView():ASprite {
		return stage;
	}

	// the stage's mouseX / mouseY (300 x 300)
	public static function mouseX():Float {
		return Math.max(0, MouseManager.getX()) / K;
	}

	public static function mouseY():Float {
		return Math.max(0, MouseManager.getY()) / K;
	}

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		resetStatics();
		if (stage != null && stage.parent != null)
			stage.parent.removeChild(stage);
	}

	#if debug
	function debugState():Dynamic {
		var sx = 0.0;
		var sr = 0.0;
		if (cells != null)
			for (c in cells) {
				sx += c.x * 7 + c.y;
				sr += c.ray;
			}
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			dif: dif,
			timer: timer,
			step: Std.string(step),
			hx: hero != null ? hero.x : 0,
			hy: hero != null ? hero.y : 0,
			hray: hero != null ? Math.round(hero.ray * 1e6) / 1e6 : 0,
			cells: cells != null ? cells.length : 0,
			csum: Math.round(sx * 1000) / 1000,
			rsum: Math.round(sr * 1000) / 1000,
			scale: lvl != null ? lvl.scale : 0,
			over: over,
			errors: flashErrors.length,
			stats: haxe.Json.stringify(stats)
		};
	}
	#end
}
