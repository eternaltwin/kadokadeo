package eltortuganemesis;

import common_haxe_avm1.KeyboardManager;
import eltortuganemesis.Actors;
import eltortuganemesis.Bmp;
import eltortuganemesis.Cs;
import eltortuganemesis.PVector;
import eltortuganemesis.Screens;
import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchControlsMode;
import pixi.core.Pixi.BlendModes;
import pixi.core.display.Container;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

enum GameOverKind {
	DOG;
	DOG_LAZERS;
	SQUIREL;
	ELECTRIFIED;
}

enum State {
	INIT;
	INIT_LEVEL;
	PLAY;
	CUT;
	SUCCESS;
	NEXT_LEVEL;
	GAME_OVER(k:GameOverKind);
}

typedef Rect = {x:Float, y:Float, width:Float, height:Float};

// El Tortuga Nemesis (KadoKado TortugaQix, Motion-Twin, a Flash 9 game): ported from the original sources (Game, Cursor,
// Qix, QixLazer, Spark, LazerSpark, MyGrass, Level...) and the graphics of its SWFs. A Qix: the turtle runs along the
// mown paths, Space / Enter lets it go into the wild lawn with its lazer cable; closing a zone mows it.
// The game logic reads the pixels of its bitmaps like the original: they are in memory (Bmp), the same on every
// computer; the field is 401 x 401, the view 300 x 300 follows the turtle, drawn x2.
@:expose('GameElTortugaNemesis')
class Game implements kado.GameInterface {
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.JOYSTICK,
		joystick: {
			x: 0.18,
			y: 0.8,
			radius: 84,
			deadZone: 0.18,
			dynamicCenter: true,
			directions: 4,
		},
		buttons: [
			{
				id: "cable",
				label: "⚡",
				rightPx: 14,
				bottomPx: 14,
				size: 84,
				keyCode: KeyboardManager.SPACE,
			}
		],
	};

	// ZQSD / WASD like the arrows (Key class of the original), Enter like Space
	public static var KEY_ALIASES = KeyboardManager.ALIASES_MOVE;

	public static inline var K = 2;

	public static inline var VW = 300;
	public static inline var VH = 300;
	public static inline var W = 401;
	public static inline var H = 401;
	public static inline var PADW = 20;
	public static inline var PADH = 20;
	public static inline var SLOW_SPEED = 2.4;
	public static inline var FAST_SPEED = 3.8;
	public static inline var LINE_WIDTH = 1;
	public static inline var FPS = 32;

	public static var me:Game;

	static var drawKeyDown = false;
	static var state:State;
	static var drawColor:Int = 0;
	static var vpcent:Float = 0.0;

	public static var now:Float = 0;
	public static var qix:Qix;

	static var cursor:Cursor;
	static var movePower:Float = 0.0;
	static var moveMod:Int = 10;
	static var moveZone:Bmp;
	static var lastFill:Bmp;

	public static var drawing:Bmp;
	public static var drawStart:PVector;
	public static var drawVector:Pt;
	public static var drawStartTime:Float;

	static var lazerSpark:LazerSpark;
	static var stats:GameLevelStat;
	static var levelIdx:Int = 0;

	public static var level:Level;

	static var nBlocksWidth:Int = 10;
	static var nBlocksHeight:Int = 10;
	static var gameover = false;

	public static var field:Rect = {x: 0, y: 0, width: 0, height: 0};

	static var log:Array<GameLevelStat>;
	static var deltaPcent = 0.0;
	static var nextLevelScreen:LevelScreen;
	static var debriefTiming:Null<Float>;
	static var anim:CutParticleSystem;

	// display
	var scene:ASprite;
	var world:ASprite;
	var hud:ASprite;
	var overlay:ASprite;
	var squirrels:ASprite;
	var visipathTex:BufTex;
	var drawingTex:BufTex;
	var lastFillTex:BufTex;
	var lazersFrontTex:BufTex;
	var lazersBackTex:BufTex;
	var visipathView:PixiSprite;
	var drawingView:PixiSprite;
	var lastFillView:PixiSprite;
	var lazerViews:Array<PixiSprite>;
	var etincelle:Mc;
	var pcent:Text;
	var pcentDecimal:Text;
	var pcentGoal:Text;
	var snapRt:RenderTexture;
	var drawingDirty:Bool;

	public var mcs:Array<Mc>;

	var frameCount:Int;
	var over:Bool;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: UInt16Array.fromArray([
				KeyboardManager.LEFT, KeyboardManager.RIGHT, KeyboardManager.UP, KeyboardManager.DOWN, KeyboardManager.SPACE,
				KeyboardManager.ENTER
			]),
			recordInputs: true,
			recordEvents: false,
		});
		me = this;
		mcs = [];
		frameCount = 0;
		over = false;
		// statics of the original reset at each game (a Flash game was a new SWF)
		state = INIT;
		drawKeyDown = false;
		drawColor = 0;
		vpcent = 0.0;
		now = 0;
		movePower = 0.0;
		moveMod = 10;
		lastFill = null;
		drawing = null;
		lazerSpark = null;
		levelIdx = 0;
		gameover = false;
		log = [];
		deltaPcent = 0.0;
		nextLevelScreen = null;
		debriefTiming = null;
		anim = null;
		Spark.sparks = [];

		scene = root.createEmptyMovieClip("scene", 0);
		scene._xscale = scene._yscale = 100 * K;
		scene.updateState();
		world = scene.createEmptyMovieClip("world", 0);
		overlay = scene.createEmptyMovieClip("overlay", 2);
		hud = scene.createEmptyMovieClip("hud", 1);

		init();
	}

	function init() {
		var fieldWidth = W - 2 * PADW;
		nBlocksWidth = Math.floor(fieldWidth / moveMod);
		fieldWidth = nBlocksWidth * moveMod;
		nBlocksHeight = Math.floor(fieldWidth / moveMod);
		var fieldHeight = nBlocksHeight * moveMod;
		field.x = (W - fieldWidth) / 2;
		field.y = (H - fieldHeight) / 2;
		field.width = fieldWidth;
		field.height = fieldHeight;
		moveZone = new Bmp(W, H, Colors.OUTSIDE);

		Lawn.init();
		world.addChild(Lawn.view);
		visipathTex = new BufTex(W, H);
		visipathView = new PixiSprite(visipathTex.tex);
		visipathView.blendMode = BlendModes.ADD;
		world.addChild(visipathView);
		lastFillTex = new BufTex(W, H);
		lastFillView = new PixiSprite(lastFillTex.tex);
		lastFillView.blendMode = BlendModes.SCREEN;
		lastFillView.visible = false;
		world.addChild(lastFillView);
		drawingTex = new BufTex(W, H);
		drawingView = new PixiSprite(drawingTex.tex);
		drawingView.blendMode = BlendModes.ADD;
		drawingView.visible = false;
		world.addChild(drawingView);

		cursor = new Cursor();
		world.addChild(cursor.gfx);
		squirrels = new ASprite();
		world.addChild(squirrels);
		qix = new Qix();
		// (smoothed: the lazers are drawn anti-aliased in the original)
		lazersBackTex = new BufTex(W, H, true);
		lazersFrontTex = new BufTex(W, H, true);
		lazerViews = [];
		for (t in [lazersBackTex, lazersBackTex]) {
			var s = new PixiSprite(t.tex);
			s.visible = false;
			lazerViews.push(s);
			world.addChild(s);
		}
		lazerViews[1].blendMode = BlendModes.ADD;
		world.addChild(qix.gfx);
		for (t in [lazersFrontTex, lazersFrontTex]) {
			var s = new PixiSprite(t.tex);
			s.visible = false;
			lazerViews.push(s);
			world.addChild(s);
		}
		lazerViews[3].blendMode = BlendModes.ADD;
		etincelle = new Mc("etincelle");
		etincelle.blendMode = BlendModes.ADD;
		etincelle.visible = false;
		world.addChild(etincelle);

		pcent = new Text("txt16", Data.T16_CHARS, Data.T16_ADV, Data.T16_ASC, Data.T16_DESC, "00,");
		pcentDecimal = new Text("txt12", Data.T12_CHARS, Data.T12_ADV, Data.T12_ASC, Data.T12_DESC, "0");
		pcentGoal = new Text("txt16", Data.T16_CHARS, Data.T16_ADV, Data.T16_ASC, Data.T16_DESC, "99");
		hud.addChild(pcent);
		hud.addChild(pcentDecimal);
		hud.addChild(pcentGoal);
		hud.visible = false;
		levelIdx = 0;
		snapRt = RenderTexture.create(VW * K, VH * K);
	}

	public function addSquirrel(m:Sym) {
		squirrels.addChild(m);
	}

	static function reset(levelNbr:Int) {
		level = Level.get(levelNbr);
		levelIdx = levelNbr + 1;
		stats = new GameLevelStat();
		log.push(stats);
		drawing = null;
		me.drawingDirty = true;
		lazerSpark = null;
		moveZone.fill(Colors.OUTSIDE);
		moveZone.fillRect(PADW, PADH - 1, nBlocksWidth * moveMod + 1, nBlocksHeight * moveMod + 2, Colors.CONQUERED_PATH);
		moveZone.fillRect(PADW + 1, PADH, nBlocksWidth * moveMod - 1, nBlocksHeight * moveMod - 1, Colors.TO_CONQUER);
		cursor.moveVector = {x: 0.0, y: 0.0};
		movePower = 0.0;
		cursor.pos.x = PADW + moveMod * Math.floor(nBlocksWidth / 2);
		cursor.pos.y = PADH + moveMod * nBlocksHeight - 1;
		cursor.oldPos = cursor.pos.clone();
		cursor.speed = FAST_SPEED;
		qix.setPos(Math.round(W / 2), Math.round(H / 4));
		qix.reset();
		vpcent = 0.0;
		deltaPcent = 0.0;
		refreshPercentCounter();
		updateVisiPath();
		Lawn.update(true, true);
		Spark.reset();
		// the turtle and the view at their new place at once (no slide from the previous level)
		cursor.gfx._x = cursor.pos.x;
		cursor.gfx._y = cursor.pos.y;
		cursor.gfx.updateState();
		me.render();
		me.scene.updateState();
	}

	// LEVEL COMPLETION STATISTICS
	static function updateStats() {
		var space = 4;
		var topX = PADW + 1;
		var topY = PADH + 1;
		var w = W - 2 * topX;
		var h = H - 2 * topY;
		var n = 0;
		var slow = 0;
		var fast = 0;
		var empty = 0;
		for (x in 0...Std.int(w / space)) {
			for (y in 0...Std.int(h / space)) {
				n++;
				var color = moveZone.get(topX + x * space, topY + y * space);
				if (Colors.isConqueredSlow(color))
					slow++;
				else if (Colors.isConqueredFast(color))
					fast++;
				else
					empty++;
			}
		}
		stats.update(slow, fast, empty, n, level.goal);
		if (stats.lastZone != null)
			me.addScore(stats.lastZone.value);
	}

	static function refreshPercentCounter() {
		me.pcentGoal.setText("/" + level.goal + "%");
		me.pcentDecimal.setText("" + Math.floor((vpcent - Math.floor(vpcent)) * 10));
		me.pcent.setText(StringTools.lpad("" + Math.floor(vpcent), "0", 2) + ",");
	}

	static function updatePercentCounter() {
		if (stats != null && vpcent < stats.pcent) {
			var maxt = (1.5 * FPS);
			var time = Math.min(maxt, deltaPcent * maxt / 50);
			vpcent = Math.min(stats.pcent, vpcent + deltaPcent / time);
			refreshPercentCounter();
		}
	}

	// MOVE / CONQUERED ZONE
	public static function getPixel(x:Int, y:Int):Int {
		return moveZone.get(x, y);
	}

	public static function getPixels(x:Int, y:Int):Array<Int> {
		return getPixelsAround(moveZone, x, y);
	}

	public static function getDrawingPixels(x:Int, y:Int):Array<Int> {
		return getPixelsAround(drawing, x, y);
	}

	static function getPixelsAround(b:Bmp, x:Int, y:Int):Array<Int> {
		return [
			b.get(x - 1, y - 1),
			b.get(x, y - 1),
			b.get(x + 1, y - 1),
			b.get(x - 1, y),
			b.get(x, y),
			b.get(x + 1, y),
			b.get(x - 1, y + 1),
			b.get(x, y + 1),
			b.get(x + 1, y + 1),
		];
	}

	public static function getCursorPos():{x:Int, y:Int} {
		return {
			x: Math.round(cursor.pos.x),
			y: Math.round(cursor.pos.y),
		};
	}

	static function updateCursor() {
		cursor.oldPos = cursor.pos.clone();
		var nextVector:Pt = null;
		var speed = cursor.speed * Timer.tmod;
		if (speed > movePower) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT))
				nextVector = {x: -1.0, y: 0.0};
			else if (KeyboardManager.isDown(KeyboardManager.RIGHT))
				nextVector = {x: 1.0, y: 0.0};
			else if (KeyboardManager.isDown(KeyboardManager.UP))
				nextVector = {x: 0.0, y: -1.0};
			else if (KeyboardManager.isDown(KeyboardManager.DOWN))
				nextVector = {x: 0.0, y: 1.0};
		}
		while (speed > 0) {
			if (movePower <= 0.00001) {
				var prev = new PVector(Math.round(cursor.pos.x), Math.round(cursor.pos.y));
				cursor.pos.x = Math.round(cursor.pos.x);
				cursor.pos.y = Math.round(cursor.pos.y);
				cursorMoved(prev);
				if (nextVector != null
					&& canMoveAt(Math.round(cursor.pos.x + nextVector.x * moveMod), Math.round(cursor.pos.y + nextVector.y * moveMod))
					&& canMoveAt(Math.round(cursor.pos.x + nextVector.x * moveMod / 2), Math.round(cursor.pos.y + nextVector.y * moveMod / 2))) {
					cursor.setNewMoveVector(nextVector.x, nextVector.y);
					movePower = moveMod;
				} else {
					movePower = 0;
					cursor.setNewMoveVector(0.0, 0.0);
					break;
				}
			}
			var n = Math.min(1, speed);
			n = Math.min(n, movePower);
			speed -= n;
			movePower -= n;
			var prev = new PVector(Math.round(cursor.pos.x), Math.round(cursor.pos.y));
			cursor.pos.x += cursor.moveVector.x * n;
			cursor.pos.y += cursor.moveVector.y * n;
			cursorMoved(prev);
		}
		cursor.update();
	}

	static function canMoveAt(x:Int, y:Int):Bool {
		if (drawing != null && x == drawStart.x && y == drawStart.y)
			return false;
		var color = Colors.OUTSIDE;
		if (x > 0 && x < W && y > 0 && y < H)
			color = moveZone.get(x, y);
		if (color == Colors.CONQUERED_PATH || color == Colors.CONQUERED_PATH_FAST) {
			for (pix in getPixelsAround(moveZone, x, y))
				if (pix == Colors.TO_CONQUER)
					return true;
			return false;
		}
		if (color == Colors.TO_CONQUER) {
			if (drawing == null)
				return drawKeyDown;
			return drawing.get(x, y) == 0;
		}
		return false;
	}

	static function cursorMoved(prevPos:PVector) {
		var x = Math.round(cursor.pos.x);
		var y = Math.round(cursor.pos.y);
		if (prevPos.x == x && prevPos.y == y)
			return;
		var color = moveZone.get(x, y);
		if (color == Colors.CONQUERED_PATH || color == Colors.CONQUERED_PATH_FAST) {
			if (drawing != null)
				linkPoint(x, y, drawStart.clone().add(drawVector));
		} else if (color == Colors.TO_CONQUER) {
			if (drawing == null) {
				cursor.speed = drawKeyDown ? SLOW_SPEED : FAST_SPEED;
				drawColor = cursor.speed == SLOW_SPEED ? Colors.DRAWING_PATH_SLOW : Colors.DRAWING_PATH_FAST;
				drawStart = prevPos;
				var vx = cursor.pos.x - prevPos.x, vy = cursor.pos.y - prevPos.y;
				var l = Math.sqrt(vx * vx + vy * vy);
				drawVector = {x: vx / l, y: vy / l};
				drawStartTime = now;
				drawing = new Bmp(W, H);
			}
			if (drawing != null) {
				drawing.set(x, y, drawColor);
				me.drawingDirty = true;
				if (cursor.speed == SLOW_SPEED && !drawKeyDown) {
					cursor.speed = FAST_SPEED;
					drawColor = Colors.DRAWING_PATH_FAST;
					drawing.floodFill(x, y, drawColor);
				}
			}
		}
	}

	static function linkPoint(x:Int, y:Int, start:PVector) {
		state = CUT;
		// Merge the line on the moveZone
		moveZone.mergeOpaque(drawing);
		// pixels around arrival zone: one pixel in each separated zone
		var pixels = getPixelsAround(moveZone, x, y);
		var z1 = {x: 0, y: 0};
		var z2 = {x: 0, y: 0};
		if (pixels[0] == drawColor) {
			z1 = {x: x - 1, y: y};
			z2 = {x: x, y: y - 1};
		} else if (pixels[1] == drawColor) {
			z1 = {x: x - 1, y: y - 1};
			z2 = {x: x + 1, y: y - 1};
		} else if (pixels[2] == drawColor) {
			z1 = {x: x, y: y - 1};
			z2 = {x: x + 1, y: y};
		} else if (pixels[3] == drawColor) {
			z1 = {x: x - 1, y: y - 1};
			z2 = {x: x - 1, y: y + 1};
		} else if (pixels[5] == drawColor) {
			z1 = {x: x + 1, y: y - 1};
			z2 = {x: x + 1, y: y + 1};
		} else if (pixels[6] == drawColor) {
			z1 = {x: x - 1, y: y};
			z2 = {x: x, y: y + 1};
		} else if (pixels[7] == drawColor) {
			z1 = {x: x - 1, y: y + 1};
			z2 = {x: x + 1, y: y + 1};
		} else if (pixels[8] == drawColor) {
			z1 = {x: x + 1, y: y};
			z2 = {x: x, y: y + 1};
		}
		// the line becomes a path
		var color = if (drawColor == Colors.DRAWING_PATH_FAST) Colors.CONQUERED_PATH_FAST else Colors.CONQUERED_PATH;
		moveZone.floodFill(Math.round(start.x), Math.round(start.y), color);
		// which side is filled: not the one of the dog
		var tmp = moveZone.clone();
		var fcolor = if (drawColor == Colors.DRAWING_PATH_FAST) Colors.CONQUERED_ZONE_FAST else Colors.CONQUERED_ZONE;
		var red = 0xFFFF0000;
		var z = z1;
		tmp.floodFill(z.x, z.y, red);
		var qPos = new PVector(qix.x, qix.y);
		if (tmp.get(Math.round(qPos.x), Math.round(qPos.y)) == red) {
			// oups, wrong side :)
			z = z2;
			moveZone.floodFill(z.x, z.y, red);
		} else {
			moveZone = tmp;
		}
		// lastFill: paletteMap of the red channel (255 -> FLASH_COLOR, else transparent) + the other channels
		lastFill = new Bmp(W, H);
		var src = moveZone.data, dst = lastFill.data;
		for (i in 0...src.length) {
			var c = src[i];
			var r = (c >> 16) & 255;
			var v = (r == 255 ? Colors.FLASH_COLOR : 0x01000000) + (c & 0xFF00) + (c & 0xFF) + (c & 0xFF000000);
			dst[i] = v | 0;
		}
		moveZone.floodFill(z.x, z.y, fcolor);
		drawing = null;
		me.drawingDirty = true;
		lazerSpark = null;
		cursor.speed = FAST_SPEED;
		updateStats();
		deltaPcent = stats.pcent - vpcent;
		Lawn.update(true);
		updateVisiPath();
		me.showLastFill();
	}

	// the visible path: the outline (1 px) of the zone of the dog, light blue, added
	static function updateVisiPath() {
		var buffer = moveZone.clone();
		var pq = qix.getPos();
		buffer.floodFill(Math.round(pq.x), Math.round(pq.y), 0xFF0000FF);
		var t = me.visipathTex;
		t.clear();
		var d = buffer.data;
		for (y in 0...H) {
			for (x in 0...W) {
				var i = y * W + x;
				if (d[i] == 0xFF0000FF)
					continue;
				var inZone = (x > 0 && d[i - 1] == 0xFF0000FF) || (x < W - 1 && d[i + 1] == 0xFF0000FF) || (y > 0 && d[i - W] == 0xFF0000FF)
					|| (y < H - 1 && d[i + W] == 0xFF0000FF);
				if (inZone)
					t.setPx(i, 100, 100, 227, 255);
			}
		}
		t.upload();
	}

	function showLastFill() {
		var t = lastFillTex;
		t.clear();
		var d = lastFill.data;
		for (i in 0...d.length) {
			var c = d[i];
			var a = (c >>> 24);
			if (a > 1)
				t.setPx(i, (c >> 16) & 255, (c >> 8) & 255, c & 255, a);
		}
		t.upload();
	}

	// one frame of the Flash player
	public function update(delta:Float) {
		frameCount++;
		advanceClips();
		now = frameCount * 1000 / FPS;
		drawKeyDown = KeyboardManager.isDown(KeyboardManager.SPACE) || KeyboardManager.isDown(KeyboardManager.ENTER);
		switch (state) {
			case INIT:
				state = NEXT_LEVEL;

			case NEXT_LEVEL:
				snapshot();
				reset(levelIdx);
				state = INIT_LEVEL;
				if (nextLevelScreen != null)
					nextLevelScreen.dispose();
				nextLevelScreen = new LevelScreen(levelIdx, snapRt);
				overlay.addChild(nextLevelScreen);

			case INIT_LEVEL:
				if (nextLevelScreen.step(Lawn.update())) {
					nextLevelScreen.dispose();
					nextLevelScreen = null;
					state = PLAY;
				}

			case PLAY:
				if (anim != null && anim.step()) {
					anim.dispose();
					anim = null;
				}
				if (drawing != null) {
					if (lazerSpark != null)
						lazerSpark.update();
					else if (now - drawStartTime > level.lazerSparkDelay)
						lazerSpark = new LazerSpark();
				}
				qix.update();
				Spark.updateSparks();
				if (!checkCollisions())
					updateCursor();

			case CUT:
				qix.updateAnim();
				Spark.pauseSparksAnim();
				var ready = Lawn.update();
				if (ready) {
					anim = new CutParticleSystem(lastFill);
					world.addChild(anim);
					lastFill = null;
					if (stats.pcent >= level.goal)
						state = SUCCESS;
					else
						state = PLAY;
				}

			case SUCCESS:
				if (anim != null && anim.step()) {
					anim.dispose();
					anim = null;
				}
				// LevelDebriefingScreen: nothing shown, one second
				if (debriefTiming == null)
					debriefTiming = 0;
				debriefTiming += Timer.deltaT * 1000;
				if (debriefTiming >= 1000) {
					debriefTiming = null;
					if (anim != null) {
						anim.dispose();
						anim = null;
					}
					state = NEXT_LEVEL;
				}

			case GAME_OVER(goKind):
				if (!gameover) {
					gameover = true;
					endGame();
				}
				qix.updateAnim();
		}
		updatePercentCounter();
		render();
	}

	// timelines of the Mc (before the code of the frame)
	function advanceClips() {
		var i = 0;
		var n = mcs.length;
		while (i < n) {
			var m = mcs[i];
			if (m.dead || !onStage(m)) {
				mcs[i] = mcs[n - 1];
				mcs.pop();
				n--;
				continue;
			}
			i++;
		}
		for (m in mcs.copy())
			m.advance();
	}

	function onStage(m:Mc):Bool {
		var p:Container = m.parent;
		while (p != null) {
			if (p == scene)
				return true;
			p = p.parent;
		}
		return false;
	}

	static function checkCollisions():Bool {
		if (drawing != null) {
			if (qix.collidesDrawing(drawing)) {
				state = GAME_OVER(DOG);
				return true;
			}
			if (lazerSpark != null) {
				if (lazerSpark.vector == null) {
					state = GAME_OVER(ELECTRIFIED);
					return true;
				}
				var rect = new Vector2D(lazerSpark.oldPos, lazerSpark.pos);
				if (rect.rectangleContains(cursor.pos) || rect.rectangleContains(cursor.oldPos)) {
					state = GAME_OVER(ELECTRIFIED);
					return true;
				}
			}
			if (cursorCollidesQixLazers()) {
				state = GAME_OVER(DOG_LAZERS);
				return true;
			}
			if (cursorCollidesSquirels()) {
				state = GAME_OVER(SQUIREL);
				return true;
			}
		} else {
			if (cursorCollidesSquirels()) {
				state = GAME_OVER(SQUIREL);
				return true;
			}
			if (cursorCollidesQixLazers()) {
				state = GAME_OVER(DOG_LAZERS);
				return true;
			}
		}
		return false;
	}

	static function cursorCollidesQixLazers():Bool {
		if (qix.lazers == null)
			return false;
		return cursor.collides(qix.lazersBack) || cursor.collides(qix.lazersFront);
	}

	static function cursorCollidesSquirels():Bool {
		for (spark in Spark.sparks) {
			var dx = spark.pos.x - cursor.pos.x, dy = spark.pos.y - cursor.pos.y;
			if (dx * dx + dy * dy <= 17 * 17)
				return true;
		}
		return false;
	}

	// RENDER
	function render() {
		var gok = null;
		if (gameover) {
			switch (state) {
				case GAME_OVER(k):
					gok = k;
				default:
			}
		}
		var vx = Math.min(Math.max(0, Math.round(cursor.pos.x - VW / 2)), W - VW);
		var vy = Math.min(Math.max(0, Math.round(cursor.pos.y - VH / 2)), H - VH);
		world._x = -vx;
		world._y = -vy;
		var ready = Lawn.isReady();
		world.visible = ready;
		// blink of the last fill
		lastFillView.visible = lastFill != null && frameCount % 4 == 0;
		// the cable, blinking on game over by the dog
		if (drawingDirty) {
			drawingDirty = false;
			if (drawing != null) {
				var t = drawingTex;
				t.clear();
				var d = drawing.data;
				for (i in 0...d.length) {
					var c = d[i];
					if (c != 0)
						t.setPx(i, (c >> 16) & 255, (c >> 8) & 255, c & 255, 255);
				}
				t.upload();
			}
		}
		drawingView.visible = drawing != null && (!gameover || gok != DOG || frameCount % 10 >= 5);
		// the turtle, blinking on game over
		cursor.gfx.visible = !gameover || frameCount % 10 >= 5;
		// lazers of the dog: drawn, then added
		if (qix.lazersChanged) {
			qix.lazersChanged = false;
			if (qix.lazers != null) {
				lazersBackTex.fromABmp(qix.lazersBack);
				lazersFrontTex.fromABmp(qix.lazersFront);
			}
		}
		for (v in lazerViews)
			v.visible = qix.lazers != null;
		qix.gfx._x = qix.x;
		qix.gfx._y = qix.y;
		qix.gfx.sync();
		etincelle.visible = lazerSpark != null;
		if (lazerSpark != null) {
			etincelle._x = lazerSpark.pos.x;
			etincelle._y = lazerSpark.pos.y;
		}
		if (anim != null)
			world.setChildIndex(anim, world.children.length - 1);
		// percentage
		hud.visible = ready;
		if (ready) {
			pcentGoal._x = VW - pcentGoal.textWidth;
			pcentGoal._y = 0;
			pcentDecimal._x = VW - pcentGoal.textWidth - pcentDecimal.textWidth;
			pcentDecimal._y = 3;
			pcent._x = VW - pcentGoal.textWidth - pcentDecimal.textWidth - pcent.textWidth + 4;
			pcent._y = 0;
		}
	}

	// picture of the game (view.clone() of the level screen)
	function snapshot() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var holder = new Container();
		var bg = new pixi.core.graphics.Graphics();
		bg.beginFill(0x555500);
		bg.drawRect(0, 0, VW, VH);
		bg.endFill();
		holder.addChild(bg);
		renderer.render(holder, {renderTexture: snapRt, clear: true, transform: new Matrix(K, 0, 0, K, 0, 0)});
		holder.destroy({children: true});
		if (Lawn.isReady()) {
			var px = scene.position.x, py = scene.position.y;
			var sx = scene.scale.x, sy = scene.scale.y;
			scene.position.set(0, 0);
			scene.scale.set(K, K);
			renderer.render(scene, {renderTexture: snapRt, clear: false});
			scene.position.set(px, py);
			scene.scale.set(sx, sy);
		}
	}

	function endGame() {
		if (over)
			return;
		over = true;
		#if debug
		untyped js.Browser.window.__over = {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			level: levelIdx
		};
		#end
		KadoKadeoManager.kkm.gameOver({l: [for (s in log) [s.pcent, s.score, s.list.length]]});
	}

	public function addScore(n:Int) {
		if (!over)
			KadoKadeoManager.kkm.addScore(n);
	}

	// joystick of the touch screens: the arrows (4 directions)
	public function pollTouchControls():Void {
		var joystick = KadoKadeoManager.kkm.getTouchJoystickState();
		if (joystick == null)
			return;
		var axisX = joystick.active ? joystick.dirX : 0;
		var axisY = joystick.active ? joystick.dirY : 0;
		setKey(KeyboardManager.LEFT, axisX < 0);
		setKey(KeyboardManager.RIGHT, axisX > 0);
		setKey(KeyboardManager.UP, axisY < 0);
		setKey(KeyboardManager.DOWN, axisY > 0);
	}

	inline function setKey(keyCode:Int, down:Bool):Void {
		if (down)
			KeyboardManager.setKeyDown(keyCode);
		else
			KeyboardManager.setKeyUp(keyCode);
	}

	public function destroy():Void {
		Lawn.destroy();
		if (snapRt != null)
			snapRt.destroy(true);
		snapRt = null;
		mcs = [];
	}
}
