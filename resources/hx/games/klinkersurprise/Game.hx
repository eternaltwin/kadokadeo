package klinkersurprise;

import haxe.io.UInt16Array;
import klinkersurprise.Generator.GeneratorMC;
import klinkersurprise.Ground.LightBitmap;
import klinkersurprise.MC.Plans;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

private enum Step {
	Seek;
	Scroller(flQuit:Bool);
	GameOver;
}

// {>MovieClip, c:Float}: a background plane and its parallax coefficient
typedef Plan = {mc:MC, c:Float};

@:expose('GameKlinkerSurprise')
class Game implements kado.GameInterface {
	// texture pixels per Flash pixel: the original's 300 x 300 pixels drawn x2
	public static inline var K = 2;
	// Flash played Klinker Surprise at 40 frames/s (the rate of the SWF) with Timer.wantedFPS = 32: tmod = 0.8
	public static inline var FRAME_RATE = 40;

	public static var COLOR = [0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF, 0xFFAA00, 0xAA00FF];
	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];

	public static inline var DP_BG = 0;
	public static inline var DP_MAP = 1;
	public static inline var DP_PLASMA = 2;
	public static inline var DP_FRONT = 3;
	public static inline var DP_INTER = 4;

	public static inline var DP_GROUND = 1;
	public static inline var DP_ELEMENT = 2;
	public static inline var DP_SELECTOR = 3;
	public static inline var DP_PARTS = 4;

	static var SCORE_DALLE = KKApi.const(125);
	static var SCORE_FREE = KKApi.const(-125);
	static var TIME_BONUS = 1200;
	static var TIME_MAX = 2500;

	static var PLASMA_CACHE = 0;

	public static inline var EMPTY = 0;
	public static inline var PATH = 1;
	public static inline var WALL = 2;
	public static inline var GENERATOR = 10;
	public static inline var PAINT = 50;

	public static var mcw = 300;
	public static var mch = 300;

	var flAutoSelect:Bool = false;
	var flForceUpdateTarget:Bool = false;

	public var xmax:Int;
	public var ymax:Int;
	public var zw:Int;
	public var zh:Int;
	public var size:Int;

	// (ccolorMax / clevel: copies of colorMax / level in mt.flash.Volatile for KKApi.flagCheater, dropped)
	public var colorMax:Int;
	public var level:Int;

	public var colorId:Null<Int>;
	public var tx:Int;
	public var ty:Int;

	var levelTimer:Float;
	// never set before the first frame: undefined, see updateFree
	var freeTimer:Float = Math.NaN;
	var scx:Float;
	var scy:Float;

	var coef:Float;

	var step:Step;

	public var map:MC;
	public var ground:Ground;

	public var grid:Array<Array<Int>>;
	public var archive:Array<Array<Array<Int>>>;
	public var path:Array<Array<Int>>;
	public var free:Array<Array<Array<Int>>>;
	public var action:Array<Int>;
	public var generators:Array<Generator>;

	var plans:Array<Plan>;

	public var plasma:Plasma;

	public var mcInter:Inter;
	public var selector:Selector;

	public static var me:Game;

	public var mdm:Plans;
	public var dm:Plans;
	public var root:MC;

	var mcTarget:MC;

	// root._xmouse / root._ymouse (Flash pixels)
	public var xmouse:Float = 0;
	public var ymouse:Float = 0;

	// ---------------------------------------------------------------- port
	var isReplay:Bool;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	var over:Bool = false;
	// the map once initStep(Seek) gave it its button handlers (onPress / onRelease / onReleaseOutside), and the map
	// pressed (see updateMouse)
	var mapButton:MC;
	var pressed:MC;
	var onPointerDown:Dynamic;
	var flushListener:Dynamic;
	var bgBitmaps:Array<LightBitmap> = [];
	var handCursor:Bool = false;
	#if debug
	// test harness: what the game went through (window.__over)
	public var stats:Dynamic;
	#end

	public static var LEVEL = [
		{size: 60, cmax: 2},
		{size: 50, cmax: 3},
		{size: 50, cmax: 4},
		{size: 40, cmax: 5},
		{size: 40, cmax: 6},
		{size: 40, cmax: 7},
		{size: 40, cmax: 7},
		{size: 40, cmax: 8}
	];

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
		MC.clearAll();
		Sprite.spriteList = [];
		#if debug
		// test harness (modes/klinkersurprise.js, map=<n>): the grids of another seed than the debug one, the same in a
		// game and in its replay
		if (untyped js.Browser.window.__ksMap != null)
			Seed.init(untyped js.Browser.window.__ksMap);
		stats = {painted: 0, freed: 0, links: 0, giveUps: 0, cuts: 0, frees: 0, autoSel: 0};
		#end
		// like the Flash player, the map pressed keeps the mouse while the button is held (its release outside the game
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
		mdm = new Plans(root);

		level = 0;
		levelTimer = TIME_MAX;

		initBg();
		// attach("mcInter"), blendMode "add", Filt.glow(mcInter, 6, 1, 0xFFFFFF): see Inter
		mcInter = mdm.add(new Inter(), DP_INTER);

		initZone();
		initPlasma();

		initStep(Seek);

		// the bitmaps drawn on the GPU (plasma, painted cells) are brought up to date just before the screen is drawn:
		// after the steps of the frame (NORMAL priority), before the render of the page (LOW)
		flushListener = function(_) flushBitmaps();
		var ticker:Dynamic = KadoKadeoManager.kkm.ticker;
		ticker.add(flushListener, null, -10);

		MC.displayAll(1);
		placePlasma();
		warmShaders();
	}

	function initStep(n:Step) {
		step = n;
		switch (step) {
			case Seek:
				// map.onPress = select, map.onRelease = map.onReleaseOutside = release (see updateMouse)
				mapButton = map;
				mcTarget = dm.attach("sel" + size, DP_SELECTOR, K * size / 100);
				mcTarget._yscale = mcTarget._xscale = size;
				mcTarget.setAdd();
				mcTarget._visible = false;
				// (moves with the map, by a period when the selector goes round)
				mcTarget.wrap = zw;
			// Filt.glow(mcTarget, 10, 1, 0xFFFFFF): baked in its pictures

			case Scroller(flQuit):
				coef = 0;
			case GameOver:
		}
	}

	// ---------------------------------------------------------------- UPDATE
	public function update(delta:Float) {
		// Flash played Klinker Surprise at 40 frames/s (the rate of the SWF) with Timer.wantedFPS = 32: tmod = 0.8, one
		// update() per Flash frame. KadoKadeo steps 32 times per second: 5 Flash frames every 4 steps. The mouse
		// events of the step come between two Flash frames, like Flash's
		mt.Timer.tmod = 32 / FRAME_RATE;
		var buttons = over ? null : updateMouse();
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame();
			if (buttons != null && !over) {
				mouseButtons(buttons);
				buttons = null;
			}
		}
		MC.displayAll(frameAcc / 4);
		placePlasma();
	}

	function flashFrame() {
		MC.frameStart();
		main();
		frameCount++;
	}

	// update() of the original: one Flash frame
	function main() {
		// STEP
		switch (step) {
			case GameOver:
			case Seek:
				updateSeek();
			case Scroller(flQuit):
				coef = Math.min(coef + 0.05 * mt.Timer.tmod, 1);
				var c = coef;
				if (!flQuit)
					c = 1 - coef;
				selector.vx = c * 100;
				selector.vy = c * 0.5 * 100;

				if (coef == 1) {
					if (flQuit) {
						map.removeMovieClip();
						initZone();
						initStep(Scroller(false));
					} else {
						initStep(Seek);
					}
				}
				// (lim, ca: a colour fade of the root, commented out in the original)
		}

		// SPRITE
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.update();

		//
		updateFree();
		updateScroll();
		// Plasma.updateAll
		plasma.update();

		// (ccolorMax != colorMax || level != clevel: KKApi.flagCheater)
	}

	// SEEK
	function updateSeek() {
		moveSelector();
		updateTarget();

		if (level > 1)
			levelTimer = Math.max(levelTimer - mt.Timer.tmod, 0);
		var c = levelTimer / TIME_MAX;
		mcInter.setBars(c);
		if (levelTimer == 0) {
			initStep(GameOver);
			gameOver();
		}
	}

	function moveSelector() {
		var dx = xmouse - mcw * 0.5;
		var dy = ymouse - mch * 0.5;

		var lim = 50;
		var adx = Math.abs(dx);
		var ady = Math.abs(dy);
		var sx = dx / adx;
		var sy = dy / ady;

		if (adx > lim) {
			dx = dx - lim * sx;
		} else {
			dx = 0;
		}
		if (ady > lim) {
			dy = dy - lim * sy;
		} else {
			dy = 0;
		}

		var c = 0.1;
		selector.vx = dx * c;
		selector.vy = dy * c;
	}

	// SELECT
	function updateTarget() {
		var x = Math.floor((xmouse - map._x) / size);
		var y = Math.floor((ymouse - map._y) / size);

		if (mcTarget._x != x * size || mcTarget._y != y * size || flForceUpdateTarget || true) {
			flForceUpdateTarget = false;
			mcTarget._x = x * size;
			mcTarget._y = y * size;

			x = tx = gx(x);
			y = ty = gy(y);

			var type = grid[x][y];
			action = [0];

			if (colorId == null) {
				if (type == EMPTY) {
					var dirIndex = 0;
					for (d in DIR) {
						var nx = gx(x + d[0]);
						var ny = gy(y + d[1]);
						var t = grid[nx][ny];
						if (t >= 10 && t < 20) {
							var col = t - 10;
							if (archive[col] == null) {
								var td = getTargetDir();
								action = [1, col, dirIndex, 1];
								if ((td + 2) % 4 == dirIndex)
									break;
							}
						}
						dirIndex++;
					}
				}
				if (type >= GENERATOR && archive[type - GENERATOR] != null) {
					action = [2, type - GENERATOR];
				}
			} else {
				var first = path[0];
				if (first[0] == x && first[1] == y) {
					action = [3];
				} else {
					var last = path[path.length - 1];
					var dx = gdx(x - last[0]);
					var dy = gdy(y - last[1]);

					if (Math.abs(dx) + Math.abs(dy) == 1) {
						if (type == EMPTY) {
							var dirIndex = 0;
							for (d in DIR) {
								if (d[0] == -dx && d[1] == -dy)
									break;
								dirIndex++;
							}
							action = [1, colorId, dirIndex];
						}
						if (type >= PAINT && type != PAINT + colorId && free.length == 0) {
							action = [4, type - PAINT];
						}
					}
				}
			}
			if (action[0] == 1) {
				mcTarget.gotoAndStop(2 + action[2]);
				// Col.setPercentColor(mcTarget, 100, COLOR[action[1]]): the colour on its white picture
				mcTarget.tint = COLOR[action[1]];
			} else {
				mcTarget.gotoAndStop(1);
				// Col.setPercentColor(mcTarget, 0, 0)
				mcTarget.tint = 0xFFFFFF;
			}

			if (flAutoSelect) {
				#if debug
				if (action[0] != 0)
					stats.autoSel++;
				#end
				select();
			}
		}

		mcTarget._visible = action[0] > 0;
		// map.useHandCursor = mcTarget._visible
		setHandCursor(mcTarget._visible);
	}

	function select() {
		flAutoSelect = true;
		var a = action;
		// (an action not computed yet, a press before the first frame: undefined in Flash, no case)
		switch (a == null ? null : a[0]) {
			case 1:
				colorId = a[1];
				if (a[3] == 1) {
					var d = DIR[a[2]];
					path = [[gx(tx + d[0]), gy(ty + d[1])]];
				}
				paint(tx, ty);
			case 2:
				#if debug
				stats.frees++;
				#end
				free.push(getArchive(a[1]));
			case 3:
				giveUpRun();
			case 4:
				#if debug
				stats.cuts++;
				#end
				var p = getArchive(a[1]);
				var index = 0;
				for (pos in p) {
					if (pos[0] == tx && pos[1] == ty)
						break;
					index++;
				}
				free.push(p.slice(0, index));
				var arr = p.slice(index + 1, p.length);
				arr.reverse();
				free.push(arr);

				//
				paint(tx, ty);
			default:
		}
		action = [0];
	}

	function release() {
		flAutoSelect = false;
	}

	//
	public function getArchive(col:Int):Array<Array<Int>> {
		var p = archive[col];
		archive[col] = null;
		var a = getColGenerator(col);
		for (g in a)
			g.unlight();
		return p;
	}

	public function paint(x:Int, y:Int) {
		path.push([x, y]);
		grid[x][y] = PAINT + colorId;
		addScore(SCORE_DALLE);
		#if debug
		stats.painted++;
		#end

		// PLASMA: spectre.fillRect(cell, COLOR[colorId] with alpha 120): drawn from the grid, see Ground
		ground.spectreDirty = true;
		var o = Col.colToObj(COLOR[colorId]);
		var o2 = {r: o.r, g: o.g, b: o.b, a: 120};

		// SPARK (Math.random, Std.random: a picture only)
		var max = 4;
		for (i in 0...max) {
			var a = 6.28 * i / max + (Seed.randVfx() * 2 - 1) * 0.3;
			var sp = new Rel(dm.attach("spark", DP_PARTS, 1));
			sp.x = (x + Seed.randVfx()) * size;
			sp.y = (y + Seed.randVfx()) * size;
			sp.timer = 10 + Seed.randVfx() * 10;
			sp.setScale(20 + Seed.randVfx() * 30);
			sp.frict = 0.98;
			sp.root.setAdd();
			sp.relPoint = selector;
			sp.updatePos();
			sp.fadeType = 0;
			sp.root.gotoAndPlay(Seed.randomVfx(sp.root._totalframes) + 1);
		}

		// CHECK END
		for (d in DIR) {
			var nx = gx(x + d[0]);
			var ny = gy(y + d[1]);
			var t = grid[nx][ny];
			// (once linkOk ran, colorId is null: GENERATOR + colorId is NaN in Flash, never equal, and path is null)
			if (colorId != null && t == GENERATOR + colorId && (path[0][0] != nx || path[0][1] != ny)) {
				linkOk();
			}
		}

		//
		var rx = Math.floor(grx(x * size));
		var ry = Math.floor(gry(y * size));
		o2.r = 255;
		o2.g = 255;
		o2.b = 255;
		o2.a = 1000;

		plasma.fillRect(rx, ry, size, size, Col.objToCol32(o2));
	}

	function linkOk() {
		#if debug
		stats.links++;
		#end
		flAutoSelect = false;
		var a = getColGenerator(colorId);
		for (g in a)
			g.light();
		path.shift();
		archive[colorId] = path;

		path = null;
		colorId = null;
		// CHECK END
		for (gen in generators) {
			if (gen.root._currentframe == 1)
				return;
		}
		initStep(Scroller(true));
	}

	function giveUpRun() {
		#if debug
		stats.giveUps++;
		#end
		path.shift();
		free.push(path);
		freeTimer = 0;
		path = null;
		colorId = null;
	}

	// FREE
	function updateFree() {
		// compiled as `if (freeTimer > 0) {...} else {...}`: freeTimer is undefined (NaN) until this sets it, so the
		// first frame takes the second branch (the source reads `if (freeTimer <= 0)`, false for undefined)
		if (freeTimer > 0) {
			if (free.length > 0)
				freeTimer -= mt.Timer.tmod;
		} else {
			freeTimer = 0.5;
			// (an index loop: a list removed makes it skip the next one until the next time)
			var i = 0;
			while (i < free.length) {
				var a = free[i];
				i++;
				if (a.length > 0) {
					addScore(SCORE_FREE);
					#if debug
					stats.freed++;
					#end

					//
					var p = a.pop();
					var col = grid[p[0]][p[1]] - PAINT;
					grid[p[0]][p[1]] = EMPTY;
					// spectre.fillRect(cell, 0)
					ground.spectreDirty = true;

					/// PLASMA: mcExplo drawn 5 times (Math.random, Std.random: a picture only)
					var max = 5;
					for (k in 0...max) {
						var sc = 0.5 + Seed.randVfx() * 4;
						var x = grx((p[0] + Seed.randVfx()) * size);
						var y = gry((p[1] + Seed.randVfx()) * size);
						var inc = 120;
						var co = Col.colToObj(COLOR[col]);
						var r = 40 + co.r + Seed.randomVfx(inc);
						var g = 40 + co.g + Seed.randomVfx(inc);
						var b = 40 + co.b + Seed.randomVfx(inc);
						plasma.drawExplo(sc, x, y, r, g, b);
					}

					// SPARK
					var max = 3;
					for (k in 0...max) {
						var a = 6.28 * k / max + (Seed.randVfx() * 2 - 1) * 0.3;
						var sp = new Rel(dm.attach("spark", DP_PARTS, 1));
						sp.x = (p[0] + Seed.randVfx()) * size;
						sp.y = (p[1] + Seed.randVfx()) * size;
						var a = Math.atan2(sp.y - (p[1] + 0.5) * size, sp.x - (p[0] + 0.5) * size);
						var ca = Math.cos(a);
						var sa = Math.sin(a);
						var speed = Seed.randVfx() * 1;
						sp.vx = ca * speed;
						sp.vy = sa * speed;
						sp.timer = 10 + Seed.randVfx() * 10;
						sp.setScale(20 + Seed.randVfx() * 30);
						sp.frict = 0.98;
						sp.root.setAdd();
						sp.relPoint = selector;
						sp.updatePos();
						sp.fadeType = 0;
						sp.root.gotoAndPlay(Seed.randomVfx(sp.root._totalframes) + 1);
					}
				}
				if (a.length == 0) {
					free.remove(a);
				}
			}
			flForceUpdateTarget = true;
		}
	}

	// GRID GENERATION
	function genGrid() {
		grid = [];
		for (x in 0...xmax) {
			grid[x] = [];
			for (y in 0...ymax) {
				grid[x][y] = EMPTY;
			}
		}

		// placeGeneratorBasic();
		placeGeneratorAdvanced();

		for (x in 0...xmax) {
			for (y in 0...ymax) {
				if (grid[x][y] == EMPTY)
					grid[x][y] = WALL;
				if (grid[x][y] == PATH)
					grid[x][y] = EMPTY;
			}
		}

		// FALSE PATH
		var max = Std.int(Math.max(5, 60 - level * 6));
		var x = Seed.random(xmax);
		var y = Seed.random(ymax);
		var dIndex = Seed.random(4);
		for (i in 0...max) {
			if (Seed.random(5) == 0) {
				dIndex = Std.int(Num.sMod(dIndex + Seed.random(2) * 2 - 1, 4));
			}
			var d = DIR[dIndex];
			x = gx(x + d[0]);
			y = gy(y + d[1]);

			if (grid[x][y] == WALL)
				grid[x][y] = EMPTY;
		}
	}

	function placeGeneratorBasic() {
		for (i in 0...colorMax) {
			for (n in 0...2) {
				var p = getEmptyPos();
				grid[p.x][p.y] = 10 + i;
			}
		}
	}

	function placeGeneratorAdvanced() {
		var rayMin = 3;
		var distMin = 6;

		for (i in 0...colorMax) {
			var to = 0;
			while (true) {
				var start = getEmptyPos();
				if (start == null) {
					// (AVM1: null.x is undefined: grid[undefined] holds nothing, no direction is EMPTY, the path is not
					// validated and nothing was written; only the random of the shuffle is drawn)
					shuffle(DIR);
				} else {
					var p = {x: start.x, y: start.y};
					var path = [[p.x, p.y]];
					grid[p.x][p.y] = PATH;
					var parc = 0;
					var flValidate = false;
					while (true) {
						var dir = shuffle(DIR);
						var flBlock = true;
						for (d in dir) {
							// (not wrapped: outside the grid, grid[x][y] is undefined, not EMPTY)
							var x = p.x + d[0];
							var y = p.y + d[1];
							var flOk = cell(x, y) == EMPTY;

							var nb = 0;
							for (p2 in path) {
								var dx = gdx(x - p2[0]);
								var dy = gdy(y - p2[1]);
								if (Math.abs(dx) + Math.abs(dy) == 1) {
									nb++;
									if (nb == 2) {
										flOk = false;
										break;
									}
								}
							}

							if (flOk) {
								path.push([x, y]);
								grid[x][y] = PATH;
								p.x = x;
								p.y = y;
								flBlock = false;
								break;
							}
						}

						parc++;
						var max = Math.min(level * 3, 14);
						if (flBlock || (parc > max && Seed.random(3) == 0)) {
							flValidate = parc > 3;
							break;
						}
					}
					if (flValidate) {
						grid[start.x][start.y] = 10 + i;
						grid[p.x][p.y] = 10 + i;
						break;
					} else {
						for (p in path)
							grid[p[0]][p[1]] = EMPTY;
					}
				}
				if (to++ > 100) {
					break;
				}
			}
		}
	}

	function getEmptyPos():{x:Int, y:Int} {
		var to = 0;
		while (true) {
			var x = Seed.random(xmax);
			var y = Seed.random(ymax);
			if (grid[x][y] == EMPTY)
				return {x: x, y: y};
			if (to++ > 100)
				break;
		}
		// (trace "can't find pos")
		return null;
	}

	// grid[x][y]: undefined outside the grid in Flash
	public function cell(x:Int, y:Int):Null<Int> {
		var c = grid[x];
		return c == null ? null : c[y];
	}

	// MAP - BG - SCROLL
	function initMap() {
		initGround();

		// MAP
		map = mdm.empty(DP_MAP);
		// (jumps by a period when the selector goes round: see MC.wrap)
		map.wrap = zw;
		var g = ground;
		map.onDestroy = function() g.destroy();
		dm = new Plans(map);
		for (x in 0...3) {
			for (y in 0...3) {
				var mc = dm.empty(DP_GROUND);
				// attachBitmap(ground, 0), attachBitmap(spectre, 1)
				for (t in [(ground.texture : Texture), (ground.spectre : Texture)]) {
					var s = new PixiSprite(t);
					s.scale.set(1 / K, 1 / K);
					mc.spr.addChild(s);
				}
				mc._x = (x - 1) * zw;
				mc._y = (y - 1) * zh;
			}
		}

		// SELECTOR (mcRunner: _alpha 0, never seen)
		selector = new Selector(dm.add(new MC(), DP_SELECTOR));
		selector.setScale(size);

		// ELEMENTS
		for (x in 0...xmax) {
			for (y in 0...ymax) {
				var type = grid[x][y];
				if (type >= 10) {
					var gen = new Generator(dm.add(new GeneratorMC(size), DP_ELEMENT), type - 10);
					gen.setPos(x, y);
				}
			}
		}
	}

	// the ground bitmap (and the spectre bitmap of initMap): see Ground
	function initGround() {
		ground = new Ground(grid, xmax, ymax, size);
	}

	function initBg() {
		scx = 0;
		scy = 0;

		plans = [];

		var infos = [
			{d: DP_BG, c: 0.2, lb: 800, col: 0xFF002200},
			{d: DP_BG, c: 0.4, lb: 150, col: 0},
			{d: DP_BG, c: 0.7, lb: 40, col: 0}
		];

		for (o in infos) {
			var bg = mdm.empty(o.d);
			bg.wrap = mcw;

			// the bitmap (mcw x mch, colour o.col) and o.lb lights drawn "add": see LightBitmap
			var bmp = new LightBitmap(o.col, o.c, o.lb);
			bgBitmaps.push(bmp);
			for (x in 0...2) {
				for (y in 0...2) {
					var mc = bg.attach(new MC());
					var s = new PixiSprite(bmp.texture);
					s.scale.set(1 / K, 1 / K);
					mc.spr.addChild(s);
					mc._x = x * mcw;
					mc._y = y * mch;
				}
			}

			//
			plans.push({mc: bg, c: o.c});
		}
	}

	function updateScroll() {
		// SCROLL
		var dx = (mcw * 0.5 - selector.x) - map._x;
		var dy = (mch * 0.5 - selector.y) - map._y;

		if (Math.abs(dx) + Math.abs(dy) < 1)
			return;

		map._x += dx;
		map._y += dy;

		dx = Num.hMod(dx, Std.int(zw * 0.5));
		dy = Num.hMod(dy, Std.int(zh * 0.5));

		for (p in plans) {
			p.mc._x = Num.sMod(p.mc._x + dx * p.c, mcw) - mcw;
			p.mc._y = Num.sMod(p.mc._y + dy * p.c, mch) - mch;
		}

		// (scx exactly 0: 0 / 0 is NaN, and stays NaN, like in Flash: the plasma no longer scrolls on that axis)
		scx += dx;
		scy += dy;
		var ddx = Math.ffloor(Math.abs(scx)) * (scx / Math.abs(scx));
		var ddy = Math.ffloor(Math.abs(scy)) * (scy / Math.abs(scy));
		if (dx == 0)
			ddx = 0;
		if (dy == 0)
			ddy = 0;

		scx -= ddx;
		scy -= ddy;
		plasma.scroll(Math.ffloor(ddx), Math.ffloor(ddy));
	}

	// PLASMA
	function initPlasma() {
		var m = PLASMA_CACHE;
		plasma = new Plasma(mdm.empty(DP_PLASMA), mcw + 2 * m, mch + 2 * m);
		plasma.setPos(-m, -m);
		// BlurFilter 2 x 2, ColorTransform(1.1, 1.1, 1.1, 1, -10, -10, -10, -16): applied by Plasma.update
	}

	// LEVEL
	function initZone() {
		var o = LEVEL[Std.int(Math.min(level, LEVEL.length - 1))];

		level++;

		path = [];
		free = [];
		generators = [];
		archive = [];

		//
		var sz = o.size;
		var side = Math.ceil(mcw / sz * 0.5) * 2 + 2;

		xmax = side;
		ymax = side;
		size = sz;
		zw = Std.int(xmax * size);
		zh = Std.int(ymax * size);
		Rel.ZW = zw;
		Rel.ZH = zh;

		colorMax = o.cmax;

		levelTimer = Math.min((levelTimer + TIME_BONUS) - level * 20, TIME_MAX);
		var str = Std.string(level);
		if (str.length == 1)
			str = "0" + str;
		mcInter.setText("LEVEL'" + str);

		genGrid();
		initMap();
	}

	// TOOLS
	function getTargetDir() {
		var dx = (mcTarget._x + size * 0.5 + map._x) - xmouse;
		var dy = (mcTarget._y + size * 0.5 + map._y) - ymouse;

		if (dx == 0)
			dx = 0.1;
		if (dy == 0)
			dy = 0.1;

		var sx = dx / Math.abs(dx);
		var sy = dy / Math.abs(dy);
		if (Math.abs(dx) > Math.abs(dy))
			sy = 0;
		else
			sx = 0;

		var dirIndex = 0;
		for (d in DIR) {
			if (sx == d[0] && sy == d[1])
				break;
			dirIndex++;
		}
		if (dirIndex == 4) {
			// (trace)
			return 0;
		}
		return dirIndex;
	}

	function shuffle(list:Array<Array<Int>>):Array<Array<Int>> {
		var pos = [];
		for (n in 0...list.length)
			pos.push(n);
		var a = [];
		while (pos.length > 0) {
			var index = Seed.random(pos.length);
			var n = pos[index];
			pos.splice(index, 1);
			a.push(list[n]);
		}
		return a;
	}

	static public function getGenerator(x:Int, y:Int):Generator {
		for (g in Game.me.generators) {
			if (g.px == x && g.py == y)
				return g;
		}
		return null;
	}

	static public function getColGenerator(type:Int):Array<Generator> {
		var a = [];
		for (g in Game.me.generators) {
			if (g.type == type)
				a.push(g);
		}
		return a;
	}

	static public function gx(x:Float):Int {
		return Std.int(Num.sMod(x, Game.me.xmax));
	}

	static public function gy(y:Float):Int {
		return Std.int(Num.sMod(y, Game.me.ymax));
	}

	static public function gdx(x:Float):Int {
		return Std.int(Num.hMod(x, Std.int(Game.me.xmax * 0.5)));
	}

	static public function gdy(y:Float):Int {
		return Std.int(Num.hMod(y, Std.int(Game.me.ymax * 0.5)));
	}

	static public function grx(x:Float):Float {
		var dx = Num.hMod(Game.me.selector.x - x, Game.me.zw * 0.5);
		return (Game.me.selector.x - dx) + Game.me.map._x;
	}

	static public function gry(y:Float):Float {
		var dy = Num.hMod(Game.me.selector.y - y, Game.me.zh * 0.5);
		return (Game.me.selector.y - dy) + Game.me.map._y;
	}

	//
	public function mouseScroll() {
		var c = 0.1;
		var vx = -(xmouse - mcw * 0.5) * c;
		var vy = -(ymouse - mch * 0.5) * c;
		map._x = Num.sMod(map._x + vx * mt.Timer.tmod, zw);
		map._y = Num.sMod(map._y + vy * mt.Timer.tmod, zh);
	}

	// ---------------------------------------------------------------- port: score (KKApi)
	function addScore(n:KKConst) {
		if (over)
			return;
		KadoKadeoManager.kkm.addScore(KKApi.val(n));
	}

	function gameOver() {
		if (over)
			return;
		#if debug
		// test harness: state of the game at its end (compared between a game and its replay)
		var painted = 0;
		for (c in grid)
			for (t in c)
				if (t >= PAINT)
					painted++;
		untyped js.Browser.window.__over = {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			level: level,
			painted: painted,
			sx: selector.x,
			sy: selector.y,
			mx: map._x,
			my: map._y,
			stats: haxe.Json.stringify(stats)
		};
		#end
		// KKApi.gameOver(stats): stats is never set in the original
		KadoKadeoManager.kkm.gameOver({});
		over = true;
		setHandCursor(false);
	}

	// ---------------------------------------------------------------- port: mouse
	// The map is a Flash button (onPress = select, onRelease = onReleaseOutside = release) once initStep(Seek) gave it
	// its handlers; it covers the whole stage. The mouse is polled once per step (the replay records it), its button
	// changes taken in order. A press on the KadoKado bar under the stage is not on the game. A map removed while
	// pressed (a level change) gets no release: flAutoSelect stays on, as in Flash.
	// onPress runs select() with the action updateTarget computed at the last frame, under the pointer of then: a mouse
	// hovers the cell before pressing it, a finger does not. When the pointer moved during the step of a press (a tap
	// somewhere else), the button changes of the step wait for one Flash frame, which computes the action under it.
	// Returns the button changes still to make (mouseButtons), or null.
	function updateMouse():Array<{button:Int, isDown:Bool}> {
		var ox = xmouse, oy = ymouse;
		xmouse = Math.max(0, MouseManager.getX()) / K;
		ymouse = Math.max(0, MouseManager.getY()) / K;
		var changes = MouseManager.getFrameButtonChanges();
		var press = false;
		for (c in changes)
			if (c.button == MouseManager.BUTTON_LEFT && c.isDown)
				press = true;
		if (press && (xmouse != ox || ymouse != oy))
			return changes;
		mouseButtons(changes);
		return null;
	}

	function mouseButtons(changes:Array<{button:Int, isDown:Bool}>) {
		for (c in changes) {
			if (c.button != MouseManager.BUTTON_LEFT)
				continue;
			if (c.isDown) {
				pressed = (ymouse < mch && mapButton != null && !mapButton.removed) ? mapButton : null;
				// onPress
				if (pressed != null)
					select();
			} else if (pressed != null) {
				// onRelease / onReleaseOutside
				if (!pressed.removed)
					release();
				pressed = null;
			}
		}
	}

	// map.useHandCursor (live games only: the cursor of the page)
	function setHandCursor(on:Bool) {
		if (isReplay || on == handCursor)
			return;
		handCursor = on;
		var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
		if (canvas != null)
			canvas.style.cursor = on ? "pointer" : "";
	}

	// ---------------------------------------------------------------- port: display
	// the plasma is a bitmap of the screen, scrolled with the map at each Flash frame: it is shown where the map is shown
	// (one Flash frame behind, interpolated: see MC)
	function placePlasma() {
		var ms = map.spr;
		var h = plasma.holder;
		if (ms == null || ms._prevState == null) {
			h._x = 0;
			h._y = 0;
			if (h._prevState != null)
				h._prevState.copyFrom(h._curState);
			return;
		}
		h._x = Num.hMod(ms._curState.x - map._x, zw * 0.5);
		h._y = Num.hMod(ms._curState.y - map._y, zh * 0.5);
		if (h._prevState == null)
			h.updateState();
		h._prevState.x = Num.hMod(ms._prevState.x - map._x, zw * 0.5);
		h._prevState.y = Num.hMod(ms._prevState.y - map._y, zh * 0.5);
	}

	// the bitmaps drawn on the GPU, just before the screen is drawn
	function flushBitmaps() {
		if (ground != null)
			ground.drawSpectre(grid, size);
		if (plasma != null)
			plasma.flush();
	}

	// The first use of a filter compiles its shader (tens of ms of freeze): the glow of mcInter is drawn once now, off
	// screen (the plasma compiles its own)
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var holder = new Container();
		var s = new PixiSprite(Texture.WHITE);
		s.filters = [new FlashGlow(6, 6, 1, 0xFFFFFF)];
		holder.addChild(s);
		var rt:Dynamic = (cast RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	public function stageRoot():ASprite {
		return root != null ? root.spr : null;
	}

	public function destroy():Void {
		if (onPointerDown != null) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			if (canvas != null)
				canvas.removeEventListener("pointerdown", onPointerDown);
			onPointerDown = null;
		}
		setHandCursor(false);
		if (flushListener != null) {
			var ticker:Dynamic = KadoKadeoManager.kkm.ticker;
			ticker.remove(flushListener);
			flushListener = null;
		}
		if (plasma != null)
			plasma.destroy();
		plasma = null;
		MC.clearAll();
		for (b in bgBitmaps)
			b.destroy();
		bgBitmaps = [];
		ground = null;
		Sprite.spriteList = [];
		if (me == this)
			me = null;
	}
}
