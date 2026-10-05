package electrolink;

import electrolink.Gfx.Part;
import electrolink.Gfx.TimeLine;
import electrolink.MC.Plans;
import haxe.io.UInt16Array;

typedef Pos = {x:Int, y:Int}

enum Step {
	Play;
	Charge;
	Explode;
	Fall;
	GameOver;
}

@:expose('GameElectrolink')
class Game implements kado.GameInterface {
	// the original's 300 x 300 pixels, drawn x2
	public static inline var K = 2;
	// Electrolink ran in the KadoKado loader at 40 frames/s (Timer.wantedFPS = 32: tmod = 0.8)
	public static inline var FRAME_RATE = 40;

	public static var FL_DEBUG = true;

	public static var DP_BG = 0;
	public static var DP_SHADE = 1;
	public static var DP_GOALS = 4;
	public static var DP_TILES = 5;
	public static var DP_SCORING = 6;
	public static var DP_ANIM = 7;
	public static var DP_FX = 8;
	public static var DP_POINTS = 9;

	public static var DP_AMBIANT = 15;

	public var step:Step;
	public var flGameOver:Bool;
	public var dm:Plans;
	public var root:MC;
	public var bg:MC;
	public var mcScoring:Scoring;
	static public var me:Game;

	public var board:Array<Array<Tile>>;
	public var goals:Array<Array<Goal>>;

	var start:Tile;

	public var links:List<Tile>;
	public var toExplode:List<Tile>;
	public var toKill:List<Tile>;
	public var toApply:Array<{t:Tile, d:Int}>;

	var timer:Null<Float>;

	public var explode:Array<Int>;
	public var explosionCount:Int;
	public var combo:Int;

	public var falls:Array<Int>;

	public var lockTile:Bool;

	public var mcTime:TimeLine;
	public var cTile:Tile;

	// KadoKadeo
	var isReplay:Bool;
	var buttons:Buttons;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	// Flash frames played (flash.Lib.getTimer: 25 ms each)
	var frameCount:Int = 0;
	var overSent:Bool = false;
	var onPointerDown:Dynamic;

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
		// one page plays several games and replays: the statics of the original start again
		MC.clearAll();
		Sprite.spriteList = [];
		mt.Timer.tmod = 32 / FRAME_RATE;
		#if debug
		// test harness: the constants, for the test modes (modes/electrolink.js)
		untyped js.Browser.window.ElectrolinkCs = Cs;
		untyped js.Browser.window.ElectrolinkTextGfx = TextGfx;
		#end
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
		me = this;
		dm = new Plans(root);
		buttons = new Buttons(dm, [DP_AMBIANT, DP_POINTS, DP_FX, DP_ANIM, DP_SCORING, DP_TILES, DP_GOALS, DP_SHADE, DP_BG]);
		flGameOver = false;

		explode = [0, 0];
		explosionCount = 0;
		links = new List();

