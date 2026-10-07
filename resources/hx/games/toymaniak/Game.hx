package toymaniak;

import haxe.io.UInt16Array;
import toymaniak.Gfx.BoxMC;
import toymaniak.Gfx.SlotMC;
import toymaniak.MC.Plans;

@:expose('GameToyManiak')
class Game implements kado.GameInterface {
	// the original's 300 x 300 pixels, drawn x2
	public static inline var K = 2;
	// Toy Maniak ran in the KadoKado loader at 40 frames/s (Timer.wantedFPS = 32: tmod ~0.8)
	public static inline var FRAME_RATE = 40;

	public var dmanager:Plans;

	var rails:Array<Rail>;
	var sels:Array<SlotMC>;

	// (the stats of the original are null: `stats = null; /*{$c, $b, $s}*/`, every push into them did nothing)
	var stats:Dynamic;

	var cursor:Toy;

	var nbrokens:Int;

	public var time:Float;
	public var speed:Float;
	public var nbonuses:Int;

	// KadoKadeo
	var isReplay:Bool;
	var root:MC;
	var buttons:Buttons;
	// mouse in the root's coordinates (Std.xmouse / Std.ymouse)
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
		var mouseButtons = new UInt16Array(1);
		mouseButtons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: mouseButtons,
		});
		// one page plays several games and replays: the clips and the statics of the previous one go
		MC.clearAll();
		Toy.resetToys();
		#if debug
		// test harness: Toy.TOYS for the test modes (modes/toymaniak.js)
		untyped js.Browser.window.ToyManiakToy = Toy;
		#end
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
		if (Seed.random(500) == 0)
			Toy.TOYS[3] = 3;
		else if (Seed.random(1000) == 0)
			Toy.TOYS[3] = 11;
		else if (Seed.random(5000) == 0)
			Toy.TOYS[3] = 10;

		dmanager = new Plans(root);
		dmanager.add(new MC("bg"), 0);
		time = 0;
		nbonuses = 0;
		speed = 1;

		var box = dmanager.add(new BoxMC(), 0);
		box._x = 150;
		box._y = 300;
		nbrokens = 0;

		stats = null;

		rails = new Array();
		for (i in 0...3)
			rails[i] = new Rail(this, i);

		sels = [box.s0, box.s1, box.s2];
		for (i in 0...3) {
			var s = sels[i];
			s.t = Seed.random(Const.NELEMENTS);
			s.gotoAndPlay(SlotMC.FALL);
			s.onPress = selectSlot.bind(i);
			updateToy(s, i);
		}
		MC.displayAll(1);
	}

	function updateToy(s:SlotMC, i:Int) {
		s.toy.gotoAndStop(Toy.TOYS[s.t]);
		s.toy.but._alpha = 0;
	}

	function initCursor(t:Int) {
		cursor = new Toy(this, t, null, true);
		cursor.mc.but._visible = false;
		dmanager.swap(cursor.mc, 3);
		updateCursor();
	}

	function selectSlot(i:Int) {
		var s = sels[i];

		if (s.t == -1) {
			if (cursor == null)
				return;
			#if debug
			cov.putSlot++;
			#end
			s.t = cursor.t;
			cursor.destroy();
			cursor = null;
			s.gotoAndStop(16);
			updateToy(s, i);
			return;
		}

		if (cursor == null) {
			#if debug
			cov.takeSlot++;
			#end
			initCursor(s.t);
			s.t = -1;
			s.gotoAndPlay(SlotMC.EMPTY);
		} else {
			#if debug
			cov.swapSlot++;
			#end
			var ot = s.t;
			s.t = cursor.t;
			cursor.setType(ot);
			updateToy(s, i);
		}
	}

	public function selectToy(t:Toy) {
		if (t.lock)
			return;

		if (cursor == null) {
			if (t.t == -1)
				return;
			#if debug
			cov.take++;
			#end
			initCursor(t.t);
			t.setType(-1);
		} else {
			if (t.t == -1) {
				#if debug
				cov.put++;
				#end
				t.setType(cursor.t);
				cursor.destroy();
				cursor = null;
			} else {
				#if debug
				cov.swap++;
				#end
				var ot = cursor.t;
				cursor.setType(t.t);
				t.setType(ot);
			}
		}
	}

	function updateCursor() {
		// (no toy in hand: cursor.mc is undefined in Flash, nothing happens)
		if (cursor == null)
			return;
		var b = cursor.mc.getBounds();
		cursor.mc._x = xmouse - (b.xMin + b.xMax) / 2;
		cursor.mc._y = ymouse - (b.yMin + b.yMax) / 2 - 10;
	}

	function main() {
		time += mt.Timer.deltaT;
		var ok = false;
		for (i in 0...rails.length)
			if (rails[i].update())
				ok = true;
		if (cursor != null && cursor.t != -1)
			ok = true;
		if (sels[0].t != -1 || sels[1].t != -1 || sels[2].t != -1)
			ok = true;

		updateCursor();
		if (time >= Const.GAMETIME && !ok) {
			// (stats.$c[i].push(rails[i].ncombos): stats is null)
			gameOver();
		}
	}

	// ---------------------------------------------------------------- KadoKadeo
	public function update(delta:Float) {
		// Flash played Toy Maniak at 40 frames/s: one Manager.main per Flash frame. KadoKadeo steps 32 times per
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
		readMouse();
		var changes = [];
		if (first)
			for (c in MouseManager.getFrameButtonChanges())
				if (c.button == MouseManager.BUTTON_LEFT)
					changes.push(c.isDown);
		buttons.frame(xmouse, ymouse, changes);
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

	// Std.xmouse / ymouse: the mouse over the game in Flash pixels (the replay records it)
	function readMouse() {
		xmouse = Math.max(0, MouseManager.getX()) / K;
		ymouse = Math.max(0, MouseManager.getY()) / K;
	}

	// KKApi.addScore: nothing after the game over is sent
	public function addScore(n:Int) {
		if (!overSent)
			KadoKadeoManager.kkm.addScore(n);
	}

	// KKApi.gameOver(stats) (called every frame by the original once over: the loader keeps the first)
	function gameOver() {
		if (overSent)
			return;
		overSent = true;
		#if debug
		// test harness: state of the game at its end (compared between a game and its replay)
		untyped js.Browser.window.__over = debugState();
		#end
		KadoKadeoManager.kkm.gameOver({});
	}

	// toy.but.useHandCursor (live games only: the cursor of the page)
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
	public var cov = {x2: 0, plus20: 0, speed: 0, breaks: 0, cap: 0, takeSlot: 0, putSlot: 0, swapSlot: 0, take: 0, put: 0, swap: 0};

	// the comparison pages (modes/toymaniak.js test=show&page=N, examples/toymaniak/ref.py draws them from the SWF):
	// 0: the 23 frames of the toy, the slot on 6 frames of its animations, the 10 frames of the lights; 1: two rails with
	// their cruncher at 2 heights, the treads moved, toys between back and front. The game is not updated afterwards
	public function debugShow(page:Int):Void {
		for (c in root.children.copy())
			c.removeMovieClip();
		var dm = new Plans(root);
		dm.add(new MC("bg"), 0);
		if (page == 0) {
			for (k in 0...11) {
				var t = dm.add(new Gfx.ToyMC(), 1);
				t.gotoAndStop(k + 1);
				t._x = 30 + 48 * (k % 6);
				t._y = k < 6 ? 55 : 115;
			}
			var sl:Array<Array<Int>> = [[2, 1], [5, 2], [9, 3], [16, 8], [19, 0], [22, 0]];
			for (k in 0...sl.length) {
				var s = dm.add(new SlotMC(), 1);
				s.gotoAndStop(sl[k][0]);
				if (s.toy != null)
					s.toy.gotoAndStop(sl[k][1]);
				s._x = 27 + 49 * k;
				s._y = 165;
			}
			for (k in 0...10) {
				var g = dm.add(new Gfx.Light("green"), 1);
				g.gotoAndStop(k + 1);
				g._x = 15 + 28 * k;
				g._y = 215;
				var r = dm.add(new Gfx.Light("red"), 1);
				r.gotoAndStop(k + 1);
				r._x = 15 + 28 * k;
				r._y = 245;
			}
		} else {
			var rails:Array<Array<Float>> = [[80, -303, -305, -32.5, 150, 2], [200, -307, -301, -15, 38, 7]];
			for (r in rails) {
				var back = dm.add(new Gfx.RailBackMC(), 0);
				back._x = 300;
				back._y = r[0];
				back.field.text = "";
				var t = dm.add(new Gfx.ToyMC(), 1);
				t.gotoAndStop(Std.int(r[5]));
				t._x = r[4];
				t._y = r[0];
				var front = dm.add(new Gfx.RailFrontMC(), 2);
				front._x = 300;
				front._y = r[0];
				front.t0._x = r[1];
				front.t1._x = r[2];
				front.cruncher._y = r[3];
			}
		}
		MC.snapshotAll();
		MC.displayAll(1);
	}

	public function debugState():Dynamic {
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			time: time,
			tmod: mt.Timer.tmod,
			nbonuses: nbonuses,
			combos: [for (r in rails) r.ncombos],
			rails: [for (r in rails) @:privateAccess r.toys.map(t -> t.t + ":" + t.x).join(",")],
			sels: [for (s in sels) s.t + "@" + s._currentframe],
			cursor: cursor == null ? null : cursor.t,
			toys: Toy.TOYS.join(","),
			cov: cov,
		};
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
		Toy.resetToys();
	}
}
