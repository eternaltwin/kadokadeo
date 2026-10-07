package oursouinvader;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchButtonShape;
import kado.TouchControlsConfig.TouchControlsMode;
import oursouinvader.MC.Plans;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;
import pixi.filters.colormatrix.ColorMatrixFilter;

typedef MonsterKind = {mc:String, diff:Int};

// Game.mt of the original, line by line; the port's own parts are at the end
@:expose('GameOursouinvader')
class Game implements kado.GameInterface {
	// left / right move the urchin, the big button shoots (Space)
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "left",
				label: "◀",
				leftPx: 20,
				bottomPx: 30,
				size: 80,
				keyCode: KeyboardManager.LEFT,
				shape: TouchButtonShape.SQUARE,
			},
			{
				id: "right",
				label: "▶",
				leftPx: 112,
				bottomPx: 30,
				size: 80,
				keyCode: KeyboardManager.RIGHT,
				shape: TouchButtonShape.SQUARE,
			},
			{
				id: "fire",
				label: "●",
				rightPx: 20,
				bottomPx: 30,
				size: 104,
				keyCode: KeyboardManager.SPACE,
			},
		],
	};

	// ZQSD / WASD move like the arrows, Enter shoots like Space
	public static var KEY_ALIASES = KeyboardManager.ALIASES_MOVE.concat(KeyboardManager.ALIASES_ENTER_SPACE);

	// Flash played Oursouinvader at 40 frames/s (the rate of temple.swf) with Timer.wantedFPS = 32
	public static inline var FLASH_FPS = 40;

	// (the cheat of the original, Enter kills the wave: off)
	static var FL_CHEAT = false;

	static var BASESPEED = 2;
	static var MAXSPEED = 10;

	public var dm:Plans;

	var root:ASprite;

	public var mSpeed:Float;

	var fValue:Float;

	var xmRange:Int;
	var ymRange:Int;

	var bg:MC;

	public var hero:Ship;

	public var direction:Float;

	var totalMonster:Int;

	var m2move:Int;
	var mIndex:Int;

	public var nbIntro:Int;

	var flTurn:Bool;

	public var shotList:Array<Shot>;
	public var monsterList:Array<Monster>;
	public var sList:Array<Sprite>;
	public var bonusList:Array<Bonus>;
	public var pList:Array<Part>;

	var difficulty:Float;
	var diffLevel:Float;
	var lagTimer:Float;

	public var mcLim:MC;

	static var MONSTERLEVELMAX = 4;

	static var MONSTERS:Array<MonsterKind> = null;

	public var step:Int;

	// mcWave and its field bx (the width of its blur)
	var mcWave:MC;
	var mcWaveBx:Float;

	var burb:Array<Burb>;

	//debug
	var zeLevel:Int;
	var flReady:Int;

	public static var me:Game;

	// port
	var isReplay:Bool;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	var over:Bool = false;
	// the filters of mcWave: GlowFilter(4, 4, strength 50, white) then BlurFilter(bx, 0)
	var waveBlur:BoxBlurX;
	var flushListener:Dynamic;
	#if debug
	// test harness: events of the game (coverage)
	public var stats = {kills: [0, 0, 0, 0, 0], bonus: [0, 0, 0, 0, 0, 0, 0], shots: 0, kamikaze: 0, shield: 0};
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
		Clip.random = Seed.randomVfx;
		// mt.Timer before its first update (Manager.init creates the game before the first Manager.main)
		Timer.tmod = 1;
		Clip.deferring = true;
		me = this;

		Cs.init();
		Cs.game = this;
		// the original's 300x300 pixels, drawn x2
		root = mc.createEmptyMovieClip("scene", 0);
		root._xscale = root._yscale = 100 * Clip.K;
		root.updateState();
		dm = new Plans(root);

		MONSTERS = [
			{mc: "mcBadBoy", diff: 1},
			{mc: "mcOcto", diff: 9},
			{mc: "mcBomber", diff: 35},
			{mc: "mcOyster", diff: 69}
		];

		mIndex = 0;
		mSpeed = BASESPEED;
		fValue = 4;

		xmRange = 6;
		ymRange = 4;
		totalMonster = xmRange * ymRange;

		//Difficulté
		difficulty = xmRange * ymRange;
		diffLevel = difficulty;

		flTurn = false;

		direction = 1;

		sList = new Array();
		pList = new Array();
		shotList = new Array();
		monsterList = new Array();
		bonusList = new Array();
		//debug
		flReady = 0;
		lagTimer = 0;

		bg = dm.attach("mcBg", 0);
		initBurbulisseur();

		hero = new Ship(dm.attach("mcHero", 1));
		mcLim = dm.attach("mcLimit", 1);
		mcLim._y = 220; //240
		mcLim.stop();

		zeLevel = -1;
		initStep(0);

		Clip.deferring = false;
		Clip.runLater();

		// the bubble bitmaps are drawn on the GPU just before the screen is: after the steps of the frame (NORMAL
		// priority), before the render of the page (LOW)
		flushListener = function(_) flushBitmaps();
		var ticker:Dynamic = KadoKadeoManager.kkm.ticker;
		ticker.add(flushListener, null, -10);

		MC.displayAll(1);
		// Flash shows the first picture after the first frame (Manager.init, then Manager.main): nothing before (the
		// sprites are placed by their first update)
		root.visible = false;
		warmShaders();
	}

	/*************************************************
	 *											MAIN
	 **************************************************/
	function initStep(n:Int) {
		step = n;
		switch (step) {
			case 0: // SPAWN
				nbIntro = 0;
				initMonsters();
				hero.initState();

				// CLEAN
				while (shotList.length > 0)
					shotList.pop().kill();
				while (bonusList.length > 0)
					bonusList.pop().kill();

				// LEVEL DISPLAY
				if (mcWave != null)
					mcWave.removeMovieClip();
				mcWave = dm.attach(Clip.EMPTY, 8);
				mcWaveBx = 100;

				// filters = [GlowFilter(blur 4 x 4, strength 50, white), BlurFilter(bx, 0)]
				waveBlur = new BoxBlurX(mcWaveBx);
				mcWave.clip.filters = [new FlashGlow(4, 4, 50, 0xFFFFFF), waveBlur];
				// field.text = "VAGUE " + (zeLevel + 1): the glyphs of the SWF's font
				var field = new Txt(Data.WAVE, 1);
				field.setColor(Data.WAVE_COLOR);
				field.setText("VAGUE " + (zeLevel + 1));
				mcWave.clip.addChild(field);

			//initStep(1)
			case 1: // GAME
				for (i in 0...monsterList.length) {
					var sp = monsterList[i];
					sp.x = sp.tx;
					sp.y = sp.ty;
					sp.vx = 0;
					sp.vy = 0;
					sp.step = 1;
				}
		}
	}

	function main() {
		// SPRITE
		moveSprites();

		updateBurbulisseur();
		updateGfxMode();

		switch (step) {
			case 0: // SPAWN
				if (nbIntro >= monsterList.length)
					initStep(1);
				mcWaveBx *= 0.75;
				if (mcWaveBx < 2)
					mcWaveBx = 0;
				waveBlur.blurX = mcWaveBx;

			case 1: // GAME
				if (mcWave != null) {
					mcWaveBx += 1;
					mcWaveBx *= 1.5;
					waveBlur.blurX = mcWaveBx;
					if (mcWaveBx > 200) {
						mcWave.removeMovieClip();
						mcWave = null;
					}
				}

				moveMonster();

				if (FL_CHEAT)
					updateCheat();
		}
	}

	// (a copy of the list: a sprite created during the loop waits until the next frame, a sprite killed during the
	// loop is still updated if it comes later)
	function moveSprites() {
		var list = sList.copy();
		for (i in 0...list.length) {
			list[i].update();
		}
	}

	/*************************************************
	 *										Monster Handler
	 **************************************************/
	function moveMonster() {
		var flTurn = false;
		var ymax:Float = 0;
		for (i in 0...monsterList.length) {
			var monster = monsterList[i];
			if (!monster.flKamikaze) {
				monster.x += direction * mSpeed * Timer.tmod;
				if ((monster.x < (0 + monster.ray)) || (monster.x > (300 - monster.ray))) {
					flTurn = true;
					// (for each monster past an edge: a column that turns speeds the wave up several times)
					if (mSpeed < MAXSPEED) {
						mSpeed += (mSpeed / monsterList.length) / 5;
					}
				}
				ymax = Math.max(monster.y, ymax);
			}
		}
		if (flTurn) {
			direction *= -1;
			for (i in 0...monsterList.length) {
				var monster = monsterList[i];
				monster.y += fValue;
			}
		}
		var warningMargin = 20;
		if (ymax + warningMargin > mcLim._y && mcLim._currentframe == 1) {
			mcLim.gotoAndStop("2");
		}
		if (ymax + warningMargin < mcLim._y && mcLim._currentframe == 2) {
			mcLim.gotoAndStop("1");
		}
		if (monsterList.length == 0) {
			initStep(0);
		}
	}

	function initMonsters() {
		zeLevel++;
		difficulty = difficulty + (difficulty / 4) + (Math.round(Seed.rand() * (difficulty)));
		// init la speed ( pk pas augmenter au fur et a mesure...)
		mSpeed = BASESPEED;
		waveGenerator();
	}

	function waveGenerator() {
		if (zeLevel < 12) {
			var waveTest = 1 + Seed.random(4);
			switch (waveTest) {
				case 1:
					waveMirror();
				case 2:
					waveSide();
				case 3:
					waveHole();
				case 4:
					waveTop();
			}
		} else {
			waveBoss();
		}
	}

	/******************************************************************************** WAVE NORMAL*/
	// (not used by the original: waveGenerator calls the mirrored waves)
	function waveNormal() {
		diffLevel = difficulty;
		for (y in 0...ymRange) {
			for (x in 0...xmRange) {
				var nbMonsterLeft = totalMonster - monsterList.length;
				putMonster(MONSTERLEVELMAX - 1, nbMonsterLeft, x, y);
			}
		}
	}

	function putMonster(mLevel:Int, nbMonsterLeft:Int, x:Int, y:Int):Void {
		// (never below 0: the weakest monster always fits, see putMonsterMirror)
		if (mLevel < 0)
			return;
		var diffLeft:Int;
		if (mLevel == 0) {
			diffLeft = (MONSTERS[mLevel].diff) * (nbMonsterLeft - 1) + (MONSTERS[mLevel].diff);
		} else {
			diffLeft = (MONSTERS[mLevel - 1].diff) * (nbMonsterLeft - 1) + (MONSTERS[mLevel].diff);
		}
		if (diffLeft <= diffLevel) {
			initMonster(MONSTERS[mLevel].mc, mLevel, x, y);
			diffLevel = diffLevel - MONSTERS[mLevel].diff;
		} else {
			putMonster(mLevel - 1, nbMonsterLeft, x, y);
		}
	}

	/******************************************************************************** WAVE MIRROR*/
	function waveMirror() {
		diffLevel = Math.round(difficulty / 2);
		var nbMonsterLeft = Math.round(totalMonster / 2);
		for (y in 0...ymRange) {
			var x = 0;
			while (x < (xmRange / 2)) {
				if ((x != 0) || (y != 0)) {
					if ((x != 0) || (y != 3)) {
						putMonsterMirror(MONSTERLEVELMAX - 1, nbMonsterLeft, x, y);
						nbMonsterLeft--;
					}
				}
				x++;
			}
		}
	}

	function putMonsterMirror(mLevel:Int, nbMonsterLeft:Int, x:Int, y:Int):Void {
		// (never below 0: diffLevel stays at least the number of monsters left, which the weakest one needs)
		if (mLevel < 0)
			return;
		var diffLeft:Int;
		if (mLevel == 0) {
			diffLeft = (MONSTERS[mLevel].diff) * (nbMonsterLeft - 1) + (MONSTERS[mLevel].diff);
		} else {
			diffLeft = (MONSTERS[mLevel - 1].diff) * (nbMonsterLeft - 1) + (MONSTERS[mLevel].diff);
		}
		if (diffLeft <= diffLevel) {
			var xprime = (xmRange - 1 - x);
			// (a pair costs the difficulty of one monster)
			if (y == 3) {
				initMonster(MONSTERS[0].mc, 0, x, y);
				initMonster(MONSTERS[0].mc, 0, xprime, y);
				diffLevel = diffLevel - MONSTERS[mLevel].diff;
			} else {
				initMonster(MONSTERS[mLevel].mc, mLevel, x, y);
				initMonster(MONSTERS[mLevel].mc, mLevel, xprime, y);
				diffLevel = diffLevel - MONSTERS[mLevel].diff;
			}
		} else {
			putMonsterMirror(mLevel - 1, nbMonsterLeft, x, y);
		}
	}

	/******************************************************************************** WAVE SIDER */
	function waveSide() {
		diffLevel = Math.round(difficulty / 2);
		var nbMonsterLeft = Math.round(totalMonster / 2) - 5;
		var x = 0;
		while (x < (xmRange / 2)) {
			for (y in 0...ymRange) {
				if ((x != 1)) {
					if ((x != 2) || (y != 3)) {
						putMonsterMirror(MONSTERLEVELMAX - 1, nbMonsterLeft, x, y);
						nbMonsterLeft--;
					}
				}
			}
			x++;
		}
		putMonsterMirror(MONSTERLEVELMAX - 1, nbMonsterLeft, 1, 3);
	}

	/******************************************************************************** WAVE SIDER */
	function waveHole() {
		diffLevel = Math.round(difficulty / 2);
		var nbMonsterLeft = Math.round(totalMonster / 2) - 2;
		var x = 0;
		while (x < (xmRange / 2)) {
			for (y in 0...ymRange) {
				if ((x != 2) || (y != 3)) {
					if ((x != 0) || (y != 0)) {
						putMonsterMirror(MONSTERLEVELMAX - 1, nbMonsterLeft, x, y);
						nbMonsterLeft--;
					}
				}
			}
			x++;
		}
	}

	/******************************************************************************** WAVE TOP */
	function waveTop() {
		diffLevel = Math.round(difficulty / 2);
		var nbMonsterLeft = Math.round(totalMonster / 2) - 1;
		for (y in 0...ymRange) {
			var x = 0;
			while (x < (xmRange / 2)) {
				if ((y != 1) || (x != 0)) {
					putMonsterMirror(MONSTERLEVELMAX - 1, nbMonsterLeft, x, y);
					nbMonsterLeft--;
				}
				x++;
			}
		}
	}

	function waveBoss() {
		var monster = new Monster(dm.attach("mcBoss", 8), 5);
		monster.tx = 120;
		monster.ty = 60;

		diffLevel = 240;
		var nbMonsterLeft = 4;
		var x = 0;
		while (x < (xmRange / 2)) {
			for (y in 0...ymRange) {
				if (x != 1) {
					if (x != 2) {
						putMonsterMirror(MONSTERLEVELMAX - 1, nbMonsterLeft, x, y);
						nbMonsterLeft--;
					}
				}
			}
			x++;
		}
	}

	function initMonster(mc:String, mType:Int, x:Int, y:Int) {
		var monster = new Monster(dm.attach("" + mc + "", mType + 5), mType + 1);
		monster.tx = Cs.MARGE + x * 40;
		monster.ty = Cs.MARGE + y * 35;
	}

	// FX
	function initBurbulisseur() {
		burb = [];
		for (i in 0...2) {
			var mc = dm.empty(0);
			var h = 90 + i * 20;
			// mc.bmp = new BitmapData(Cs.mcw, mc.h, true, 0x00000000); mc.attachBitmap(mc.bmp, 0)
			var b = new Burb(mc, i, h);
			mc._y = Cs.mch + 30 - h;
			burb.push(b);
		}
	}

	// (the random of the bubbles only makes pictures: the visual random)
	function updateBurbulisseur() {
		// var bubble = dm.attach("mcSmallBubble", 0) ... bubble.removeMovieClip(): only drawn into the bitmaps, attached
		// and removed in the same frame (never shown)
		for (i in 0...burb.length) {
			var mc = burb[i];
			if (Seed.randVfx() / Timer.tmod < 1 / (i + 1)) {
				var sc = (0.6 + Seed.randVfx() * 0.8) * (i * 0.5 + 0.5);
				mc.draw(sc, Seed.randVfx() * Cs.mcw, mc.h - 20);
			}
			// colorTransform(alpha offset -(3 + i)) and scroll(0, -(i + 1))
			mc.endFrame();
		}

		if (Seed.randVfx() / Timer.tmod < burb.length * 0.1) {
			var p = new Part(dm.attach("mcSmallBubble", 8));
			p.x = Seed.randVfx() * Cs.mcw;
			p.y = Cs.mch + 40;
			p.vy = -(1 + Seed.randVfx() * 2);
			p.setScale(50 + Seed.randVfx() * 50);
			p.timer = 40 + Seed.randVfx() * 40;
			p.fadeType = 0;
		}
	}

	// (the frame rate of KadoKadeo is steady: Timer.tmod stays 0.8, no bitmap is dropped)
	function updateGfxMode() {
		if (Timer.tmod > 1.4) {
			lagTimer += Timer.tmod;
			if (lagTimer > 16) {
				lagTimer = -150;
				var mc = burb.pop();
				if (mc != null)
					mc.dispose();
			}
		} else {
			if (lagTimer > 0) {
				lagTimer -= Timer.tmod;
			} else {
				lagTimer += Timer.tmod;
			}
		}
	}

	// mcScore with field.text = KKApi.val(sc) and GlowFilter(2, 2, strength 5, white): the clip of that score (text and
	// glow baked)
	public function dispScore(sc:KKConst, x:Float, y:Float) {
		var p = new Part(dm.attach("score" + KKApi.val(sc), 8));
		p.x = x;
		p.y = y;
		p.vy = -3.5;
		p.frict = 0.95;
		p.timer = 30;
	}

	// CHEAT
	function updateCheat() {
		if (flReady > 0)
			flReady--;
		if ((KeyboardManager.isDown(KeyboardManager.ENTER)) && (flReady == 0)) {
			flReady = 10;
			var tempList = monsterList.copy();
			monsterList = new Array();
			for (i in 0...tempList.length) {
				tempList[i].explode();
			}
		}
	}

	// (moveMonster2, the "SPACE INVADERS move algo" left in the "DUMP" section of the original, is never called: not
	// ported)
	// ---------------------------------------------------------------- port

	// KKApi.addScore: nothing after the game over
	public function addScore(n:KKConst) {
		if (over)
			return;
		KadoKadeoManager.kkm.addScore(KKApi.val(n));
	}

	// KKApi.gameOver({}) (the hero's death)
	public function gameOver() {
		if (over)
			return;
		over = true;
		#if debug
		untyped js.Browser.window.__over = debugState();
		#end
		KadoKadeoManager.kkm.gameOver({});
	}

	// the first use of a filter compiles its shader: the glow, the blur of the title and the colour of the hero's flash
	// are drawn once now, off screen (the bubble bitmaps compile their own)
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var holder = new Container();
		var s = new PixiSprite(Texture.WHITE);
		var cm = new ColorMatrixFilter();
		cm.matrix = [0.5, 0, 0, 0, 0.1, 0, 0.5, 0, 0, 0.1, 0, 0, 0.5, 0, 0.1, 0, 0, 0, 1, 0];
		s.filters = [new FlashGlow(3, 3, 1, 0xFFFFFF), new BoxBlurX(10), cm];
		holder.addChild(s);
		var rt:Dynamic = (cast RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	public function stageRoot():ASprite {
		return root;
	}

	// the bubble bitmaps, just before the screen is drawn
	function flushBitmaps() {
		if (burb != null)
			for (b in burb)
				b.flush();
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

	// one Flash frame: the timelines advance, then Manager.main (tmod ~0.8: Timer settles on 32 / 40), then the frame
	// scripts the code triggered
	function flashFrame() {
		Timer.tmod = 32 / FLASH_FPS;
		MC.frameStart();
		Clip.deferring = true;
		main();
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
	function debugState():Dynamic {
		var ms = 0.0;
		for (m in monsterList)
			ms += m.x * 7 + m.y;
		var ss = 0.0;
		for (s in shotList)
			ss += s.x * 7 + s.y;
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			wave: zeLevel + 1,
			step: step,
			hx: hero.x,
			dead: hero.dead,
			monsters: monsterList.length,
			msum: Math.round(ms * 1000) / 1000,
			shots: shotList.length,
			ssum: Math.round(ss * 1000) / 1000,
			bonuses: bonusList.length,
			mSpeed: Math.round(mSpeed * 1e6) / 1e6,
			dif: difficulty,
			heroType: hero.type,
			heroSpeed: hero.speed,
			fireRate: hero.fireRate,
			stats: haxe.Json.stringify(stats),
			over: over,
		};
	}

	// test harness (modes/oursouinvader.js): a bonus of type t falling from (x, y), like the one of a monster
	public function debugBonus(t:Int, x:Float, y:Float) {
		var b = new Bonus(null);
		b.bType = t;
		b.root.gotoAndStop(t + 1);
		b.x = x;
		b.y = y;
		b.updatePos();
	}

	// test harness: the wave of the start replaced by wave w at difficulty d (before the first frame)
	public function debugWave(w:Int, d:Float) {
		for (m in monsterList.copy()) {
			m.root.removeMovieClip();
			m.kill();
		}
		zeLevel = w - 2;
		difficulty = d;
		initStep(0);
	}

	// test harness: clips drawn by the runtime on a page ([name, frame, x, y, scale, {nested instance: frame, __glow:
	// [colour, alpha, blur, strength]}]), to compare with the SWF (examples/oursouinvader/ncheck.mjs, ref.py)
	public function debugShow(list:Array<Array<Dynamic>>, bgColor:Int) {
		var stage:Dynamic = untyped KadoKadeoManager.kkm.stage;
		var box = new ASprite();
		var g = box.getGraphics();
		g.beginFill(bgColor);
		g.drawRect(0, 0, 600, 640);
		g.endFill();
		// the random first frames of the nested clips on their first frame, like the reference
		Clip.random = n -> 0;
		for (o in list) {
			var c = new Clip(o[0], 2);
			for (pass in 0...2) {
				if (pass == 1)
					c.gotoAndStop(o[1]);
				if (o.length > 5)
					for (k in Reflect.fields(o[5])) {
						if (k == "__glow")
							continue;
						var sub = c.getClip(k);
						if (sub != null)
							sub.gotoAndStop(Reflect.field(o[5], k));
					}
			}
			Clip.runLater();
			c._x = o[2];
			c._y = o[3];
			c._xscale = c._yscale = o[4] * 100;
			// a GlowFilter set by the code: [colour, alpha, blur, strength]
			var gl:Array<Float> = o.length > 5 ? Reflect.field(o[5], "__glow") : null;
			if (gl != null)
				c.filters = [new FlashGlow(gl[2], gl[2], gl[3], Std.int(gl[0]), gl[1])];
			box.addChild(c);
		}
		Clip.random = Seed.randomVfx;
		box.updateState();
		box.updateGraphics(1);
		stage.addChild(box);
	}
	#end

	public function destroy():Void {
		if (flushListener != null) {
			var ticker:Dynamic = KadoKadeoManager.kkm.ticker;
			ticker.remove(flushListener);
			flushListener = null;
		}
		if (burb != null)
			for (b in burb)
				b.dispose();
		burb = null;
		me = null;
		MC.clearAll();
		Clip.reset();
	}
}