		initBg();
		initGoals();
		initBoard();
		initTime();
		initPlay();
		MC.displayAll(1);
		TextGfx.warm();
	}

	function initBg() {
		var bg = dm.add(new Bg(), DP_BG);
		bg._x = 0;
		bg._y = 0;
		this.bg = bg;

		mcScoring = dm.add(new Scoring(), DP_SCORING);
		mcScoring._x = Cs.mcw;
		mcScoring._y = Cs.mch - 20;

		// (embedFonts and the TextFormat "TexasLED": the fields are drawn with the glyphs of the SWF, TextGfx)

		mcScoring.gotoAndStop(1);
	}

	function initTime() {
		mcTime = Game.me.dm.add(new TimeLine(), Game.DP_GOALS);
		mcTime.start = getTimer();
		mcTime._x = Cs.TIME_X;
		mcTime._y = Cs.TIME_Y;
	}

	public function parse(tile:Tile, from:Int, checkState:Int) {
		if (tile.parsed)
			return;

		tile.parsed = true;
		if (checkState == Cs.PARSE_IN)
			links.add(tile);

		switch (checkState) {
			case 0:
				tile.setIn(); // PARSE_IN
			case 3:
				tile.setIn(); // PARSE_LIGHT
			case 1:
				tile.setOut(); // PARSE_OUT
		}

		for (i in 0...4) {
			if (Tile.sMod(i + 2, 4) == from)
				continue;

			var neighbour = getNeighbour(i, tile.pos);

			if (checkState == Cs.PARSE_IN && isGoal(tile, i)) {
				var side = if (tile.pos.x == 0) 0 else 1;
				goals[side][tile.pos.y].activate(checkState);
			}

			if (neighbour == null)
				continue;

			var neighbourIn = Tile.sMod(i + 2, 4);
			if (!(tile.pipes[i] && neighbour.pipes[neighbourIn])) // no link
				continue;

			parse(neighbour, i, checkState);
		}
	}

	public function isGoal(tile:Tile, dir:Int) {
		return ((tile.pos.x == Cs.BOARD_WIDTH - 1 && dir == Cs.EAST && tile.pipes[dir])
			|| (tile.pos.x == 0 && dir == Cs.WEST && tile.pipes[dir]));
	}

	public function resetLinks() {
		links = new List();
	}

	public function check(?t:Tile) {
		lock();
		resetParsing(true);
		for (t in board[0]) {
			if (!isConnected()) {
				resetLinks();
				resetExplode();
				resetGoalsActivation();
			}

			if (t.checkEdge(Cs.WEST)) {
				var mode = if (isConnected()) Cs.PARSE_LIGHT else Cs.PARSE_IN;
				goals[0][t.pos.y].activate(mode);
				parse(t, Cs.EAST, mode);
			} else
				goals[0][t.pos.y].shutdown();
		}

		if (!isConnected())
			resetExplode();

		for (t in board[Cs.BOARD_WIDTH - 1]) {
			if (t.checkEdge(Cs.EAST)) {
				if (goals[1][t.pos.y].toExplode)
					continue;
				goals[1][t.pos.y].activate(Cs.PARSE_OUT);
				parse(t, Cs.WEST, Cs.PARSE_OUT);
			} else
				goals[1][t.pos.y].shutdown();
		}

		if (isConnected()) {
			combo++;
			start = t;
			initCharge();
			return true;
		}
		unlock();
		return false;
	}

	public function isLocked() {
		return lockTile || flGameOver;
	}

	public function lock() {
		lockTile = true;
	}

	public function unlock() {
		lockTile = false;
	}

	// (out of the board: undefined in Flash, null here)
	public function getNeighbour(i:Int, p:Pos):Tile {
		switch (i) {
			case 0:
				return tileAt(p.x + 1, p.y); // EAST
			case 1:
				return tileAt(p.x, p.y + 1); // SOUTH
			case 2:
				return tileAt(p.x - 1, p.y); // WEST
			case 3:
				return tileAt(p.x, p.y - 1); // NORTH
			default:
				throw "unknown direction";
		}
	}

	inline function tileAt(x:Int, y:Int):Tile {
		var c = x >= 0 && x < board.length ? board[x] : null;
		return c != null && y >= 0 && y < c.length ? c[y] : null;
	}

	// ---------------------------------------------------------------- KadoKadeo
	public function update(delta:Float) {
		// Flash played Electrolink at 40 frames/s with Timer.wantedFPS = 32: tmod = 0.8, one update() per Flash frame.
		// KadoKadeo steps 32 times per second: 5 Flash frames every 4 steps
		mt.Timer.tmod = 32 / FRAME_RATE;
		frameAcc += 5;
		var first = true;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame(first);
			first = false;
		}
		MC.displayAll(frameAcc / 4);
	}

	// one Flash frame: playheads advance, the mouse events of the buttons, then the original update()
	function flashFrame(first:Bool) {
		frameCount++;
		MC.frameStart();
		var changes = [];
		if (first)
			for (c in MouseManager.getFrameButtonChanges())
				if (c.button == MouseManager.BUTTON_LEFT)
					changes.push(c.isDown);
		buttons.frame(Math.max(0, MouseManager.getX()) / K, Math.max(0, MouseManager.getY()) / K, changes);
		main();
	}

	// flash.Lib.getTimer(): the time of a Flash player at exactly 40 frames/s
	public function getTimer():Float {
		return frameCount * 1000 / FRAME_RATE;
	}

	// update() of the original
	function main() {
		updateSprites();

		switch (step) {
			case Play:
				if (flGameOver) {
					gameOver();
					step = GameOver;
				}

			case Charge:
				timer -= 200 * mt.Timer.tmod;
				if (timer <= 0) {
					if (linksDone()) {
						timer = null;
						initExplode();
					} else
						next(function(t, i) {
							return t.charge(i);
						});
				}

			case Explode:
				timer -= 400 * mt.Timer.tmod;
				if (timer <= 0) {
					if (linksDone()) {
						timer = null;
						finishExplode();
						step = Fall;
						initFall();
					} else
						next(function(t, i) {
							return t.explode(i);
						});
				}

			case Fall:
				if (!fallDone())
					return;
				if (!check())
					initPlay();

			case GameOver:
				updateGameOver();
		}

		updateTime();
	}

	function updatePlay() {}

	function updateSprites() {
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.update();
	}

	// CHARGE

	function initCharge() {
		step = Charge;

		toExplode = new List();
		toKill = new List();
		for (t in links) {
			toExplode.push(t);
			toKill.push(t);
		}

		timer = 100;
		if (start == null) {
			start = links.first();
			toApply = links.first().charge(Cs.WEST);
		} else
			toApply = start.charge();
	}

	function next(f:Tile->Int->Array<{t:Tile, d:Int}>) {
		if (toApply == null || toApply.length == 0) {
			resetLinks();
			return;
		}

		timer = 100;

		var t = toApply.copy();
		toApply = new Array();
		for (e in t) {
			var newTiles = f(e.t, e.d);
			for (n in newTiles) {
				if (!Lambda.exists(toApply, function(x) {
					return x.t == n.t;
				}))
					toApply.push(n);
			}
		}
	}

	function linksDone() {
		return links == null || links.length == 0;
	}

	// ### EXPLOSION

	function initExplode() { // explode board and give points
		step = Explode;
		explosionCount++;

		links = new List();
		for (t in toExplode) {
			links.add(t);
		}

		timer = 100;
		toApply = start.explode();
	}

	public function finishExplode() {
		resetFall();
		start = null;

		mcScoring._t._pts.text = Std.string(KKApi.val(KKApi.cmult(KKApi.cmult(Cs.GOAL_POINTS, KKApi.const(getExplosions())),
			KKApi.const(comboMult(Game.me.combo)))));
		mcScoring._t._mult.text = "x" + Std.string(getExplosions());
		mcScoring.gotoAndPlay(1);

		while (toKill.length > 0) {
			var t = toKill.pop();
			t.destroy();
			falls[t.pos.x]++; // count holes in each column
		}

		for (side in goals) {
			for (g in side) {
				g.unLight();
				if (g.toExplode)
					g.explode();
			}
		}
	}

	// Cs.COMBO_MULT[combo]: past the 13 values of the table (13 explosions chained without a move) the original read
	// undefined (NaN points); here 0
	public static function comboMult(combo:Int):Int {
		return combo >= 0 && combo < Cs.COMBO_MULT.length ? Cs.COMBO_MULT[combo] : 0;
	}

	// ### FALL

	function resetFall() {
		falls = new Array();
		for (i in 0...Cs.BOARD_WIDTH) {
			falls.push(0);
		}
	}

	function initFall() { // create and check next board validity
		resetParsing(true);
		var checked = false;
		var newTiles = null;
		var easyMode = false;

		while (!checked) {
			newTiles = makeNewTiles(easyMode);
			checked = testBoard();
			if (!checked) {
				for (t in newTiles)
					t.kill();
				easyMode = true;
			}
		}
	}

	function makeNewTiles(easyMode:Bool) { // create new tiles in board holes
		var res = new List();
		for (i in 0...Cs.BOARD_WIDTH) {
			var f = falls[i];
			var y = -50;
			for (j in 0...f) {
				var t = new Tile(Tile.getRandomCase(easyMode), Seed.random(4), {x: i, y: f - j - 2}, y);
				board[i].insert(0, t);
				res.add(t);
				y -= Cs.TILE_SIZE;
			}
		}
		return res;
	}

	function fallDone() {
		for (b in board) {
			for (t in b) {
				if (t.isFalling())
					return false;
			}
		}
		return true;
	}

	function initBoard() {
		cTile = new Tile(0, 0, {x: -10, y: -10});
		cTile.setIn();

		board = new Array();
		for (i in 0...Cs.BOARD_WIDTH) {
			board[i] = new Array();
			for (j in 0...Cs.BOARD_HEIGHT) {
				var t = Tile.getRandomCase(if (i == Cs.BOARD_WIDTH - 1) [Cs.TILE_3, Cs.TILE_4] else [Cs.TILE_4]);
				var dir = if (i == Cs.BOARD_WIDTH - 1) Tile.getBlockedDirection(t) else Seed.random(4);
				var e = new Tile(t, dir, {x: i, y: j});
				board[i][j] = e;
				e.updatePipe();
			}
		}

		// trace first green links
		for (t in board[0]) {
			if (t.checkEdge(Cs.WEST)) {
				goals[0][t.pos.y].activate();
				parse(t, Cs.EAST, Cs.PARSE_IN);
			} else
				goals[0][t.pos.y].shutdown();
		}
		resetParsing();
	}

	function initGoals() {
		goals = new Array();

		for (j in 0...2) {
			goals[j] = new Array();
			for (i in 0...Cs.BOARD_HEIGHT) {
				var g = new Goal();
				g.setPos(j, i);
				goals[j].push(g);
			}
		}
	}

	function resetGoalsActivation() {
		for (j in 0...2) {
			for (i in 0...Cs.BOARD_HEIGHT) {
				goals[j][i].toExplode = false;
			}
		}
	}

	public function resetParsing(?unlink:Bool) {
		resetExplode();
		for (b in board) {
			for (t in b) {
				t.parsed = false;
				if (unlink)
					t.resetState();
			}
		}
	}

	function resetExplode() {
		explode = [0, 0];
	}

	function initPlay() {
		step = Play;
		combo = 0;
		unlock();
	}

	// GAMEOVER
	function initGameOver() {
		lock();
		flGameOver = true;
	}

	function updateGameOver() {}

	function updateTime() { // update TimeLine && check gameover
		var now = getTimer();

		var c = Cs.PLAY_TIME - (now - mcTime.start);

		if (c > 0) {
			mcTime._timeLeft._xscale = c / Cs.PLAY_TIME * 100;
		} else
			initGameOver();

		// TIME PARTS (visual random)
		var nb = 1 + Seed.randomVfx(3);
		var drop = {x: Cs.TIME_X + mcTime._timeLeft._width - 1, y: mcTime._timeLeft._height};
		for (i in 0...nb) {
			var mc = dm.add(new Part(), DP_FX);
			mc._xscale = 40;
			mc._yscale = 40;
			mc.setColor(0x2AB9D6);

			var s = new Phys(mc);
			s.x = drop.x;
			s.y = Cs.TIME_Y + i * (drop.y / nb);
			s.weight = -0.2;
			s.alpha = 90;
			s.vx = Seed.randVfx() * 4;
			s.vy = Seed.randVfx() * 1;
			s.fadeType = 5; // alpha
			s.timer = 5;
		}
	}

	// TOOLS
	public function addScore(sc:Int) { // pr ajouter au score du joueur
		// (no point after the game over is sent)
		if (!overSent)
			KadoKadeoManager.kkm.addScore(KKApi.val(sc));
	}

	// KKApi.gameOver({})
	function gameOver() {
		if (overSent)
			return;
		overSent = true;
		#if debug
		// test harness: state of the game at its end (compared between a game and its replay)
		untyped js.Browser.window.__over = {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			explosions: explosionCount,
			start: mcTime.start,
			board: boardKey()
		};
		#end
		KadoKadeoManager.kkm.gameOver({});
	}

	#if debug
	public function boardKey():String {
		var s = "";
		for (c in board)
			for (t in c)
				s += t.tile + "" + t.d;
		return s;
	}
	#end

	// ### TEST PARSING

	public function parseTest(tile:Tile, from:Int):Bool {
		if (tile.parsed)
			return false;

		tile.parsed = true;
		var entries = Cs.TEST_PARSING[tile.tile];

		for (e in entries) {
			var dir = Tile.sMod(from + e, 4);

			var neighbour = getNeighbour(dir, tile.pos);

			if (neighbour == null) {
				if (isTestGoal(tile, from)) {
					return true;
				} else
					continue;
			}

			var res = parseTest(neighbour, Tile.sMod(dir + 2, 4));
			if (res)
				return true;
		}

		return false;
	}

	function isTestGoal(tile:Tile, from:Int) {
		if (tile.pos.x != Cs.BOARD_WIDTH - 1)
			return false;

		var entries = Cs.TEST_PARSING[tile.tile];
		for (e in entries) {
			var dir = Tile.sMod(from + e, 4);
			if (dir == Cs.EAST)
				return true;
		}
		return false;
	}

	function testBoard() {
		for (t in board[0]) {
			resetParsing();
			if (parseTest(t, Cs.WEST))
				return true;
		}
		return false;
	}

	public function getExplosions():Int {
		return explode[0] + explode[1];
	}

	public function isConnected():Bool {
		return explode[0] > 0 && explode[1] > 0;
	}

	// EXPLODE PARTS
	static public function parts(x:Float, y:Float) {
		var nb = 5;
		var dsx = 10;
		var dsy = 10;

		// (particles: visual random)
		for (i in 0...nb) {
			var mc = Game.me.dm.add(new Part(), Game.DP_FX);
			var size = 20 + Seed.randomVfx(4) * 10;
			mc._xscale = size;
			mc._yscale = size;

			mc.setColor(0xFFFFFF);

			var s = new Phys(mc);
			s.x = x + (Seed.randVfx() * 2 - 1) * dsx;
			s.y = y + (Seed.randVfx() * 2 - 1) * dsy;
			s.weight = (Seed.randVfx() * 2 - 1) + 0.8;
			s.alpha = 90;
			s.vx = (Seed.randVfx() * 2 - 1) * 10;
			s.vy = (Seed.randVfx() * 2 - 1) * 10;
			s.fadeType = 5; // alpha
			s.timer = 10;
		}
	}

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		MC.clearAll();
		Sprite.spriteList = [];
		if (me == this)
			me = null;
	}
}
