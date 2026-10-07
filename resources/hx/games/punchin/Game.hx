package punchin;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchButtonShape;
import kado.TouchControlsConfig.TouchControlsMode;
import punchin.MC.Plans;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

enum Step {
	Intro;
	Play;
	GameOver;
}

// Game.hx of the original (Haxe for Flash 8), line by line; the port's own parts are at the end
@:expose('GamePunchIn')
class Game implements kado.GameInterface {
	// left / right dodge (held), the round button punches
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "left",
				label: "◀",
				leftPx: 20,
				bottomPx: 30,
				size: 84,
				keyCode: KeyboardManager.LEFT,
				shape: TouchButtonShape.SQUARE,
			},
			{
				id: "right",
				label: "▶",
				leftPx: 116,
				bottomPx: 30,
				size: 84,
				keyCode: KeyboardManager.RIGHT,
				shape: TouchButtonShape.SQUARE,
			},
			{
				id: "punch",
				label: "👊",
				rightPx: 24,
				// (above the endurance gauge)
				bottomPx: 124,
				size: 96,
				keyCode: KeyboardManager.SPACE,
			},
		],
	};

	// ZQSD / WASD move like the arrows, Enter = Space
	public static var KEY_ALIASES = KeyboardManager.ALIASES_MOVE.concat(KeyboardManager.ALIASES_ENTER_SPACE);

	// Flash played Punch-In at 40 frames/s (the rate of the SWF and of the KadoKado loader) with Timer.wantedFPS = 32
	public static inline var FLASH_FPS = 40;

	var step:Step;

	public static var boxer:Boxer;
	public static var afro:Afro;

	// flash.Lib._global.bonusCol: 1 no bonus, 2 green, 3 blue, 4 red (the next punch that lands gives its points)
	public static var bonusCol:Int = 1;

	var zC:Float;
	// (undefined until the first hit of the original: false)
	var isMoovin:Bool = false;
	var goSta:Bool;
	var flBonus:Bool;
	var flCol:Bool;

	var zFinishx:Float;
	var zStartx:Float;
	var staInc:Float;

	var sTime:Float;

	public static var DP_BG = 0;
	public static var DP_AFRO = 1;
	public static var DP_PLAYER = 2;
	public static var DP_GUI = 6;
	public static var DP_MSG = 10;

	static var BONUSVERT = 200000;
	static var BONUSBLEU = 360000;
	static var BONUSROUGE = 470000;

	static var BONUSMAX = 500000;
	static var BONUS = 20000;

	var bonusCool:Float;
	var endBonus:Float;
	var fall:Float;

	public static var me:Game;

	public var dm:Plans;
	public var root:ASprite;
	public var bg:MC;
	public var st:StaminaMC;

	public var stats:{_p:Array<Int>, _t:Array<Int>, _g:Array<Int>};

	var mcChrono:ChronoMC;
	var message:TextMC;
	var msgTimer:Float;
	var flMsg:Bool;

	// (undefined until a bonus of a colour: the bonus without colour blinks the player with nothing, see update)
	var currentCol:Int = 0;

	// ---------------------------------------------------------------- port
	var isReplay:Bool;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	// flash.Lib.getTimer(): 25 ms per Flash frame played (the chrono of the original counts the real time)
	var flashTime:Float = 0;
	// the score of KKApi, nothing after the game over
	var over:Bool = false;
	#if debug
	// test harness: events of the game (coverage)
	public var dbg = {
		hits: 0,
		misses: 0,
		ouch: 0,
		counters: 0,
		maxCombo: 0,
		bonus0: 0,
		bonus1: 0,
		bonus2: 0,
		bonusShown: 0,
		autoDef: 0,
		afroAtk: 0,
		afroDef: 0,
		counterAtk: 0,
		msgs: 0,
		endBy: ""
	};
	#end

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		var keys = new UInt16Array(3);
		keys[0] = KeyboardManager.LEFT;
		keys[1] = KeyboardManager.RIGHT;
		keys[2] = KeyboardManager.SPACE;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: keys,
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});
		MC.clearAll();
		Clip.reset();
		Sprite.spriteList = [];
		// mt.Timer before its first update (Manager.init creates the game before the first Manager.main)
		Timer.tmod = 1;
		Clip.deferring = true;
		// the original's 300x300 pixels, drawn x2
		root = mc.createEmptyMovieClip("scene", 0);
		root._xscale = root._yscale = 100 * Clip.K;
		root.updateState();

		step = Intro;
		me = this;
		stats = {_p: [], _t: [], _g: [0, 0, 0]};
		dm = new Plans(root);
		msgTimer = 0;
		flMsg = false;
		goSta = false;
		bonusCool = 120;
		sTime = getTimer();
		flBonus = false;
		bonusCol = 1;
		initPlay();

		Clip.deferring = false;
		Clip.runLater();
		MC.displayAll(1);
		// Flash shows the first picture after the first frame (Manager.init, then Manager.main): nothing before
		root.visible = false;
		warmShaders();
	}

	public function initPlay() {
		initBg();
		initPlayer();
		initGui();
	}

	function initBg() {
		bg = dm.attach("mcBg", DP_BG);
		bg._x = Cs.w / 2 + 40;
		bg._y = Cs.h;
	}

	function initPlayer() {
		boxer = new Boxer(dm.attach("mcPlayer", DP_PLAYER));
		afro = new Afro(dm.attach("mcAfro", DP_AFRO));
	}

	function initGui() {
		staInc = 0.1;
		st = dm.add(new StaminaMC(), DP_GUI);
		st._x = Cs.w / 2 + 88;
		st._y = Cs.h - 12;
		st.maskXScale = 100;

		mcChrono = dm.add(new ChronoMC(), DP_GUI);
		mcChrono._x = 150;
		mcChrono._y = 19;
	}

	function initBonus() {
		var bonus = Seed.rand() * 500000;
		// (a draw under BONUSVERT gives a bonus without colour: bonusCol stays 1, the blinking is cancelled each frame)
		if (bonus > BONUSROUGE) {
			currentCol = 0xFF6600;
			bonusCol = 4;
		} else if (bonus > BONUSBLEU) {
			currentCol = 0x02CBFD;
			bonusCol = 3;
		} else if (bonus > BONUSVERT) {
			currentCol = 0xB3FD02;
			bonusCol = 2;
		}
		flBonus = true;
		flCol = true;
		endBonus = 100;
		bonusCool = 200;
		#if debug
		if (bonusCol != 1)
			dbg.bonusShown++;
		#end
	}

	// ---------------------------------------------------------------- UPDATE
	// one frame of the Flash player (Manager.main)
	public function origUpdate() {
		Timer.tmod *= 0.5; // HACK FOR KK2 ~= double mt.Timer.update() call

		if (flBonus) {
			if (endBonus > 0) {
				endBonus -= Timer.tmod;
				if (flCol) {
					boxer.root.setPercentColor(70, currentCol);
					flCol = false;
				} else {
					boxer.root.setPercentColor(40, currentCol);
					flCol = true;
				}
			} else {
				bonusCol = 1;
				flBonus = false;
			}
		}

		if (bonusCol == 1) {
			boxer.root.setPercentColor(0, 0x02CBFD);
		}

		if (bonusCool > 0) {
			bonusCool -= Timer.tmod;
		} else if ((BONUS / BONUSMAX) > Seed.rand()) {
			initBonus();
		}

		updateSprites();

		switch (step) {
			case Intro:
				step = Play;
			case Play:
				if (isMoovin)
					bgAnim();
				incStamina();
				if (flMsg) {
					if (msgTimer > 0) {
						msgTimer -= Timer.tmod;
					} else {
						endMsg();
					}
				}
				updateTime();
			case GameOver:
				fall += 2;
				boxer.y += fall;
		}
	}

	function updateSprites() {
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.update();
	}

	// (the compiled code tests `cTime <= 0` first)
	function updateTime() {
		var newTime = getTimer();

		var cTime = 120000 - (newTime - sTime);
		var dTime = getChronoTimer(cTime);

		if (cTime <= 0) {
			#if debug
			if (dbg.endBy == "")
				dbg.endBy = "time";
			#end
			initGameOver();
		} else {
			mcChrono.setText(dTime);
		}
	}

	// ---------------------------------------------------------------- PLAY
	// (the compiled code tests `_xscale < 100` first)
	public function incStamina() {
		if (st.maskXScale < 100) {
			st.maskXScale += staInc;
		} else if (!flMsg) {
			staMax();
		}
	}

	public function decStamina(val:Int) {
		// (st.power does not exist in mcStamina: its _currentframe and gotoAndStop do nothing)
		if (st.maskXScale > 0) {
			st.maskXScale -= val;
		}

		if (st.maskXScale <= 0) {
			goSta = true;
			#if debug
			if (dbg.endBy == "")
				dbg.endBy = "stamina";
			#end
			initGameOver();
		}
	}

	// st.power.gotoAndStop(2): st.power does not exist (nothing)
	public function staMax() {}

	// (the original drops the message still shown: it stays on its stop() for ever, ended here instead)
	public function newMsg(msg:String, time:Float) {
		if (flMsg)
			endMsg();
		message = dm.add(new TextMC(), DP_MSG);
		message._x = Cs.w;
		message._y = 30;
		message.setText(msg);
		msgTimer = time;
		flMsg = true;
		#if debug
		dbg.msgs++;
		#end
	}

	function endMsg() {
		message.gotoAndPlay("end");
		flMsg = false;
	}

	function initBgAnim(goal:Float) {
		isMoovin = true;
		zStartx = bg._x;
		zFinishx = goal;
	}

	public function moveBg(direction:String) {
		switch (direction) {
			case "right":
				if (-bg._x + Cs.w + 20 < bgWidth() / 2)
					initBgAnim(bg._x - 5);
			case "center":

			case "left":
				if (bg._x < bgWidth() / 2)
					initBgAnim(bg._x + 5);
		}
	}

	function bgAnim() {
		if (bg._x == zFinishx) {
			isMoovin = false;
		} else if (bg._x > zFinishx) {
			bg._x--;
		} else if (bg._x < zFinishx) {
			bg._x++;
		}
	}

	function getChronoTimer(t:Float) {
		var ms = t;
		var s = Std.int(ms / 1000);
		var min = Std.int(s / 60);

		var smin = Std.string(min);
		while (smin.length < 2)
			smin = "0" + smin;
		var ss = Std.string(s - min * 60);
		while (ss.length < 2)
			ss = "0" + ss;

		return smin + ":" + ss;
	}

	public function isPlaying() {
		return Game.me.step != GameOver;
	}

	// ---------------------------------------------------------------- GAMEOVER
	public function initGameOver() {
		step = GameOver;
		endGame();
		fall = 0;
	}

	// ---------------------------------------------------------------- port
	// the glow of the messages compiles its shader now, not at the first punch
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var holder = new Container();
		var s = new PixiSprite(Texture.WHITE);
		s.filters = [new FlashGlow(3, 3, 1, 0xFFFFFF)];
		holder.addChild(s);
		var rt:Dynamic = (cast pixi.core.textures.RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	// flash.Lib.getTimer()
	inline function getTimer():Float {
		return flashTime;
	}

	// bg._width (mcBg is never scaled)
	inline function bgWidth():Float {
		return Data.BG_WIDTH;
	}

	// KKApi.addScore: nothing after the game over
	public function addScore(n:KKConst) {
		if (over)
			return;
		var v:Int = n;
		if (v != 0)
			KadoKadeoManager.kkm.addScore(v);
	}

	// KKApi.gameOver(stats): once (the afro can still knock the player out after the end of the chrono, initGameOver
	// then runs again: the fall starts again, like the original)
	function endGame() {
		if (over)
			return;
		over = true;
		#if debug
		untyped js.Browser.window.__over = debugState();
		#end
		KadoKadeoManager.kkm.gameOver(stats);
	}

	public function stageRoot():ASprite {
		return root;
	}

	// ---------------------------------------------------------------- KadoKadeo step: 5 Flash frames every 4 steps
	public function update(delta:Float) {
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame();
		}
		MC.displayAll(frameAcc / 4);
	}

	// one Flash frame: the timelines advance, then Manager.main (tmod ~0.8: Timer settles on 32 / 40; the game halves
	// it), then the frame scripts the code triggered
	function flashFrame() {
		Timer.tmod = 32 / FLASH_FPS;
		MC.frameStart();
		flashTime += 1000 / FLASH_FPS;
		Clip.deferring = true;
		origUpdate();
		Clip.deferring = false;
		Clip.runLater();
		frameCount++;
		root.visible = true;
		#if debug
		untyped js.Browser.window.__state = debugState();
		#end
	}

	#if debug
	// state compared between a game and its replay (test harness)
	public function debugState():Dynamic {
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			step: Std.string(step),
			over: over,
			stamina: st.maskXScale,
			bx: boxer.x,
			by: boxer.y,
			bstep: Std.string(boxer.step),
			bmove: Std.string(boxer.move),
			combo: boxer.nbCombo,
			bframe: boxer.root._currentframe,
			astep: Std.string(afro.afroStep),
			amove: Std.string(afro.afroMove),
			aframe: afro.root._currentframe,
			defLevel: afro.defLevel,
			bgx: bg._x,
			bonusCol: bonusCol,
			bonusCool: bonusCool,
			chrono: mcChrono.text,
			stats: haxe.Json.stringify(dbg),
		};
	}

	// test harness: clips drawn by the runtime on a page ([name, frame, x, y, scale]), to compare with the SWF
	public function debugShow(list:Array<Array<Dynamic>>, bgColor:Int) {
		var stg:Dynamic = untyped KadoKadeoManager.kkm.stage;
		var box = new ASprite();
		var g = box.getGraphics();
		g.beginFill(bgColor);
		g.drawRect(0, 0, 600, 640);
		g.endFill();
		for (o in list) {
			var c = new Clip(o[0], 2);
			Clip.deferring = true;
			c.gotoAndStop(o[1]);
			Clip.deferring = false;
			Clip.runLater();
			c._x = o[2];
			c._y = o[3];
			c._xscale = c._yscale = o[4] * 100;
			box.addChild(c);
		}
		box.updateState();
		box.updateGraphics(1);
		stg.addChild(box);
	}
	#end

	public function destroy():Void {
		me = null;
		boxer = null;
		afro = null;
		bonusCol = 1;
		MC.clearAll();
		Clip.reset();
		Sprite.spriteList = [];
	}
}

