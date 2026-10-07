package spiroule;

import haxe.io.UInt16Array;
import pixi.core.Pixi.BlendModes;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.textures.RenderTexture;
import pixi.filters.alpha.AlphaFilter;
import spiroule.FlashFilters.FlashBoxBlur;
import spiroule.FlashFilters.FlashCx;
import spiroule.FlashFilters.FlashGlow;
import spiroule.FlashFilters.FlashShadow;
import spiroule.MC.Plans;

enum Step {
	Play;
	GameOver;
}

// launcher of the original ({>MovieClip, ball, timer, shade, turret}): its clip (frame 1, the base under the balls),
// the ball ready to be shot, the time before the next one, the turret (mcLauncher frame 2, over the balls). (shade:
// launcherShade, see initLauncher). port: hl, the light of the turret (turret.smc, in "overlay" mode: see OverlayLayer)
typedef Launcher = {
	var mc:MC;
	var ball:Ball;
	var timer:Float;
	var turret:MC;
	var hl:MC;
}

// Game.hx of the original (Haxe for Flash 8), line by line; the port's own parts are at the end
@:expose('GameSpiroule')
class Game implements kado.GameInterface {
	// Flash played Spiroule at 40 frames/s (the rate of the KadoKado loader that plays the game SWF) with
	// Timer.wantedFPS = 32
	public static inline var FLASH_FPS = 40;

	// (false in the released game: -D prod)
	public static var FL_TEST = false;
	public static var DP_FX = 3;
	public static var DP_LAUNCHER = 2;
	public static var DP_BALL = 1;
	public static var DP_BG = 0;
	public static var ANGLE_DECAL = -130; // DECALLAGE DU GFX CANON

	public var flStart:Bool;
	public var step:Step;
	public var colorMax:Int;
	public var speed:Float;
	public var lastPos:Float;
	public var animCoef:Float;
	public var black:Int;
	public var chains:Array<Chain>;
	public var balls:Array<Ball>;
	public var shots:Array<Ball>;
	public var bgrid:Array<Array<Array<Ball>>>;
	public var launcher:Launcher;
	public var mcMagnet:MC;

	public static var me:Game;

	public var dm:Plans;
	public var bdm:Plans;
	public var root:ASprite;
	public var bg:MC;

	// ---------------------------------------------------------------- port
	var isReplay:Bool;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	// mt.Timer.tmod of the Flash player (see flashFrame)
	var tmod:Float = 1;
	// the score of KKApi, nothing after the game over
	var over:Bool = false;
	// the planes under DP_FX, drawn together under the clips in "overlay" mode
	var low:ASprite;
	var ovl:OverlayLayer;

	// the planes of the clips in blendMode "overlay": the light of the turret, the sparks (Ball.fxPart)
	var hdm:Plans;

	public var odm:Plans;

	// mcMulti clips (their blur, see updateMultis)
	var multis:Array<{mc:MC, blur:FlashBoxBlur}> = [];

	// mcMagnet's drawing (Ball.fxLink), and whether something was drawn in this Flash frame
	public var magnet:Graphics;

	var magnetOn:Bool = false;

