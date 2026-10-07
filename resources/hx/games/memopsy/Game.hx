package memopsy;

import haxe.io.UInt16Array;
import memopsy.Gfx.GoodMC;
import memopsy.MC.Plans;

@:expose('GameMemopsy')
class Game implements kado.GameInterface {
	// the original's 300 x 300 pixels, drawn x2
	public static inline var K = 2;
	// Memopsy ran in the KadoKado loader at 40 frames/s (Timer.wantedFPS = 32: tmod ~0.8)
	public static inline var FRAME_RATE = 40;

	public var dmanager:Plans;

	var level:Array<Array<Card>>;
	var life:Array<MC>;
	var oldlife:Array<MC>;
	var bg_mc:MC;
	var bg_speed:Float;
	var current:Card;
	var maxpairs:Int;
	var npairs:Int;
	var nlevel:Int;
	var nmiss:Int;
	var lock:Int;

	var time:Float;
	var pair_time:Float;
	var times:Array<Int>;

	// KadoKadeo
	var isReplay:Bool;
	var root:MC;
	var buttons:Buttons;
	// mouse in the root's coordinates (the cards' onPress hit test)
	var xmouse:Float = 0;
	var ymouse:Float = 0;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	// mt.Timer of the Flash player at 40 frames/s: deltaT = 25 ms, tmod smoothed from 1 towards 32 / 40
	var calcTmod:Float = 1;
	var overSent:Bool = false;
	var handCursor:Bool = false;
	var onPointerDown:Dynamic;

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		// a game is its clicks: one {k, x, y} event per press on a card (a byte each), no mouse stream
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});
		// one page plays several games and replays: the clips and the statics of the previous one go
		MC.clearAll();
		Card.cards = [];
		mt.Timer.tmod = 1;
		mt.Timer.deltaT = 1 / FRAME_RATE;
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

		root = new MC(null, 1 / K);
		root.posK = K;
		mc.addChild(root.spr);
		buttons = new Buttons(root);
		readMouse();

		// original: new(mc)
		dmanager = new Plans(root);
		dmanager.attach("bg", Const.PLAN_BG);
		bg_speed = 0;
		bg_mc = dmanager.attach("bgAnim", Const.PLAN_BG);
		bg_mc._x = 150;
		bg_mc._y = 150;
		time = 0;
		lock = 0;
		nlevel = 0;
		nmiss = 0;
		pair_time = 0;
		times = new Array();
		initLevel();
		initLife();
		MC.displayAll(1);
	}

	function shuffle(tbl:Array<Int>) {
		var l = tbl.length;
		for (i in 0...l) {
			var a = Seed.random(l);
			var b = Seed.random(l);
			var s = tbl[a];
			tbl[a] = tbl[b];
			tbl[b] = s;
		}
	}

	public function getLevel() {
		var l = (nlevel >= Const.LEVELS.length) ? (Const.LEVELS.length - 1) : nlevel;
		return Const.LEVELS[l];
	}

	function initLevel() {
		var ids = new Array();
		var l = getLevel();
		var w = l.width;
		var h = l.height;

		npairs = Std.int(w * h / 2);
		maxpairs = npairs;

		for (i in 0...npairs) {
			var id = i % Const.NUMCARDS;
			ids.push(id);
			ids.push(id);
		}
		shuffle(ids);

		var n = 0;
		level = new Array();
		for (x in 0...w) {
			level[x] = new Array();
			for (y in 0...h)
				level[x][y] = new Card(this, ids[n++], x, y);
		}
	}

	function destroyLevel() {
		var l = getLevel();
		for (x in 0...l.width)
			for (y in 0...l.height)
				level[x][y].destroy();
	}

	function initLife() {
		life = new Array();
		oldlife = new Array();
		for (i in 0...Const.MAXLIFE)
			addLife();
		for (i in 0...Const.MAXLIFE - Const.STARTLIFE)
			looseLife();
	}

	function addLife() {
		if (life.length == Const.MAXLIFE)
			return;

		if (oldlife.length == 0) {
			var l = dmanager.attach("life", Const.PLAN_LIFE);
			var x = 150 - 0.5 * Const.MAXLIFE * (Data.LIFE_WIDTH + 1);
			l._x = x + life.length * (Data.LIFE_WIDTH + 1);
			l._y = 2;
			l.stop();
			life.push(l);
		} else {
			var l = oldlife.shift();
			l.gotoAndStop(1);
			// (already out of the list: the original removes it again, nothing happens)
			oldlife.remove(l);
			life.push(l);
		}
	}

	function looseLife() {
		var l = life[life.length - 1];
		life.remove(l);
		l.gotoAndStop(2);
		oldlife.unshift(l);
		if (life.length == 0) {
			gameOver();
			return;
		}
	}

	function cardSelect(c:Card) {
		if (lock > 1 || c.visible)
			return;
		if (lock == 1 && current != null)
			return;
		lock++;
		c.show(true);
	}

	function bonusTime() {
		// (the original's score for the level time is commented out: only the reset stays)
		time = 0;
	}

	function bonusPair() {
		var t = Std.int(Math.min(pair_time, Const.POINTS.length - 1));
		if (t < 0)
			t = 0;
		addScore(Const.POINTS[t]);
		times.push(t);
		pair_time = -0.3;
		nmiss = 0;
	}

	function gameOver() {
		if (!overSent) {
			overSent = true;
			#if debug
			// test harness: state of the game at its end (compared between a game and its replay)
			untyped js.Browser.window.__over = debugState();
			#end
			KadoKadeoManager.kkm.gameOver({l: nlevel, t: times});
		}
		lock = 99;
	}

	public function onShowDone(c:Card) {
		lock--;
		if (c.visible) {
			if (current == null)
				current = c;
			else {
				if (current.id != c.id) {
					current.show(false);
					c.show(false);
					lock += 2;
					looseLife();
					nmiss++;
					#if debug
					cov.miss++;
					#end
				} else {
					npairs--;
					bonusPair();
					nmiss = 0;
					#if debug
					cov.pairs++;
					#end
					if (npairs == 0) {
						for (i in 0...5)
							addLife();
						destroyLevel();
						nlevel++;
						initLevel();
						bonusTime();
						#if debug
						cov.levels++;
						#end
					} else {
						explode(current.mcface._x, current.mcface._y);
						explode(c.mcface._x, c.mcface._y);
					}
				}
				current = null;
			}
		}
	}

	function explode(x:Float, y:Float) {
		var fx = dmanager.add(new GoodMC(), Const.PLAN_FX);
		fx._x = x;
		fx._y = y;
	}

	function main() {
		time += mt.Timer.deltaT;
		pair_time += mt.Timer.deltaT;
		bg_speed = bg_speed * 0.95 + (npairs + 1) * 0.05;
		bg_mc._rotation += mt.Timer.tmod * bg_speed;
		Card.main(this);
	}

	// ---------------------------------------------------------------- KadoKadeo
	public function update(delta:Float) {
		// Flash played Memopsy at 40 frames/s: one Manager.main per Flash frame. KadoKadeo steps 32 times per
		// second: 5 Flash frames every 4 steps
		frameAcc += 5;
		var first = true;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame(first);
			first = false;
		}
		MC.displayAll(frameAcc / 4);
		setHandCursor(buttons.over != null && buttons.over.useHandCursor);
	}

	// one Flash frame: the mouse events (between two frames), the playheads, then Manager.main (Timer.update, main)
	function flashFrame(first:Bool) {
		frameCount++;
		MC.snapshotAll();
		if (isReplay) {
			// the presses of the replay, on the frame (step) the player made them
			if (first)
				for (e in KadoKadeoManager.kkm.replay.consumeEvents())
					applyReplayEvent(e);
		} else {
			readMouse();
			var changes = [];
			if (first)
				for (c in MouseManager.getFrameButtonChanges())
					if (c.button == MouseManager.BUTTON_LEFT)
						changes.push(c.isDown);
			buttons.frame(xmouse, ymouse, changes);
		}
		MC.advanceAll();
		// mt.Timer.update at 40 frames/s: deltaT 25 ms, tmod = tmod * 0.95 + 0.05 * deltaT * wantedFPS (from 1: the
		// Timer starts with the game)
		calcTmod = calcTmod * 0.95 + (1 - 0.95) * (1 / FRAME_RATE) * 32;
		mt.Timer.deltaT = 1 / FRAME_RATE;
		mt.Timer.tmod = calcTmod;
		main();
		#if debug
		if (testHook != null)
			testHook();
		#end
	}

	// the mouse over the game in Flash pixels
	function readMouse() {
		xmouse = Math.max(0, MouseManager.getX()) / K;
		ymouse = Math.max(0, MouseManager.getY()) / K;
	}

	// ---------------------------------------------------------------- replay
	// a press over a card (mc.onPress): recorded for the frame (step) being played as one byte ({k, x, y}: the grid is
	// at most 6 x 4), the replay gives it back on the same frame (applyReplayEvent), then the original's cardSelect
	public function pressCard(c:Card) {
		if (!isReplay) {
			var replay = KadoKadeoManager.kkm.replay;
			replay.recordEvent({k: 0, x: c.cx, y: c.cy}, replay.getCurrentFrame());
		}
		cardSelect(c);
	}

	function applyReplayEvent(e:Dynamic) {
		if (e == null || e.k != 0)
			return;
		var x:Int = e.x;
		var y:Int = e.y;
		var l = getLevel();
		if (x < 0 || x >= l.width || y < 0 || y >= l.height)
			return;
		cardSelect(level[x][y]);
	}

	// ---------------------------------------------------------------- KKApi
	// KKApi.addScore: nothing after the game over is sent
	public function addScore(n:Int) {
		if (!overSent)
			KadoKadeoManager.kkm.addScore(n);
	}

	// the cards' useHandCursor (live games only: the cursor of the page)
	function setHandCursor(on:Bool) {
		if (isReplay || on == handCursor)
			return;
		handCursor = on;
		var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
		if (canvas != null)
			canvas.style.cursor = on ? "pointer" : "";
	}

	#if debug
	// test harness: called after each Flash frame (test modes)
	public var testHook:Void->Void;
	// what the game went through (coverage of the bots, compared between a game and its replay)
	public var cov = {pairs: 0, miss: 0, levels: 0};

	public function debugState():Dynamic {
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			time: Math.round(time * 1e6) / 1e6,
			pairTime: Math.round(pair_time * 1e6) / 1e6,
			nlevel: nlevel,
			npairs: npairs,
			maxpairs: maxpairs,
			nmiss: nmiss,
			lock: lock,
			lives: life.length,
			times: times.join(","),
			grid: gridState(),
			anims: Card.cards.length,
			bgr: Math.round(bg_mc._rotation * 1e6) / 1e6,
			bgs: Math.round(bg_speed * 1e6) / 1e6,
			cov: cov,
		};
	}

	function gridState():String {
		var l = getLevel();
		var out = [];
		for (y in 0...l.height)
			for (x in 0...l.width) {
				var c = level[x][y];
				out.push(c.id + (c.visible ? "+" : c.mcface._visible ? "^" : "-"));
			}
		return out.join(",");
	}

	// the comparison pages (modes/memopsy.js test=show&page=N, examples/memopsy/ref.py draws them from the SWF):
	// 0: the 11 frames of the card, the 9 of the flip (top on a face), the 5 of the good flash, the 2 life beads;
	// 1: the start of a game (bg, bgAnim turned, the 4 x 2 grid with a face shown, the 10 lives). The game is not
	// updated afterwards
	public function debugShow(page:Int):Void {
		for (c in root.children.copy())
			c.removeMovieClip();
		Card.cards = [];
		var dm = new Plans(root);
		if (page == 0) {
			dm.attach("bg", 0);
			for (k in 0...11) {
				var c = dm.add(new Gfx.CardMC(), 1);
				c.gotoAndStop(k + 1);
				c._x = 4 + 50 * (k % 6);
				c._y = k < 6 ? 6 : 78;
			}
			for (k in 0...9) {
				var f = dm.add(new Gfx.FlipMC(), 1);
				f.gotoAndStop(k + 1);
				f.top.gotoAndStop(8);
				f.back.stop();
				f._x = 4 + 33 * k;
				f._y = 150;
			}
			for (k in 0...5) {
				var g = dm.add(new GoodMC(), 1);
				g.stop();
				g.gotoAndStop(k + 1);
				g._x = 8 + 50 * k;
				g._y = 222;
			}
			for (k in 0...2) {
				var l = dm.attach("life", 1);
				l.gotoAndStop(k + 1);
				l._x = 260 + 16 * k;
				l._y = 230;
			}
		} else {
			dm.attach("bg", 0);
			var b = dm.attach("bgAnim", 0);
			b._x = 150;
			b._y = 150;
			b._rotation = 30;
			var px = (300 - 4 * 50 + 8) / 2;
			var py = (290 - 2 * 70 + 6) / 2 + 10;
			for (x in 0...4)
				for (y in 0...2) {
					var c = dm.add(new Gfx.CardMC(), 2);
					c.gotoAndStop(x == 1 && y == 1 ? 5 : 1);
					c._x = px + x * 50;
					c._y = py + y * 70;
				}
			for (k in 0...10) {
				var l = dm.attach("life", 3);
				l.gotoAndStop(1);
				l._x = 150 - 0.5 * Const.MAXLIFE * (Data.LIFE_WIDTH + 1) + k * (Data.LIFE_WIDTH + 1);
				l._y = 2;
			}
		}
		MC.snapshotAll();
		MC.displayAll(1);
	}
	#end

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		setHandCursor(false);
		MC.clearAll();
		Card.cards = [];
	}
}