// a picture of the sheet in a clip whose children are in Flash pixels
function picture(anim:String):PixiSprite {
	var t = Tex.get(anim)[0];
	var s = new PixiSprite(t);
	s.anchor.copyFrom(t.defaultAnchor);
	s.scale.set(1 / Clip.K, 1 / Clip.K);
	return s;
}

// mcStamina: its frame, the gauge (sprite 64) under the mask `mask` (a 100 x 12 rectangle whose _xscale the code sets:
// the piece of the gauge picture under it, no mask), the overlay. The code reads and writes mask._xscale (maskXScale),
// shown one Flash frame late like the clips
class StaminaMC extends MC {
	public var maskXScale:Float = 100;

	var shownXScale:Float = 100;
	var gauge:PixiSprite;
	var gaugeTex:Texture;
	var crop:Texture;

	public function new() {
		super(Clip.EMPTY);
		clip.addChild(picture("stFrame"));
		gaugeTex = Tex.get("stGauge")[0];
		crop = new Texture(gaugeTex.baseTexture, gaugeTex.frame.clone());
		gauge = new PixiSprite(crop);
		gauge.scale.set(1 / Clip.K, 1 / Clip.K);
		clip.addChild(gauge);
		clip.addChild(picture("stOver"));
	}

	override function tick() {
		shownXScale = maskXScale;
	}

