package hexile;

import haxe.io.UInt16Array;
import hexile.MC.Plans;
import hexile.Socle.HexMC;
import pixi.core.Pixi.BlendModes;
import pixi.core.display.Container;
import pixi.core.textures.Texture;
import pixi.filters.alpha.AlphaFilter;

typedef Move = {sc:Float, h:Socle}

enum HexType {
	Beach;
	Dirt;
	Mountain;
}

enum Step {
	Play;
	Jump;
	Convert;
	GameOver;
}

// mcCastle: the island top of the castle (its base: frame 1, smc frame 2, a random texture), the soldiers of the turn
// placed by its base, and the counter of the moves left (field)
class Castle extends MC {
	public var base:CastleBase;
	public var field:Digits;

	public function new(?tex:Int) {
		super();
		// the texture of its base: gotoAndStop(random(_totalframes) + 1), a picture only
		attach(new MC("castle")).gotoAndStop(tex != null ? tex : Seed.randomVfx(7) + 1);
		base = cast attach(new CastleBase());
		base._x = Data.CASTLE_BASE[0];
		base._y = Data.CASTLE_BASE[1];
		base._yscale = Data.CASTLE_BASE[2] * 100;
		field = cast attach(new Digits(Data.DIG_CASTLE));
	}
}

// the base of mcCastle (sprite 35): frame 1 + the soldiers still to jump; the soldiers it places run
// _parent._parent._obj.register(this) on their first frame: castle._obj.register of Game.initPlay, which gives them
// the frame (colour) of the team that plays, at their place in the timeline (not rounded like Socle.register)
class CastleBase extends MC {
	public var frame(default, null):Int = 1;
	public var register:Int = 1;

	public function gotoFrame(f:Int) {
		if (f < 1)
			f = 1;
		if (f > 11)
			f = 11;
		if (f == frame)
			return;
		frame = f;
		for (c in children.copy())
			c.removeMovieClip();
		for (it in Data.BASE_DIRT[f - 1]) {
			var m:MC;
			if (it[0] == 1) {
				m = attach(new MC("shade"));
				m._alpha = it[3] * 100;
			} else {
				var sol = new hexile.Socle.SoldierMC();
				sol.setTeam(register - 1);
				m = attach(sol);
			}
			m.showNow = true;
			m._x = it[1];
			m._y = it[2];
		}
	}

	public function prevFrame() {
		gotoFrame(frame - 1);
	}
}

// mcMsg: its smc (the text field, with the GlowFilter of Game.newMsg baked) drops in and stops on frame 10; "leave"
// (11) takes it out, removeMovieClip() on frame 17 (the yscale 0.9988 of the smc's placement is left out: 0.05 px)
class Msg extends MC {
	var smc:MC;

	public function new(text:Int) {
		super();
		_totalframes = 17;
		playing = true;
		stopAt = 10;
		removeAt = 17;
		smc = attach(new MC("msg"));
		smc.gotoAndStop(text + 1);
		smc._x = 150;
		smc._y = Data.MSG_Y[0];
	}

	override function onFrame() {
		smc._y = Data.MSG_Y[_currentframe - 1];
	}

	public function leave() {
		gotoAndPlay(11);
		onFrame();
	}

	#if debug
	public function debugFrame(f:Int) {
		gotoAndStop(f);
		onFrame();
	}
	#end
}

// mcInter with Filt.glow(inter, 2, 1, 0): the black glow of the bar and of its two counters (with their own glows)
// under them
class Inter extends MC {
	var fields:Array<Digits>;
	var glows:Array<Digits>;

	public function new() {
		super();
		attach(new MC("interG"));
		glows = [
			cast attach(new Digits(Data.DIG_INTER0, [Data.DIG_INTER0.anim + "G"])),
			cast attach(new Digits(Data.DIG_INTER1, [Data.DIG_INTER1.anim + "G"]))
		];
		attach(new MC("inter"));
		fields = [cast attach(new Digits(Data.DIG_INTER0)), cast attach(new Digits(Data.DIG_INTER1))];
	}

	#if debug
	public function debugGlow(on:Bool) {
		children[0]._visible = on;
		for (g in glows)
			g._visible = on;
	}
	#end

	// Reflect.field(inter, "_field" + team).text = s
	public function setField(team:Int, s:String) {
		fields[team].setText(s);
		glows[team].setText(s);
	}
}

