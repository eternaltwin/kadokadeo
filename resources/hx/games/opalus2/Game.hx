package opalus2;

import haxe.io.UInt16Array;
import mt.bumdum.Sprite;
import common_haxe_avm1.KKApi;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;

class GridElem extends ASprite {
	public var flDead:Bool;
}

@:expose('GameOpalus2')
class Game implements kado.GameInterface {
	public static var DP_FRUIT = 2;
	public static var DP_PART = 3;

	public static var BLAST_TIME = 6;
	public static var FALL_WAIT = 20;
	public static var HAND_SPEED_COEF = 0.3;

	public static var FL_ENLIGHT = true;

	public var step:Int;
	public var turn:Int;
	public var bonus:Int;
	public var timer:Float;
	public var glowDec:Float;

	public var zlim:{
		xmin:Float,
		xmax:Float,
		ymin:Float,
		ymax:Float
	};

	public var zone:Array<{x:Int, y:Int}>;
	public var zoneMap:Array<Array<Bool>>;
	public var sel:Array<Array<{x:Int, y:Int}>>;
	public var dList:Array<{x:Int, y:Int}>;
	public var selectableMap:Array<Array<Bool>>;

	public var dm:DepthManager;
	public var gdm:DepthManager;

	var glow:Array<ASprite>;
	var fList:Array<Part>;
	var bg:ASprite;
	var map:ASprite;
	var blob:Blob;
	var hoverColor:Int;
	var isReplayMode:Bool;
	var hoveredCell:{x:Int, y:Int};

	var stats:{};