	override function show(f:Float) {
		var xs = shownXScale + (maskXScale - shownXScale) * f;
		// the mask covers [ST_MASK_X, ST_MASK_X + w] (to the left of it when its scale is negative)
		var w = Data.ST_MASK_W * xs / 100;
		var x0 = Math.min(Data.ST_MASK_X, Data.ST_MASK_X + w);
		var x1 = Math.max(Data.ST_MASK_X, Data.ST_MASK_X + w);
		var t:Dynamic = gaugeTex;
		var fr = gaugeTex.frame;
		var tr:Dynamic = t.trim;
		var trX:Float = tr != null ? tr.x : 0;
		var trY:Float = tr != null ? tr.y : 0;
		var ax:Float = gaugeTex.defaultAnchor.x * t.orig.width;
		var ay:Float = gaugeTex.defaultAnchor.y * t.orig.height;
		// texture pixels of the frame seen through the mask
		var fx0 = Math.max(fr.x, fr.x + ax + x0 * Clip.K - trX);
		var fx1 = Math.min(fr.x + fr.width, fr.x + ax + x1 * Clip.K - trX);
		if (!Math.isFinite(xs) || fx1 <= fx0) {
			gauge.visible = false;
			return;
		}
		gauge.visible = true;
		var c:Dynamic = crop;
		c.frame = new pixi.core.math.shapes.Rectangle(fx0, fr.y, fx1 - fx0, fr.height);
		c.orig = new pixi.core.math.shapes.Rectangle(0, 0, fx1 - fx0, fr.height);
		c.trim = null;
		c.updateUvs();
		gauge.texture = crop;
		gauge.x = (fx0 - fr.x + trX - ax) / Clip.K;
		gauge.y = (trY - ay) / Clip.K;
	}
}