@:expose('GameHexile')
class Game implements kado.GameInterface {
	// texture pixels per Flash pixel: the original's 300 x 300 pixels drawn x2
	public static inline var K = 2;
	// Flash played Hexile at 40 frames/s (the rate of the SWF) with Timer.wantedFPS = 32: tmod = 0.8
	public static inline var FRAME_RATE = 40;

	public static var MODE_CLONE = false;

	public static var FL_QUICK = false;
	public static var FL_DEBUG = false;

	public static var PMIN = 1;
	public static var PMAX = 6;

	public static var CMAX = 17;

	public static inline var DP_BG = 0;
	public static inline var DP_HEX = 1;
	public static inline var DP_SHADE = 2;
	public static inline var DP_QUEUE = 3;
	public static inline var DP_SOLDAT = 4;
	public static inline var DP_PARTS = 5;
	public static inline var DP_INTER = 6;

	public static var CX = 2;
	public static var CY = 2;

	var flWin:Bool;
	var flBlink:Bool;

	var step:Step;
	var ssum:Int;
	var ia:Int;

	public var count:Int;

	var gstep:Int;

	var coef:Float;

	public var turn:Int;

	public var library:Array<Array<Int>>;

	public var scores:Array<Int>;
	public var grid:Array<Array<Socle>>;
	public var socles:Array<Socle>;
	public var work:Array<Socle>;
	public var blinks:Array<Socle>;
	public var hex:Socle;
	public var soldats:Array<Soldat>;

	public var inter:Inter;
	public var castle:Castle;
	public var msg:Msg;

	public static var me:Game;

	public var dm:Plans;
	public var gdm:MC;
	public var sdm:MC;
	public var rdm:MC;
	public var ground:MC;
	public var root:MC;
	public var bg:SeaBitmap;