	var grid:Array<Array<GridElem>>;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		isReplayMode = isReplay;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
		});

		Cs.init();
		Cs.game = this;

		gdm = new DepthManager(root);
		map = gdm.attach("mcWallpaper", 1);

		Filt.glow(map, 30 * Cs.NEW_GEN_SCALE, 1.5, 0x397BFC);

		dm = new DepthManager(map);
		bg = gdm.attach("mcBg", 0);

		fList = new Array();
		glow = new Array();
		zone = new Array();

		glowDec = 0;
		hoverColor = -1;
		hoveredCell = null;

		initGrid();
		turn = Cs.TURN;

		zlim = {
			xmin: 99,
			ymin: 99,
			xmax: -99,
			ymax: -99
		};

		var mid = Std.int(Cs.GRID_MAX * 0.5);

		var zm = 0;
		var x = mid - zm;
		while (x <= mid + zm) {
			var y = mid - zm;
			while (y <= mid + zm) {
				free(x, y);
				y++;
			}
			x++;
		}

		blob = new Blob(gdm.attach("mcBlob", 3));
		blob.x = (mid + 0.5) * Cs.SIZE;
		blob.y = (mid + 0.5) * Cs.SIZE;
		blob.updateSize();

		map.mask = blob.root;
		map.onPress = function() {
			onMapPress();
		};
		map.useHandCursor = true;
		KKApi.registerButton(map);

		initStep(0);
	}

	public function initGrid() {
		grid = new Array();
		zoneMap = new Array();
		selectableMap = new Array();
		for (x in 0...Cs.GRID_MAX) {
			grid[x] = new Array();
			zoneMap[x] = new Array();
			selectableMap[x] = new Array();
			for (y in 0...Cs.GRID_MAX) {
				var mc:GridElem = cast dm.attach("mcFruit", DP_FRUIT);
				mc._x = (x + 0.5) * Cs.SIZE;
				mc._y = (y + 0.5) * Cs.SIZE;
				mc.flDead = false;
				grid[x][y] = mc;
				zoneMap[x][y] = false;
				selectableMap[x][y] = false;
				var id = getRandomId();
				mc.gotoAndStop(id + 1);
				// mc.cacheAsBitmap = true;

				/*
					var bmp = new flash.display.BitmapData(Cs.SIZE,Cs.SIZE,true,0x00000000);
					var base = dm.attach("mcFruit",0)
					var m = new flash.geom.Matrix()
					m.tx = Cs.SIZE*0.5
					m.ty = Cs.SIZE*0.5
					bmp.draw(base,m, null, null, null, null )
					mc.attachBitmap(bmp,1)
				 */
			}
		}
	}

	public function initStep(s:Int) {
		step = s;

		switch (step) {
			case 0: // CHOICE
				initSel();

			case 1: // DESTROY
				timer = Cs.TIME_EXPLODE;

			case 2: // ISOLATE

				if (dList.length == 0) {
					initStep(0);
				} else {
					timer = Cs.TIME_FALL;
					dList = getIsolateList();
					for (pos in dList) {
						var mc = grid[pos.x][pos.y];
						var p = new Part(gdm.attach("mcFruit", 8));
						p.x = mc._x;
						p.y = mc._y;
						p.weight = 0.4 * Cs.NEW_GEN_SCALE + Math.random() * 0.4 * Cs.NEW_GEN_SCALE;
						p.root.gotoAndStop(mc._currentframe);
						free(pos.x, pos.y);
						fList.push(p);
					}
				}

			case 9: // ENDGAME
				timer = 4;
				blob.tsx = 0;
				blob.tsy = 0;
		}
	}

	public function update(delta:Float) {
		for (event in KadoKadeoManager.kkm.replay.consumeEvents()) {
			applyReplayEvent(event);
		}

		timer -= Timer.tmod;
		if (!isReplayMode) {
			updateHover();
		}
		switch (step) {
			case 1: // DESTROY
				var prc = (1 - timer / Cs.TIME_EXPLODE) * 100;
				var list = new Array();

				for (p in dList) {
					var mc = grid[p.x][p.y];
					if (prc < 100) {
						Col.setPercentColor(mc, prc, 0xFFFFFF);
						mc._xscale = 100 - prc;
						mc._yscale = 100 - prc;
					} else {
						addChain(p.x, p.y, list);
						var ball = grid[p.x][p.y];
						blast(ball);
						KadoKadeoManager.kkm.addScore(KKApi.cadd(Cs.SCORE_BALL, bonus));
						free(p.x, p.y);
					}
				}
				if (timer <= 0) {
					blob.updateSize();
					if (list.length > 0) {
						dList = list;
						bonus = KKApi.cadd(Cs.SCORE_BONUS, bonus);
						initStep(1);
					} else {
						initStep(2);
					}
				}

			case 2: // ISOLATE
				/*
					var prc = (timer/Cs.TIME_FALL)*100
					for( var i=0; i<dList.length; i++ ){
						var p = dList[i];
						var mc = grid[p.x][p.y]
						if(prc>0){
							mc._xscale = prc
							mc._yscale = prc
						}else{
							var ball = grid[p.x][p.y]
							blast(ball)
							//KadoKadeoManager.kkm.addScore(Cs.SCORE[ball._currentframe-1])
							free(p.x,p.y)
						}
					}
				 */

				if (timer < 0) {
					if (KKApi.val(turn) > 0) {
						initStep(0);
					} else {
						initStep(9);
					}
				}
			case 9:
				if (timer < 0 && fList.length == 0) {
					KadoKadeoManager.kkm.gameOver(stats);
					initStep(10);
				}
		}

		// SPRITES
		for (l in Sprite.spriteList.copy()) {
			l.update();
		}

		// FALL
		var i = 0;
		while (i < fList.length) {
			var p = fList[i];
			if (p.y > Cs.mch + Cs.SIZE) {
				p.kill();
				fList.splice(i--, 1);
				KadoKadeoManager.kkm.addScore(Cs.SCORE_FALL);
			}
			i++;
		}

		// GLOW
		glowDec = (glowDec + 47) % 628;
		var prc = 50 + Math.cos(glowDec / 100) * 30;
		for (mc in glow) {
			Col.setPercentColor(mc, prc, 0xFFFFFF);
		}
	}

	public function initSel() {
		var colorMax = Cs.PROB.length;
		var centerEmpty = getCenterEmptyMap();
		var x = 0;
		while (x < Cs.GRID_MAX) {
			var y = 0;
			while (y < Cs.GRID_MAX) {
				selectableMap[x][y] = false;
				y++;
			}
			x++;
		}

		sel = new Array();
		for (i in 0...colorMax) {
			sel[i] = new Array();
		}
		for (x in 0...Cs.GRID_MAX) {
			for (y in 0...Cs.GRID_MAX) {
				if (grid[x][y] == null) {
					continue;
				}
				var hasVoidNeighbor = false;
				for (d in Cs.DIR) {
					var nx = d[0] + x;
					var ny = d[1] + y;
					if (nx >= 0 && ny >= 0 && nx < Cs.GRID_MAX && ny < Cs.GRID_MAX && centerEmpty[nx][ny] == true) {
						hasVoidNeighbor = true;
						break;
					}
				}
				if (hasVoidNeighbor) {
					selectableMap[x][y] = true;
					var mc = grid[x][y];
					var id = mc._currentframe - 1;
					sel[id].push({x: x, y: y});
				}
			}
		}

		hoverColor = -1;
		delight(-1);
	}

	public function selectFromCell(x:Int, y:Int) {
		if (x < 0 || y < 0 || x >= Cs.GRID_MAX || y >= Cs.GRID_MAX) {
			return;
		}
		if (!selectableMap[x][y]) {
			return;
		}
		var mc = grid[x][y];
		if (mc == null) {
			return;
		}
		select(mc._currentframe - 1);
	}

	public function emptySel() {
		delight(-1);
		hoverColor = -1;
		hoveredCell = null;
		var x = 0;
		while (x < Cs.GRID_MAX) {
			var y = 0;
			while (y < Cs.GRID_MAX) {
				selectableMap[x][y] = false;
				y++;
			}
			x++;
		}
		sel = new Array();
	}

	public function select(id) {
		dList = sel[id].copy();
		for (p in dList) {
			grid[p.x][p.y].flDead = true;
		}
		emptySel();
		turn = KKApi.cadd(turn, Cs.DEC_TURN);
		blob.panel.field.text = Std.string(KKApi.val(turn));
		// blob.turnList.pop().removeMovieClip();;
		bonus = KKApi.const(0);
		initStep(1);
	}

	public function enlight(id) {
		var list = sel[id];
		for (p in list) {
			var mc = grid[p.x][p.y];
			glow.push(mc);
		}
	}

	public function delight(id) {
		var i = 0;
		while (i < glow.length) {
			var mc = glow[i];
			Col.setPercentColor(mc, 0, 0xFFFFFF);
			glow.splice(i--, 1);
			i++;
		}
	}

	public function getMouseCell():{x:Int, y:Int} {
		var mx = map._xmouse;
		var my = map._ymouse;
		var cx = Std.int(Math.floor(mx / Cs.SIZE));
		var cy = Std.int(Math.floor(my / Cs.SIZE));
		if (cx < 0 || cy < 0 || cx >= Cs.GRID_MAX || cy >= Cs.GRID_MAX) {
			return null;
		}
		return {x: cx, y: cy};
	}

	public function getCenterEmptyMap():Array<Array<Bool>> {
		var centerEmpty = new Array();
		for (x in 0...Cs.GRID_MAX) {
			centerEmpty[x] = new Array();
		}

		var queueX = new Array<Int>();
		var queueY = new Array<Int>();
		var qh = 0;

		function addCenterEmpty(x:Int, y:Int) {
			if (x < 0 || y < 0 || x >= Cs.GRID_MAX || y >= Cs.GRID_MAX) {
				return;
			}
			if (centerEmpty[x][y] == true || grid[x][y] != null) {
				return;
			}
			centerEmpty[x][y] = true;
			queueX.push(x);
			queueY.push(y);
		}

		var mid = Std.int(Cs.GRID_MAX * 0.5);
		addCenterEmpty(mid, mid);
		while (qh < queueX.length) {
			var cx = queueX[qh];
			var cy = queueY[qh];
			qh++;
			for (d in Cs.DIR) {
				addCenterEmpty(cx + d[0], cy + d[1]);
			}
		}

		return centerEmpty;
	}

	public function updateHover() {
		updateHoverFromCell(getMouseCell(), true);
	}

	public function updateHoverFromCell(pos:{x:Int, y:Int}, ?recordEvent:Bool = false) {
		if (step != 0) {
			if (hoverColor != -1) {
				delight(hoverColor);
				hoverColor = -1;
			}
			hoveredCell = null;
			return;
		}

		var id = -1;
		if (pos != null && selectableMap[pos.x][pos.y]) {
			var mc = grid[pos.x][pos.y];
			if (mc != null) {
				id = mc._currentframe - 1;
			}
		}

		if (recordEvent && id != -1 && pos != null) {
			if (hoveredCell == null || hoveredCell.x != pos.x || hoveredCell.y != pos.y) {
				KadoKadeoManager.kkm.replay.recordEvent({k: 0, x: pos.x, y: pos.y});
			}
		}

		hoveredCell = (id != -1 && pos != null) ? {x: pos.x, y: pos.y} : null;

		if (id == hoverColor) {
			return;
		}

		if (hoverColor != -1) {
			delight(hoverColor);
		}
		hoverColor = id;
		if (hoverColor != -1) {
			enlight(hoverColor);
		}
	}

	public function onMapPress() {
		if (step != 0) {
			return;
		}
		var pos = getMouseCell();
		if (pos != null) {
			if (!isReplayMode) {
				KadoKadeoManager.kkm.replay.recordEvent({k: 2, x: pos.x, y: pos.y});
			}
			selectFromCell(pos.x, pos.y);
		}
	}

	public function applyReplayEvent(event:Dynamic) {
		if (event == null) {
			return;
		}

		var kind:Int = Reflect.field(event, "k");
		var x:Null<Int> = Reflect.field(event, "x");
		var y:Null<Int> = Reflect.field(event, "y");
		if (kind == null || x == null || y == null) {
			return;
		}

		switch (kind) {
			case 0:
				updateHoverFromCell({x: x, y: y}, false);
			case 1:
			case 2:
				updateHoverFromCell({x: x, y: y}, false);
				selectFromCell(x, y);
			default:
		}
	}

	//
	public function addChain(x, y, list) {
		var base = grid[x][y];
		for (d in Cs.DIR) {
			var nx = x + d[0];
			var ny = y + d[1];
			if (nx >= 0 && ny >= 0 && nx < Cs.GRID_MAX && ny < Cs.GRID_MAX) {
				var mc = grid[nx][ny];
				if (mc != null && base != null && mc._currentframe == base._currentframe && !mc.flDead) {
					list.push({x: nx, y: ny});
					mc.flDead = true;
				}
			}
		}
	}

	public function free(x, y) {
		if (zoneMap[x][y]) {
			return;
		}
		zoneMap[x][y] = true;
		zone.push({x: x, y: y});
		zlim.xmin = Math.min(zlim.xmin, x);
		zlim.ymin = Math.min(zlim.ymin, y);
		zlim.xmax = Math.max(zlim.xmax, x);
		zlim.ymax = Math.max(zlim.ymax, y);
		if (grid[x][y] != null) {
			grid[x][y].removeMovieClip();
			grid[x][y] = null;
		}
	}

	public function getRandomId() {
		var rnd = random(Cs.PROB_SUM);
		var sum = 0;
		for (i in 0...Cs.PROB.length) {
			sum += Cs.PROB[i];
			if (sum >= rnd)
				return i;
		}
		trace("RANDOM ID ERROR");
		return null;
	}

	public function random(max:Int):Int {
		return KadoKadeoManager.kkm.seed.random(max);
	}

	//
	public function eat(base) {
		/*
			var max = Math.min( 50/dList.length, 12 )
			for( var i=0; i<max; i++ ){
				var p = new Part(dm.attach("partRotSpark",DP_PART))
				var a  = Math.random()*6.28
				var sp = 2+Math.random()*3
				var ca = Math.cos(a);
				var sa = Math.sin(a);
				var ray = Cs.SIZE*0.4
				p.x = base._x + ca*ray
				p.y = base._y + sa*ray
				p.vx = ca*sp;
				p.vy = sa*sp;
				p.vr = (Math.random()*2-1)*30
				p.timer = 10+Math.random()*10
				p.frict = 0.92
				downcast(p.root).sub._x = Math.random()*10
			}
		 */
	}

	public function blast(base:GridElem) {
		if (base == null) {
			return;
		}
		var max = Std.int(Math.min(60 / dList.length, 12));
		for (i in 0...max) {
			var partB = dm.attach("partRotSpark" + base._currentframe, DP_PART);
			// partB.loop = true;
			partB.play();
			var p = new Part(partB);
			var a = Math.random() * 6.28;
			var sp = 2 + Math.random() * 3;
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.vr = (Math.random() * 2 - 1) * 30;
			p.timer = 10 + Math.random() * 10;
			p.frict = 0.92;
			var dist = Math.random() * 10 * Cs.NEW_GEN_SCALE;
			partB._x = dist;
			// p.root.sub._x = dist;
			var na = Math.random() * 6.28;
			p.root._rotation = na / 0.0174;
			p.x = base._x - Math.cos(na) * dist;
			p.y = base._y - Math.sin(na) * dist;
		}
	}

	//
	public function getIsolateList() {
		var safe = new Array();
		for (x in 0...Cs.GRID_MAX) {
			safe[x] = new Array();
		}

		var queueX = new Array<Int>();
		var queueY = new Array<Int>();
		var qh = 0;

		function addSafe(x:Int, y:Int) {
			if (x < 0 || y < 0 || x >= Cs.GRID_MAX || y >= Cs.GRID_MAX) {
				return;
			}
			if (safe[x][y] == true || grid[x][y] == null) {
				return;
			}
			safe[x][y] = true;
			queueX.push(x);
			queueY.push(y);
		}

		for (x in 0...Cs.GRID_MAX) {
			addSafe(x, 0);
			addSafe(x, Cs.GRID_MAX - 1);
		}
		for (y in 1...Cs.GRID_MAX - 1) {
			addSafe(0, y);
			addSafe(Cs.GRID_MAX - 1, y);
		}

		while (qh < queueX.length) {
			var cx = queueX[qh];
			var cy = queueY[qh];
			qh++;
			for (d in Cs.DIR) {
				addSafe(cx + d[0], cy + d[1]);
			}
		}

		var list = [];
		for (x in 1...Cs.GRID_MAX - 1) {
			for (y in 1...Cs.GRID_MAX - 1) {
				if (grid[x][y] != null && safe[x][y] != true)
					list.push({x: x, y: y});
			}
		}

		return list;
	}
}