// mcChrono: the bar under its text field `label`, the field (Verdana Bold Italic, a device font: glyph pictures), the
// shine over it
class ChronoMC extends MC {
	public var text(default, null):String;

	var label:Txt;

	public function new() {
		super(Clip.EMPTY);
		clip.addChild(picture("chUnder"));
		label = new Txt(Data.CHRONO_FIELD, 1);
		label.setColor(Data.CHRONO_COLOR);
		clip.addChild(label);
		clip.addChild(picture("chOver"));
		// the text of the field in the SWF
		setText("2:00");
	}

	// mcChrono.label.text = s
	public function setText(s:String) {
		text = s;
		label.setText(s);
	}

	override function tick() {}
}

// mcText (sprite 59): `sub` (its field `label`: the message) slides in glowing red to white, turns cream and shrinks
// (frames 1..9, stop), then from the label "end" shrinks back to white and removes itself (frame 15). Its timeline is
// played here: the position, scale and colour of `sub` on each frame (Data.TEXT_FRAMES), its glow (Data.TEXT_GLOWS)
class TextMC extends MC {
	var sub:Container;
	var label:Txt;
	var glow:FlashGlow;
	var frame:Int = 1;
	var playing:Bool = true;

	public function new() {
		super(Clip.EMPTY);
		sub = new Container();
		label = new Txt(Data.MSG_FIELD, 1);
		sub.addChild(label);
		clip.addChild(sub);
	}