	// the mouse in Flash pixels (bg._xmouse, bg._ymouse), where the launcher aimed at its last update
	var mouseX:Float = 0;
	var mouseY:Float = 0;
	var aimX:Float = Math.NaN;
	var aimY:Float = Math.NaN;
	// bg.onPress = shoot (a ball is ready); a press not given to the game yet, the Flash frames it still waits
	var bgPress:Bool = false;
	var pressPending:Bool = false;
	var pressWait:Int = 0;
	var handCursor:Bool = false;
	var onPointerDown:Dynamic;
	#if debug
	// test harness: what the game went through (window.__over)
	public var stats = {
		shots: 0,
		inserts: 0,
		combos: 0,
		maxCombo: 0,
		blackOut: 0,
		blackKick: 0,
		splits: 0,
		joins: 0,
		maxChains: 0
	};
	#end

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		var buttonsRec = new UInt16Array(1);
		buttonsRec[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: buttonsRec,
		});
		// statics of the original (the SWF was loaded again for every game)
		MC.clearAll();
		Clip.reset();
		Sprite.spriteList = [];
		// mt.Timer before its first update (Manager.init creates the game before the first Manager.main)
		Timer.tmod = 1;
		Clip.deferring = true;
		// like the Flash player, a press keeps the mouse while the button is held (KadoKadeo releases the buttons when
		// the pointer leaves the canvas)
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			onPointerDown = function(e:Dynamic) {
				try {
					canvas.setPointerCapture(e.pointerId);
				} catch (_:Dynamic) {}
			};
			canvas.addEventListener("pointerdown", onPointerDown);
		}

		Cs.init();
		// the original's 300x300 pixels, drawn x2
		root = mc.createEmptyMovieClip("scene", 0);
		root._xscale = root._yscale = 100 * Clip.K;
		root.updateState();
		me = this;
		low = new ASprite();
		root.addChild(low);
		dm = new Plans(root, null, low, DP_FX);
		ovl = new OverlayLayer(low);
		hdm = new Plans(ovl.add(root));
		odm = new Plans(ovl.add(root));
		initBg();
		initGfxTable();
		speed = Cs.SPEED_START;
		colorMax = 4;
		black = 10000000;
		step = Play;
		//
		var mcBalls = dm.empty(DP_BALL);
		bdm = new Plans(mcBalls.clip, mcBalls);
		var fl = new FlashShadow();
		// DropShadowFilter: blurX = blurY = 4, alpha 0.5, color 0, distance 4, angle 135 (strength 1, quality 1)
		fl.set(4, 135, 0, 0.5, 4, 1, 1);
		mcBalls.clip.filters = [fl];
		// LIST
		balls = [];
		chains = [];
		shots = [];
		bgrid = [];
		for (x in 0...Cs.GXMAX) {
			bgrid[x] = [];
			for (y in 0...Cs.GYMAX)
				bgrid[x][y] = [];
		}
		//
		mcMagnet = dm.empty(DP_FX);
		magnet = new Graphics();
		mcMagnet.clip.addChild(magnet);
		// Filt.glow(mcMagnet, 2, 1, 0xFFFFFF), Filt.glow(mcMagnet, 20, 1, 0xFFFF00), blendMode "add": the glows in a
		// row, the result added to the picture (the last filter draws it in "add" mode)
		var g1 = new FlashGlow();
		g1.set(2, 1, 0xFFFFFF, 1);
		var g2 = new FlashGlow();
		g2.set(20, 1, 0xFFFF00, 1);
		var add = new AlphaFilter(1);
		add.blendMode = BlendModes.ADD;
		mcMagnet.clip.filters = [g1, g2, add];
		initLauncher();
		var c = new Chain();
		c.pos = 1.1;
		for (i in 0...Cs.START_CHAIN_LENGTH)
			c.addBall();
		//
		flStart = true;
		// PARTS
		for (i in 0...120) {
			var p = new Runner();
			p.pos = 1.3;
			p.speed = -(0.5 + Seed.randVfx() * 3.2) * 0.005;
			p.frict = 0.99;
			p.timer = 20 + Seed.randVfx() * 80;
			p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
			p.setScale(40 + Seed.randVfx() * 60);
			// (Filt.glow(p.root, 10, 2, 0xFFFFFF): drawn by Spark)
			p.fadeType = 0;
		}

		Clip.deferring = false;
		Clip.runLater();
		MC.displayAll(1);
		// Flash shows the first picture after the first frame (Manager.init, then Manager.main)
		root.visible = false;
		warmShaders();
	}

	// port: the textures of the balls (mcBallTexture drawn into 5 x 48 BitmapData of 24 x 24) are pictures of the sheet
	// "spirouleb" (anims tex0..tex4), drawn by the asset pipeline like Flash drew them
	function initGfxTable() {}

	// the original update(), one Flash frame
	function main() {
		animCoef = Math.min(Ball.ANIM_COEF * Timer.tmod, 1);
		magnet.clear();
		magnetOn = false;
		switch (step) {
			case Play:
				updatePlay();
			case GameOver:
				updateGameOver();
		}
		updateSprites();
		mcMagnet.clip.visible = magnetOn;
		// (chains.cheat || balls.cheat || shots.cheat: the anti-cheat of mt.flash.PArray, KKApi.flagCheater)
	}

	// BG
	function initBg() {
		bg = dm.attach("mcBg", DP_BG);
		for (i in 0...10) {
			if (i % 2 == 1) {
				// (mcLoupiotes with _fr = i == 9 ? 2 : 1 and blendMode "overlay": the light of each position drawn over the
				// decor by the asset pipeline, clips mcLoupiotes0..4)
				var mc = dm.attach("mcLoupiotes" + Std.int(i / 2), DP_BG);
				mc._x = i * 9.5 - 1;
				mc._y = 253;
				mc.gotoAndPlay(16 - (i * 2) % 15);
			}
		}
	}

	// PLAY
	function updatePlay() {
		speed += Cs.SPEED_INC * Timer.tmod;
		var v = speed * 10000;
		if (v > 4)
			black = 8;
		if (v > 8)
			black = 6;
		if (v > 16)
			black = 5;
		if (v > 30)
			black = 4;
		updateChains();
		updateShots();
		updateLauncher();
	}

	function updateSprites() {
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.update();
	}

	// LAUNCHER
	function initLauncher() {
		// launcherShade (DP_BALL - 1, _alpha 40, blendMode "layer", blurred): updateLauncher sets its _alpha to 0 before
		// the first picture, it is never seen
		var mc = dm.attach("mcLauncher", DP_BALL - 1);
		mc._x = Cs.SPX;
		mc._y = Cs.SPY;
		mc.stop();
		var turret = dm.attach("mcLauncher", DP_LAUNCHER);
		turret.gotoAndStop(2);
		turret._x = Cs.SPX;
		turret._y = Cs.SPY;
		// turret.smc (GlowFilter(5, 5, white), blendMode "overlay"): moved with the turret
		var hl = hdm.attach("turretHl", 0);
		hl._x = Cs.SPX;
		hl._y = Cs.SPY;
		hl._alpha = 39.84;
		launcher = {
			mc: mc,
			ball: null,
			timer: 0,
			turret: turret,
			hl: hl
		};
	}

	function updateLauncher() {
		// ROTATION
		var dx = mouseX - Cs.SPX;
		var dy = mouseY - Cs.SPY;
		var a = Cs.q(Math.atan2(dy, dx));
		aimX = mouseX;
		aimY = mouseY;
		// (the rotation read back is in ]-180, 180]: shoot gets the angle back from it)
		launcher.mc._rotation = a / 0.0174 + ANGLE_DECAL;
		launcher.turret._rotation = launcher.mc._rotation;
		launcher.hl._rotation = launcher.turret._rotation;
		launcher.hl._alpha = 80 - Math.abs(Cs.hMod(a + 0.77, 3.14)) * 30;
		var dist = 8;
		// (no ball ready: fields of null in Flash, nothing)
		if (launcher.ball != null) {
			launcher.ball.x = Cs.SPX + Cs.q(Math.cos(a)) * dist;
			launcher.ball.y = Cs.SPY + Cs.q(Math.sin(a)) * dist;
			launcher.ball.updatePos();
			launcher.ball.root.setSub("smc", null, null, null, null, launcher.mc._rotation);
		}
		// BALL
		if (launcher.ball == null) {
			launcher.timer -= Timer.tmod;
			if (launcher.timer < 0) {
				launcher.timer = Cs.CADENCE;
				launcher.ball = new Ball();
				launcher.ball.x = Cs.SPX;
				launcher.ball.y = Cs.SPY;
				launcher.ball.updatePos();
				bgPress = true;
			}
		}
	}

	function shoot() {
		var bs = Cs.LAUNCH_SPEED;
		var b = launcher.ball;
		launcher.ball = null;
		shots.push(b);
		var a = (launcher.mc._rotation - ANGLE_DECAL) * 0.0174;
		b.vx = Cs.q(Math.cos(a)) * bs;
		b.vy = Cs.q(Math.sin(a)) * bs;
		bgPress = false;
		launcher.turret.sub("gfx").gotoAndPlay(2);
		launcher.mc.sub("smc").gotoAndPlay(2);
		#if debug
		stats.shots++;
		#end
	}

	function updateShots() {
		// (for (b in shots): the length is read at each turn, a ball inserted or killed makes the next one wait a frame;
		// a black ball kicked out is updated in this frame)
		var i = 0;
		while (i < shots.length) {
			var b = shots[i];
			i++;
			b.update();
		}
	}

	// CHAINS
	function updateChains() {
		var lch = chains[0];
		if (lch == null) {
			lch = new Chain();
			lch.pos = 1.1;
			lch.vit = speed;
		}
		lastPos = lch.pos - lch.list.length * Cs.ec;
		var a = chains.copy();
		for (ch in a)
			ch.update();
		for (ch in a)
			if (ch.cci != null) {
				ch.checkCombo(ch.cci);
				ch.cci = null;
			}
		#if debug
		if (chains.length > stats.maxChains)
			stats.maxChains = chains.length;
		#end
	}

	// DANGER
	public function danger() {
		var s = bg.sub("smc");
		if (s != null)
			s.play();
	}

	// GAMEOVER
	public function initGameOver() {
		step = GameOver;
	}

	function updateGameOver() {
		if (chains == null)
			return;
		var chain = chains[0];
		// (no chain: undefined in Flash, nothing until the test of the length)
		if (chain != null) {
			var ball = chain.list.shift();
			if (ball != null)
				ball.collapse();
			if (chain.list.length == 0)
				chain.kill();
		}
		if (chains.length == 0) {
			chains = null;
			gameOver();
		}
	}

	// ---------------------------------------------------------------- port
	// bgrid[x][y] (out of the grid: undefined in Flash)
	public inline function cell(x:Null<Int>, y:Null<Int>):Array<Ball> {
		return x != null && y != null && x >= 0 && x < Cs.GXMAX && y >= 0 && y < Cs.GYMAX ? bgrid[x][y] : null;
	}

	// KKApi.addScore
	public function addScore(n:Int) {
		if (!over)
			KadoKadeoManager.kkm.addScore(n);
	}

	public function magnetUsed() {
		magnetOn = true;
	}

	// Filt.glow(mcMulti, 4, 6, colour): until the frame script `filters = []` (frame 14)
	public function glowMulti(mc:MC, color:Int) {
		var g = new FlashGlow();
		g.set(4, 6, color, 1);
		mc.clip.filters = [g];
		multis.push({mc: mc, blur: null});
		#if debug
		stats.combos++;
		#end
	}

	// the BlurFilter of mcMulti.smc on its frames 14..25 (the multiplier blurs while it fades)
	function updateMultis() {
		var i = 0;
		while (i < multis.length) {
			var m = multis[i];
			if (m.mc.removed || m.mc.clip.selfRemoved) {
				multis.splice(i, 1);
				continue;
			}
			i++;
			var smc = m.mc.clip.get("smc");
			var f = m.mc.clip.frame;
			var b = f >= 1 && f <= Data.MULTI_BLUR.length ? Data.MULTI_BLUR[f - 1] : 0.0;
			if (smc == null)
				continue;
			if (b > 0) {
				if (m.blur == null)
					m.blur = new FlashBoxBlur();
				m.blur.set(b, 1);
				if (smc.filters == null)
					smc.filters = [m.blur];
			} else if (smc.filters != null) {
				smc.filters = null;
			}
		}
	}

	// ---------------------------------------------------------------- KadoKadeo step: 5 Flash frames every 4 steps
	public function update(delta:Float) {
		pollMouse();
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame();
		}
		MC.displayAll(frameAcc / 4);
		updateMultis();
		setHandCursor(bgPress && !over);
	}

	// one Flash frame: the press on bg (an event between two frames), the timelines advance, then Manager.main
	// (mt.Timer.update, then the original update), then the frame scripts the code triggered
	function flashFrame() {
		if (pressPending) {
			// a press waits for the launcher to aim at it (a finger lands where it presses: Flash had followed the mouse
			// there before the click)
			if (pressWait > 0) {
				pressWait--;
			} else {
				pressPending = false;
				if (bgPress) {
					Clip.deferring = true;
					shoot();
					Clip.deferring = false;
					Clip.runLater();
				}
			}
		}
		MC.frameStart();
		// mt.Timer.update at 40 frames/s: tmod = tmod * 0.95 + 0.05 * deltaT * 32, from 1 towards 0.8
		tmod = tmod * 0.95 + 0.05 * (1 / FLASH_FPS) * 32;
		Timer.tmod = tmod;
		Clip.deferring = true;
		main();
		Clip.deferring = false;
		Clip.runLater();
		frameCount++;
		root.visible = true;
	}

	// The mouse: bg._xmouse / _ymouse (bg at the origin of the stage) and its press (bg.onPress), polled once per step
	// (the replay records them)
	function pollMouse() {
		mouseX = Math.max(0, MouseManager.getX()) / Clip.K;
		mouseY = Math.max(0, MouseManager.getY()) / Clip.K;
		for (c in MouseManager.getFrameButtonChanges())
			if (c.button == MouseManager.BUTTON_LEFT && c.isDown) {
				pressPending = true;
				pressWait = mouseX == aimX && mouseY == aimY ? 0 : 1;
			}
	}

	// bg.useHandCursor
	function setHandCursor(on:Bool) {
		if (isReplay || on == handCursor)
			return;
		handCursor = on;
		var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
		if (canvas != null)
			canvas.style.cursor = on ? "pointer" : "";
	}

	// KKApi.gameOver
	function gameOver() {
		if (over)
			return;
		#if debug
		untyped js.Browser.window.__over = debugState();
		#end
		KadoKadeoManager.kkm.gameOver({});
		over = true;
	}

	#if debug
	public function debugState():Dynamic {
		var sx = 0.0;
		for (b in balls)
			sx += b.x + b.y * 0.001;
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			speed: Math.round(speed * 1e9),
			black: black,
			balls: balls.length,
			chains: chains == null ? -1 : chains.length,
			shots: shots.length,
			sx: Math.round(sx * 1000),
			stats: haxe.Json.stringify(stats)
		};
	}
	#end

	public function stageRoot():ASprite {
		return root;
	}

	// The first use of a filter compiles its shader (tens of ms of freeze): the filters of the game are drawn once now,
	// off screen
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var holder = new Container();
		var s = new pixi.core.sprites.Sprite(pixi.core.textures.Texture.WHITE);
		var cx = new FlashCx();
		cx.set([1, 1, 1, 10, 10, 10]);
		var gl = new FlashGlow();
		gl.set(2, 2, 0xFFFFFF, 1);
		var sh = new FlashShadow();
		sh.set(4, 135, 0, 0.5, 4, 1, 1);
		var bl = new FlashBoxBlur();
		bl.set(3, 1);
		var add = new AlphaFilter(1);
		add.blendMode = BlendModes.ADD;
		s.filters = [cx, gl, sh, bl, add];
		holder.addChild(s);
		var rt:Dynamic = (cast RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
		ovl.warm();
	}

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			if (canvas != null)
				canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		setHandCursor(false);
		if (ovl != null)
			ovl.dispose();
		me = null;
		MC.clearAll();
		Clip.reset();
		Sprite.spriteList = [];
	}
}