	// ---------------------------------------------------------------- port
	var isReplay:Bool;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	var over:Bool = false;
	// the score of KKApi (setScore / getScore of the original)
	var score:Int = 0;
	// mouse (Flash buttons): the hex under the pointer, the hex pressed, whether the pointer is still over it
	var hovered:Socle;
	var pressed:Bool = false;
	var pressTarget:Socle;
	var pressInside:Bool = false;
	var onPointerDown:Dynamic;
	var shadeFilter:AlphaFilter;
	#if debug
	// test harness: what the game went through (window.__over)
	public var stats:Dynamic;
	#end
	var rayFilter:AlphaFilter;

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: UInt16Array.fromArray([MouseManager.BUTTON_LEFT]),
		});
		// statics of the original (the SWF was loaded again for every game)
		CX = 2;
		CY = 2;
		MC.clearAll();
		Sprite.spriteList = [];
		#if debug
		// test harness (modes/hexile.js, map=<n>): another island than the one of the debug seed, the same in a game
		// and in its replay
		if (untyped js.Browser.window.__hexileMap != null)
			Seed.init(untyped js.Browser.window.__hexileMap);
		stats = {plouf: 0, conv: 0, renf: 0, mount: 0};
		#end
		// like the Flash player, a hex pressed keeps the mouse while the button is held (its release outside the game
		// is still seen)
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
		me = this;
		dm = new Plans(root);

		flBlink = true;

		// PLACE CX
		while (true) {
			CX = Seed.random(20);
			CY = Seed.random(20);
			var flBreak = isInBorder(CX, CY, 1);
			var dx = Math.abs(6 - CX);
			var dy = Math.abs(6 - CY);
			var r = 2;
			if (dx < r && dy < r)
				flBreak = false;
			if (flBreak)
				break;
		}

		// BG
		var mc = dm.empty(DP_BG);
		bg = new SeaBitmap(0x4278AC);
		bg.attachTo(mc);

		// GROUND
		ground = dm.empty(DP_HEX);
		gdm = ground;

		// SHADE: _alpha 30 on the plane, blendMode "layer": the shades are drawn together, then at 30 %
		var mc = dm.empty(DP_SHADE);
		shadeFilter = new AlphaFilter(0.3);
		mc.spr.filters = [shadeFilter];
		sdm = mc;

		// RAY: blendMode "add" on the plane: the rays drawn together, then added
		var mc = dm.empty(DP_QUEUE);
		rayFilter = new AlphaFilter(1);
		untyped rayFilter.blendMode = BlendModes.ADD;
		mc.spr.filters = [rayFilter];
		rdm = mc;

		scores = [];
		scores[0] = 0;
		scores[1] = 0;
		ssum = 0;

		initInter();

		// IA
		ia = 1;

		if (Seed.random(3) == 0)
			ia--;
		while (Seed.random(5) == 0)
			ia++;
		// (flash.System.setClipboard(ia), and inter._field: a field mcInter does not have)

		initGrid();
		buildLibrary();

		turn = 0;
		initPlay();

		MC.displayAll(1);
		warmShaders();
	}

	// INIT
	public function initGrid() {
		var max = 11;
		socles = [];
		grid = [];
		soldats = [];

		for (x in 0...max)
			grid[x] = [];
		var cx = 6;
		var cy = 6;

		newSocle(cx, cy);

		for (i in 0...CMAX * 2 - 1) {
			var list = [];
			for (h in socles) {
				for (d in Cs.DIR) {
					var x = h.x + d[0];
					var y = h.y + d[1];
					if (cell(x, y) == null && isIn(x, y))
						list.push({x: x, y: y});
				}
			}
			var p = list[Seed.random(list.length)];
			newSocle(p.x, p.y);
		}
		for (x in 0...max)
			for (y in 0...max)
				if (grid[x][y] != null)
					gdm.toTop(grid[x][y].root);

		terraforming();
	}

	function newSocle(x:Int, y:Int) {
		var mc:Socle = new Socle(x, y);
	}

	public function isIn(x:Int, y:Int) {
		var dx = Math.abs(x - CX);
		var dy = Math.abs(y - CY);
		var r = 1;
		return isInBorder(x, y, 0) && (dx > r || dy > r);
	}

	public function isInBorder(x:Int, y:Int, m:Int) {
		return x - y < 5 - m && y - x < 5 - m && x + y > 2 + m && x + y < 17;
	}

	// grid[x][y]: undefined outside the grid in Flash
	public function cell(x:Int, y:Int):Socle {
		var c = grid[x];
		return c == null ? null : c[y];
	}

	// LIBRARY
	public function buildLibrary() {
		library = [];

		var base = [6, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 1, 1,];

		if (FL_QUICK)
			base = [1, 2, 3, 4, 5, 6];

		for (i in 0...2) {
			var a = base.copy();
			var lib = [];
			while (a.length > 0) {
				var index = Seed.random(a.length);
				lib.push(a[index]);
				a.splice(index, 1);
			}
			library.push(lib);
		}
	}

	// TERRAFORMING
	public function terraforming() {
		//
		var beachLim = 7 + Seed.random(3);
		var mountLim = 5 + Seed.random(12);

		// BEACH
		for (h in socles)
			h.seekSea();
		for (h in socles) {
			var sea = h.dataSea * 2.0;
			var a = h.getNeighbors();
			for (h2 in a)
				sea += h2.dataSea * 0.5;
			if (sea + Seed.random(2) > beachLim && h.dataSea > 0) {
				h.setType(Beach);
			} else {
				h.setType(Dirt);
			}
			if (Seed.random(mountLim) == 0) {
				h.setType(Mountain);
			}
		}

		// PAINT BG

		newSocle(CX, CY);

		// BIG BLUE
		var hexes = [for (c in gdm.children) (cast c : HexMC).socle];
		bg.drawGround(hexes, 100, 16, 0x5188BF);

		// RIVAGE
		for (h in socles) {
			var i = 0;
			for (d in Cs.DIR) {
				var x = h.x + d[0];
				var y = h.y + d[1];
				if (cell(x, y) == null) {
					// m.rotate(i * 6.28 / 6); m.scale(1.01, 1.01); m.translate(...): pictures of the 6 rotations, its
					// random frame (a picture only), brush.smc._alpha 100 on a beach, 40 otherwise
					var frame = Seed.randomVfx(5) + 1;
					bg.drawBrush(h.type == Beach ? "brushB" : "brushD", i * 5 + frame, Cs.getX(x, y), Cs.getY(x, y));
				}
				i++;
			}
		}
		socles.pop();

		// CASTLE
		castle = dm.add(new Castle(), DP_HEX);
		castle._x = Cs.getX(CX, CY);
		castle._y = Cs.getY(CX, CY);
	}

	// PLAY
	function initPlay() {
		step = Play;
		coef = 0;
		turn = 1 - turn;
		var a = library[turn];

		if (a.length == 0) {
			initGameOver();
			return;
		}

		var index = Seed.random(a.length);
		count = a[index];
		a.splice(index, 1);

		var fr = turn + 1;
		castle.base.register = fr;
		castle.base.gotoFrame(count + 1);

		var h = library[0].length + library[1].length;
		if (h == 0) {
			newMsg("DERNIER COUP");
		}
		castle.field.setText(Std.string(h));

		if (turn == 0) {
			for (h in socles) {
				if (h.team == null)
					grid[h.x][h.y].active();
			}
		}
	}

	function updatePlay() {
		coef += 0.05 * mt.Timer.tmod;

		flBlink = !flBlink;
		if (blinks != null)
			for (h in blinks) {
				for (sol in h.soldats) {
					sol.setBlink(flBlink);
				}
			}

		if (turn == 1 && coef >= 1)
			autoPlay();
	}

	function autoPlay() {
		var list:Array<Move> = [];
		for (h in socles) {
			if (h.team == null) {
				var score = [0.5, 1, 0][Type.enumIndex(h.type)];
				for (d in Cs.DIR) {
					var nx = h.x + d[0];
					var ny = h.y + d[1];
					var h2 = cell(nx, ny);
					if (h2 == null) {
						score -= 0.5;
					} else if (h2.team == null) {
						score -= 0.5;
					} else if (h2.team == 1) {
						score += Math.min(h2.n * 0.25, 3);
					} else if (h2.team == 0) {
						if (h2.n < count)
							score += Cs.q(Math.pow(h2.n, 1.5));
						else
							score -= 1;
					}
				}
				list.push({sc: score, h: h});
			}
		}

		var f = function(a:Move, b:Move) {
			if (a.sc > b.sc)
				return -1;
			return 1;
		}
		sort(list, f);

		var rlist = [];
		var n = -9999.9;
		var bads = ia;
		for (o in list) {
			bads--;
			if (o.sc < n && bads < 0)
				break;
			n = o.sc;
			rlist.push(o);
		}

		initJump(rlist[Seed.random(rlist.length)].h);
	}

	// JUMP
	public function initJump(hex:Socle) {
		if (msg != null)
			newMsg();

		step = Jump;
		this.hex = hex;
		hex.team = turn;
		var max = Socle.getMax(hex.type);
		var n = 0;

		for (i in 0...count) {
			var sol = new Soldat(turn);
			sol.id = n;
			sol.x = castle._x;
			sol.y = castle._y - 16;
			sol.initJump(n >= max);
			n++;
		}

		for (h in socles)
			grid[h.x][h.y].unactive();
	}

	function updateJump() {
		for (sol in soldats)
			if (sol.step == 1)
				return;
		initConvert();
	}

	// CONVERT
	function initConvert() {
		step = Convert;
		coef = 0;
		work = [];

		var fill = hex.getRenfort(hex.n - 1);
		var clist = hex.getConvert(hex.n);
		#if debug
		stats.conv += clist.length;
		stats.renf += fill.length;
		if (hex.type == Mountain)
			stats.mount++;
		#end
		for (h in clist) {
			h.swapTeam();
			work.push(h);
		}

		for (h in fill) {
			var sol = new Soldat(turn);
			sol.id = 0;
			sol.x = Cs.getX(hex.x, hex.y);
			sol.y = Cs.getY(hex.x, hex.y);
			sol.initJump(false, h);
			sol.jh = 40;
			hex.incSoldat(-1);
		}
	}

	function updateConvert() {
		if (soldats.length == 0) {
			majScore();
			initPlay();
		}
	}

	// GAMEOVER
	function initGameOver() {
		step = GameOver;
		coef = 0;

		flWin = scores[0] >= scores[1];
		gstep = 0;

		for (h in socles) {
			if (h.team == (flWin ? 0 : 1)) {
				for (mc in h.soldats) {
					// (Std.random: the dance is a picture only)
					mc.dance(Seed.randomVfx(10) + 1);
				}
			}
		}
	}

	function updateGameOver() {
		switch (gstep) {
			case 0:
				coef += 0.01;
				if (msg == null && coef > 0.5) {
					if (flWin) {
						addScore(Cs.SCORE_VICTORY);
						newMsg("+" + KKApi.val(Cs.SCORE_VICTORY) + " pts");
					}
				}
				if (coef >= 1) {
					gstep = 10;
					coef = 0;
				}

			case 10:
				if (coef == 0) {
					coef = 1;
					work = [];
					for (h in socles)
						if (h.team == 0)
							work.push(h);
					newMsg("BONUS");
				}

				// (no hex of the player: work[0] is undefined, undefined.n > 0 is false)
				var h = work[0];
				if (h != null && h.n > 0) {
					h.incSoldat(-1);
					addScore(Cs.SCORE_ALLY);
					h.fxStar();
				} else {
					work.shift();
					if (work.length == 0) {
						coef = 0;
						newMsg();
						gstep++;
					}
				}

			case 11:
				coef += 0.04;
				if (coef > 1) {
					gameOver();
					gstep++;
				}
		}
	}

	// SCORE
	function majScore() {
		var sc = KKApi.const(0);
		for (h in socles) {
			if (h.team == 0) {
				sc = KKApi.cadd(sc, Cs.SCORE_HEX[Type.enumIndex(h.type)]);
			}
		}
		setScore(sc);
	}

	// INTER
	function initInter() {
		inter = dm.add(new Inter(), DP_INTER);
		incTeamScore(0, 0);
		incTeamScore(1, 0);
	}

	public function incTeamScore(team:Int, inc:Int) {
		scores[team] += inc;
		inter.setField(team, Std.string(scores[team]));

		ssum = scores[0] + scores[1];
	}

	// TOOLS
	function newMsg(?str:String) {
		if (msg != null) {
			msg.leave();
			msg = null;
			if (str == null)
				return;
		}
		if (str == null)
			return;
		msg = dm.add(new Msg(Data.MSGS.indexOf(str.toUpperCase())), DP_INTER);
	}

	// UPDATE
	public function update(delta:Float) {
		// Flash played Hexile at 40 frames/s (the rate of the SWF) with Timer.wantedFPS = 32: tmod = 0.8, one
		// update() per Flash frame. KadoKadeo steps 32 times per second: 5 Flash frames every 4 steps. The mouse
		// events of the step come between two Flash frames, like Flash's
		mt.Timer.tmod = 32 / FRAME_RATE;
		updateMouse();
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame();
		}
		MC.displayAll(frameAcc / 4);
	}

	function flashFrame() {
		MC.frameStart();
		main();
		frameCount++;
	}

	// update() of the original: one Flash frame
	function main() {
		updateSprites();
		switch (step) {
			case Play:
				updatePlay();
			case Jump:
				updateJump();
			case Convert:
				updateConvert();
			case GameOver:
				updateGameOver();
		}
	}

	function updateSprites() {
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.update();
	}

	public function decScore(n:Int) {
		var sc = KKApi.val(score);
		var dec = KKApi.val(n);
		sc = Std.int(Math.max(0, sc - dec));
		setScore(KKApi.const(sc));
	}

	// ---------------------------------------------------------------- port: score (KKApi)
	public function addScore(n:Int) {
		setScore(score + n);
	}

	function setScore(n:Int) {
		if (over)
			return;
		var d = n - score;
		score = n;
		if (d != 0)
			KadoKadeoManager.kkm.addScore(d);
	}

	function gameOver() {
		if (over)
			return;
		#if debug
		// test harness: state of the game at its end (compared between a game and its replay)
		var owned = [0, 0];
		for (h in socles)
			if (h.team != null)
				owned[h.team]++;
		untyped js.Browser.window.__over = {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			s0: scores[0],
			s1: scores[1],
			h0: owned[0],
			h1: owned[1],
			ia: ia,
			cx: CX,
			cy: CY,
			win: flWin,
			stats: haxe.Json.stringify(stats)
		};
		#end
		KadoKadeoManager.kkm.gameOver({});
		over = true;
	}

	// ---------------------------------------------------------------- port: mouse
	// The hexes are Flash buttons (Socle: onRollOver / onDragOver = rover, onRollOut / onDragOut = rout, onRelease =
	// select, enabled on the player's turn). The pointer is polled once per step (the replay records it): the hex under
	// it is the topmost enabled one whose picture covers it (a disabled clip does not catch the mouse).
	function updateMouse() {
		var mx = Math.max(0, MouseManager.getX());
		var my = Math.max(0, MouseManager.getY());
		var under = hexAt((mx + 0.5) / K, (my + 0.5) / K);
		if (!pressed) {
			if (under != hovered) {
				if (hovered != null)
					hovered.rout();
				hovered = under;
				if (hovered != null)
					hovered.rover();
			}
		}
		if (MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT)) {
			pressed = true;
			pressTarget = hovered;
			pressInside = pressTarget != null;
		}
		if (pressed && pressTarget != null) {
			var inside = under == pressTarget;
			if (inside != pressInside) {
				pressInside = inside;
				// onDragOver / onDragOut
				if (inside)
					pressTarget.rover();
				else
					pressTarget.rout();
				hovered = inside ? pressTarget : null;
			}
		}
		if (MouseManager.isButtonJustReleased(MouseManager.BUTTON_LEFT)) {
			var target = pressTarget;
			pressed = false;
			pressTarget = null;
			if (target != null && under == target) {
				hovered = null;
				// onRelease
				target.select();
			}
		}
		// a hex disabled under the pointer (the player's move is made) does not answer any more
		if (hovered != null && !hovered.enabled && !pressed)
			hovered = null;
	}

	function hexAt(fx:Float, fy:Float):Socle {
		var i = gdm.children.length - 1;
		while (i >= 0) {
			var s = (cast gdm.children[i] : HexMC).socle;
			if (s.enabled && s.hitTest(fx, fy))
				return s;
			i--;
		}
		return null;
	}

	// ---------------------------------------------------------------- port: tools
	// Array.sort with the comparators of the original (they never return 0): an insertion sort, the same in every
	// browser (the order of equal elements decides which hexes get the reinforcements and which moves the AI weighs;
	// the browsers' sorts differ on such comparators)
	public static function sort<T>(a:Array<T>, f:T->T->Int) {
		for (i in 1...a.length) {
			var v = a[i];
			var j = i - 1;
			while (j >= 0 && f(a[j], v) > 0) {
				a[j + 1] = a[j];
				j--;
			}
			a[j + 1] = v;
		}
	}

	// The first use of a filter compiles its shader (tens of ms of freeze): the AlphaFilter of the shade and ray
	// planes is drawn once now, off screen
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var holder = new Container();
		var s = new pixi.core.sprites.Sprite(Texture.WHITE);
		var f = new AlphaFilter(0.5);
		untyped f.blendMode = BlendModes.ADD;
		s.filters = [f, new AlphaFilter(0.3)];
		holder.addChild(s);
		var rt:Dynamic = (cast pixi.core.textures.RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	#if debug
	// test harness: a page of clips drawn by the runtime, over the game (examples/hexile/hcheck.mjs, compared with the
	// same page rendered from the SWF by ref.py). items: {k: "hex" | "castle" | "inter" | "msg" | "anim", x, y, ...}
	public function debugShow(items:Array<Dynamic>, bgColor:Int) {
		var stage:Dynamic = untyped KadoKadeoManager.kkm.stage;
		var box = new ASprite();
		var g = box.getGraphics();
		g.beginFill(bgColor);
		g.drawRect(0, 0, 600, 640);
		g.endFill();
		var dr = new MC(null, 1 / K);
		dr.posK = K;
		box.addChild(dr.spr);
		var oldGdm = gdm, oldGrid = grid, oldSocles = socles, oldCount = count;
		gdm = dr;
		grid = [for (i in 0...40) []];
		socles = [];
		count = 6;
		var gx = 0;
		for (it in items) {
			var mc:MC = null;
			switch (it.k) {
				case "hex":
					var s = new Socle(gx++, 0);
					var t = it.t == "D" ? Dirt : it.t == "M" ? Mountain : Beach;
					s.debugSet(t, it.v != null ? it.v : 0, it.tex != null ? it.tex : 1, it.h != null ? it.h : 0, it.n, it.team);
					if (it.bright)
						s.rover();
					if (it.blink)
						for (sol in s.soldats)
							sol.setBlink(true);
					mc = s.root;
				case "castle":
					var c = new Castle(it.tex);
					c.base.register = it.team + 1;
					c.base.gotoFrame(it.frame);
					if (it.text != null)
						c.field.setText(it.text);
					mc = dr.attach(c);
				case "inter":
					var i = new Inter();
					i.setField(0, it.a);
					i.setField(1, it.b);
					i.debugGlow(it.glow == true);
					mc = dr.attach(i);
				case "msg":
					var m = new Msg(it.i);
					m.debugFrame(it.f);
					mc = dr.attach(m);
				default:
					mc = dr.attach(new MC(it.a));
					mc.gotoAndStop(it.f != null ? it.f : 1);
					if (it.xs != null)
						mc._xscale = it.xs;
					if (it.r != null)
						mc._rotation = it.r;
			}
			mc._x = it.x;
			mc._y = it.y;
		}
		gdm = oldGdm;
		grid = oldGrid;
		socles = oldSocles;
		count = oldCount;
		MC.displayAll(1);
		box.updateState();
		box.updateGraphics(1);
		stage.addChild(box);
	}
	#end

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			if (canvas != null)
				canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		// the sea bitmap first: its sprite is in a plane MC.clearAll destroys
		if (bg != null)
			bg.destroy();
		bg = null;
		MC.clearAll();
		Sprite.spriteList = [];
		CX = 2;
		CY = 2;
	}
}