	// message.sub.label.text = s
	public function setText(s:String) {
		label.setText(s);
	}

	// gotoAndPlay("end")
	override public function gotoAndPlay(f:Dynamic) {
		if (removed)
			return;
		frame = Data.TEXT_END;
		playing = true;
	}

	// a Flash frame: the playhead advances, then the frame script (9: stop(), 15: removeMovieClip(""))
	override function tick() {
		if (!playing)
			return;
		frame = frame >= Data.TEXT_FRAMES.length ? 1 : frame + 1;
		if (frame == Data.TEXT_STOP)
			playing = false;
		else if (frame == Data.TEXT_FRAMES.length)
			removeMovieClip();
	}

	override function show(f:Float) {
		var r = Data.TEXT_FRAMES[frame - 1];
		if (r == null) {
			sub.visible = false;
			return;
		}
		sub.visible = true;
		sub.x = r[0];
		sub.y = r[1];
		sub.scale.set(r[2], r[2]);
		var gl = Data.TEXT_GLOWS[frame - 1];
		if (gl == null) {
			sub.filters = null;
		} else {
			if (glow == null)
				glow = new FlashGlow(gl[0], gl[1], gl[2], Std.int(gl[3]));
			glow.set(gl[0], gl[1], gl[2]);
			glow.setColor(Std.int(gl[3]));
			if (sub.filters == null)
				sub.filters = [glow];
		}
		// the white glyphs through the colour transform of `sub`: 255 * multiplier + offset
		var m = r[3];
		var c = 0;
		for (i in 0...3) {
			var ch = (Data.MSG_COLOR >> (16 - 8 * i)) & 0xFF;
			c = (c << 8) | Std.int(Math.min(255, Math.round(ch * m + r[4 + i])));
		}
		label.setColor(c);
	}
}
