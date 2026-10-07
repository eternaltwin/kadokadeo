package julianus;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchButtonShape;
import kado.TouchControlsConfig.TouchControlsMode;
#if debug
import julianus.Hero.BlowMC;
import julianus.Hero.HeroMC;
import julianus.Pic.PicMC;
import julianus.Pic.SpikesMC;
#end

typedef Stats = {
	bo:Array<Int>, // bonuses
	b:Int, // bulles
	f:Int, // fusions
	p:Int, // pics
	k:Int, // bulles separate
	d:Int, // dist
}

@:expose('GameJulianus')
class Game implements kado.GameInterface {
	public static inline var K = 2;

	// Flash played Julianus at 40 frames/s (the rate of the SWF) with mt.Timer.wantedFPS = 32: tmod = 0.8 and
	// Timer.deltaT = 1 / 40, one main() per Flash frame (see update). Several things happen once per Flash frame
	// without tmod (speed_delta subtracted from the speed, collisions, particles): 40 per second, like the original
	public static inline var FRAME_RATE = 40;
	public static inline var TMOD = 0.8;
	public static inline var DELTA_T = 0.025;

	// the mouse steers (a finger moves it: a touch outside the button is not a click) and the button blows (SPACE)
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		passthroughMouseButtons: false,
		buttons: [
			{
				id: "blow",
				label: "💨",
				rightPx: 20,
				bottomPx: 20,
				size: 90,
				keyCode: KeyboardManager.SPACE,
				shape: TouchButtonShape.CIRCLE,
			},
		],
	};

	// ZQSD / WASD move like the arrows, Enter blows like SPACE
	public static var KEY_ALIASES = KeyboardManager.ALIASES_MOVE.concat(KeyboardManager.ALIASES_ENTER_SPACE);

	public var mc:MC;
	public var dmanager:Plans;
	public var hero:Hero;

	var bg:Bg;

	public var bulles:Array<Bulle>;
	public var pics:Array<Pic>;
	public var kills:Array<Pic>;
	public var bcount:Int;

	var pcount:Int;
	var time:Float;

	public var speed:Float;
	public var speed_delta:Float;

	var game_over:Bool = false;
	var dist:Float;

	public var stats:Stats;

	var isReplay:Bool;
	var over:Bool = false;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	// mouse as last seen by the game (canvas pixels), to send onMouseMove when it moves
	var mouseX:Int = -1;
	var mouseY:Int = -1;
	var onPointerDown:Dynamic;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		var keys = new UInt16Array(5);
		keys[0] = KeyboardManager.LEFT;
		keys[1] = KeyboardManager.RIGHT;
		keys[2] = KeyboardManager.UP;
		keys[3] = KeyboardManager.DOWN;
		keys[4] = KeyboardManager.SPACE;
		var buttons = new UInt16Array(1);
		buttons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: keys,
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: buttons,
		});
		MC.clearAll();
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

		// the original's 300x300 pixels, drawn x2
		mc = new MC(null, 1 / K);
		mc.posK = K;
		root.addChild(mc.spr);

		bcount = 0;
		pcount = 0;
		dist = 0;
		speed = 0;
		speed_delta = 0;
		time = 0;
		kills = new Array();
		dmanager = new Plans(mc);
		bg = new Bg(this);
		hero = new Hero(this);
		bulles = new Array();
		pics = new Array();
		bulles.push(new Bulle(this, 150, 150));
		stats = {
			p: 0,
			bo: [0, 0, 0],
			f: 0,
			b: 0,
			k: 0,
			d: 0,
		};
		for (i in 0...8)
			genPic(300);
	}

	// bg.onPress / onRelease / onReleaseOutside
	function press(flg:Bool):Void {
		hero.action = flg;
	}

	// bg.onMouseMove
	function onMove(x:Float, y:Float):Void {
		hero.tx = x - mc._x;
		hero.ty = y - mc._y;
	}

	// the mouse events of the Flash player, from the mouse polled at the start of the step (recorded by the replay,
	// clamped to >= 0 like its recorder): a move sends onMouseMove (only inside the stage, or while the button is
	// held: the player keeps the mouse then), a press on the stage (bg covers it) onPress, a release onRelease
	function pollMouse():Void {
		var x = MouseManager.getX();
		var y = MouseManager.getY();
		if (x < 0)
			x = 0;
		if (y < 0)
			y = 0;
		var inStage = x < 300 * K && y < 300 * K;
		if (frameCount == 0) {
			// Hero.new: tx = game.mc._xmouse...
			mouseX = x;
			mouseY = y;
			hero.initMouse(x / K - mc._x, y / K - mc._y);
		}
		if (x != mouseX || y != mouseY) {
			mouseX = x;
			mouseY = y;
			if (inStage || MouseManager.isButtonDown(MouseManager.BUTTON_LEFT))
				onMove(x / K, y / K);
		}
		for (c in MouseManager.getFrameButtonChanges()) {
			if (c.button != MouseManager.BUTTON_LEFT)
				continue;
			if (!c.isDown)
				press(false);
			else if (inStage)
				press(true);
		}
	}

	function genPic(dx:Int):Void {
		pcount++;
		stats.p++;
		if (Seed.random(10) == 0)
			genPic(dx);
		var x, y;
		while (true) {
			x = Seed.random(250 + dx) + 320;
			y = Seed.random(300) + 10;
			var ok = true;
			for (i in 0...pics.length) {
				var p = pics[i];
				var ddx = p.px - x;
				var dy = p.py - y;
				if (ddx * ddx + dy * dy < 400) {
					ok = false;
					break;
				}
			}
			if (ok) {
				var id = 0;
				// (bcount 0 at the start: random(-10) is 0 in Flash, like Seed.random: the first bonuses are sure)
				if (pcount > 20 && Seed.random(5) == 0) {
					id = 1;
					if (x > 360 && pcount > 50 && Seed.random(3) == 0)
						id = 2;
				} else if (Seed.random(10 * (bcount - 1)) == 0) {
					bcount++;
					id = 3 + randomProbas([20, 4, 1]);
				}
				pics.push(new Pic(this, id, x, y));
				break;
			}
		}
	}

	// Tools.randomProbas
	static function randomProbas(a:Array<Int>):Int {
		var n = 0;
		var i = a.length - 1;
		while (i >= 0)
			n += a[i--];
		n = Seed.random(n);
		i = 0;
		while (n >= a[i]) {
			n -= a[i];
			i++;
		}
		return i;
	}

	function genBulle():Void {
		var ntrys = 10;
		while (ntrys-- > 0) {
			var x = Seed.random(200) + 50;
			var ok = true;
			for (i in 0...pics.length) {
				var p = pics[i];
				if (p.py < 100 && p.px > x - 30 && p.px < x + 30) {
					ok = false;
					break;
				}
			}
			if (ok) {
				stats.b++;
				bulles.push(new Bulle(this, x, -20));
				return;
			}
		}
	}

	// pop: the burst of a bubble, at the resolution of its size (see Bulle.showLevel); the 9th frame removes it
	public function attachPop(x:Float, y:Float, size:Float):Void {
		var lv = Data.POP_LEVELS;
		var i = level(lv, size);
		var p = dmanager.attach("pop" + Std.int(lv[i] * 100), Const.PLAN_PART, K * lv[i]);
		p.playing = true;
		p.removeAt = 9;
		p._x = x;
		p._y = y;
		p._xscale = size;
		p._yscale = size;
	}

	// the picture of a clip drawn at size % (bulle, pop): the first resolution (in scale) not below it, else the last
	public static function level(levels:Array<Float>, size:Float):Int {
		var i = 0;
		while (i < levels.length - 1 && levels[i] * 100 < size)
			i++;
		return i;
	}

	public function addScore(n:Int):Void {
		// (no points after the end of the game)
		if (over)
			return;
		KadoKadeoManager.kkm.addScore(n);
	}

	public function update(delta:Float):Void {
		pollMouse();
		// 5 Flash frames every 4 steps (see FRAME_RATE)
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			MC.frameStart();
			main();
			frameCount++;
			if (frameCount == 1)
				MC.snapAll();
		}
		MC.displayAll(frameAcc / 4);
	}

	function main():Void {
		var i;
		var dx = -(TMOD * ((hero.px < 150) ? 0.5 : (hero.px / 300)));
		var p = Const.POW_080;
		speed_delta += 0.000025 * TMOD;
		speed = speed * p + dx * (1 - p) - speed_delta;
		dist += speed;
		time += DELTA_T;
		if (!game_over && time > 1) {
			var pts = 0.0;
			for (i in 0...bulles.length)
				pts += bulles[i].size / 9;
			while (time > 1) {
				addScore(KKApi.val(KKApi.const(Std.int(pts) * 5)));
				time -= 1;
				if (Seed.random(10 * bulles.length + Std.int(pcount / 3)) == 0)
					genBulle();
			}
		}
		// (index loops: an element removed during its update makes the next one wait for the next frame, like the
		// original; the lists grow during the loops)
		i = 0;
		while (i < bulles.length) {
			bulles[i].update(speed);
			i++;
		}
		i = 0;
		while (i < pics.length) {
			if (!pics[i].update(speed)) {
				genPic(0);
				pics.splice(i--, 1);
			}
			i++;
		}
		i = 0;
		while (i < kills.length) {
			if (!kills[i].updateKill(speed))
				kills.splice(i--, 1);
			i++;
		}
		if (bulles.length == 0) {
			game_over = true;
			stats.d = Std.int(-dist);
			gameOver();
		}
		hero.update();
		bg.update(speed);
	}

	// KKApi.gameOver(stats), called by main() on every frame without bubbles: once
	function gameOver():Void {
		if (over)
			return;
		#if debug
		// test harness: state of the game at its end (compared between a game and its replay)
		var sz = 0.0;
		for (p in pics)
			sz += p.px * 7 + p.py * 3;
		untyped js.Browser.window.__over = {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			hx: hero.px,
			hy: hero.py,
			ang: hero.ang,
			speed: speed,
			dist: dist,
			pics: pics.length,
			picsHash: sz,
			bcount: bcount,
			pcount: pcount,
			stats: haxe.Json.stringify(stats)
		};
		#end
		KadoKadeoManager.kkm.gameOver({
			"$bo": stats.bo,
			"$b": stats.b,
			"$f": stats.f,
			"$p": stats.p,
			"$k": stats.k,
			"$d": stats.d
		});
		over = true;
	}

	#if debug
	// test harness: a page of clips in given states drawn by the game's runtime, over a plain colour (jcheck.mjs; the
	// same pages rendered from the SWF by ref.py)
	public function debugShow(items:Array<Dynamic>, bgColor:Int):Void {
		var stage:Dynamic = untyped KadoKadeoManager.kkm.stage;
		var box = new ASprite();
		var g = box.getGraphics();
		g.beginFill(bgColor);
		g.drawRect(0, 0, 600, 640);
		g.endFill();
		var dr = new MC(null, 1 / K);
		dr.posK = K;
		box.addChild(dr.spr);
		function hero(it:Dynamic):MC {
			var h = new HeroMC();
			h.body.gotoAndStop(it.bf);
			h.body._rotation = it.r;
			return h;
		}
		function blow(it:Dynamic):MC {
			var b = new BlowMC();
			b.gotoAndStop(it.f);
			for (p in b.puffs)
				p.gotoAndStop(it.pf);
			return b;
		}
		for (it in (items : Array<Dynamic>)) {
			var list:Array<MC> = switch (it.k) {
				case "hero": [hero(it)];
				case "eyes":
					var e = new MC("eyes");
					e.gotoAndStop(it.f);
					[e];
				case "blow": [blow(it)];
				case "full":
					// hero, blow, then the eyes put over (Hero.update)
					var e = new MC("eyes");
					e.gotoAndStop(it.f);
					[hero(it), blow(it), e];
				case "pic":
					var p = new PicMC();
					p.gotoAndStop(it.f);
					if (it.f == 2) {
						var sub:SpikesMC = cast p.sub;
						if (it.blur != null) {
							sub.gotoAndStop(2);
							sub.blur.blur._rotation = it.br;
							sub.blur.blur.gotoAndStop(it.bf);
						} else
							sub._rotation = it.r;
					}
					if (it.f == 3) {
						p.sub._x = it.dx;
						p.sub._y = it.dy;
					}
					[p];
				case "bonus":
					var m = new MC("bonus" + it.n);
					m.gotoAndStop(it.f);
					[m];
				case "bulle":
					var lv = Data.BULLE_LEVELS[level(Data.BULLE_LEVELS, it.size)];
					var m = new MC("bulle" + Std.int(lv * 100), K * lv);
					[m];
				case "pop":
					var lv = Data.POP_LEVELS[level(Data.POP_LEVELS, it.size)];
					var m = new MC("pop" + Std.int(lv * 100), K * lv);
					m.gotoAndStop(it.f);
					[m];
				case "part":
					var m = new MC("part", K * 4);
					m.gotoAndStop(it.f);
					[m];
				default:
					var m = new MC(it.k);
					m.gotoAndStop(it.f);
					[m];
			}
			for (mc in list) {
				dr.attach(mc);
				mc._x = it.x;
				mc._y = it.y;
				var s:Float = it.size != null ? it.size : it.s != null ? it.s : 100;
				mc._xscale = it.xs != null ? it.xs : s;
				mc._yscale = it.ys != null ? it.ys : s;
			}
		}
		MC.displayAll(1);
		stage.addChild(box);
		box.updateGraphics(1);
	}
	#end

	public function destroy():Void {
		MC.clearAll();
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
	}
}
