package opalus2;

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
	public var sel:Array<Array<{x:Int, y:Int}>>;
	public var dList:Array<{x:Int, y:Int}>;

	public var dm:DepthManager;
	public var gdm:DepthManager;

	var pList:Array<ASprite>;
	var glow:Array<ASprite>;
	var fList:Array<Part>;
	var bg:ASprite;
	var map:ASprite;
	var blob:Blob;

	var stats:{};

	var grid:Array<Array<GridElem>>;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		Cs.init();
		Cs.game = this;

		gdm = new DepthManager(root);
		map = gdm.attach("mcWallpaper", 1);

		Filt.glow(map, 30 * Cs.NEW_GEN_SCALE, 1.5, 0x397BFC);

		dm = new DepthManager(map);
		bg = gdm.attach("mcBg", 0);

		pList = new Array();
		fList = new Array();
		glow = new Array();
		zone = new Array();

		glowDec = 0;

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

		initStep(0);
	}

	public function initGrid() {
		grid = new Array();
		for (x in 0...Cs.GRID_MAX) {
			grid[x] = new Array();
			for (y in 0...Cs.GRID_MAX) {
				var mc:GridElem = cast dm.attach("mcFruit", DP_FRUIT);
				mc._x = (x + 0.5) * Cs.SIZE;
				mc._y = (y + 0.5) * Cs.SIZE;
				mc.flDead = false;
				grid[x][y] = mc;
				var id = getRandomId();
				mc.gotoAndStop(id + 1);
				mc.cacheAsBitmap = true;

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
						p.weight = 0.4 + Math.random() * 0.4;
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
		gdm.root_mc.update();
		timer -= Timer.tmod;
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
				if (timer < 0) {
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
					KKApi.gameOver(stats);
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
		var done = new Array();
		for (x in 0...Cs.GRID_MAX) {
			done[x] = new Array();
		}
		sel = new Array();
		for (i in 0...10) {
			sel[i] = new Array();
		}
		for (p in zone) {
			for (d in Cs.DIR) {
				var nx = d[0] + p.x;
				var ny = d[1] + p.y;
				if (done[nx][ny] == null) {
					done[nx][ny] = true;
					var mc = grid[nx][ny];
					if (mc != null) {
						var id = mc._currentframe - 1;
						sel[id].push({x: nx, y: ny});
						var cellX = nx;
						var cellY = ny;
						var colorId = id;
						mc.onPress = function() {
							selectFromCell(cellX, cellY);
						};
						mc.onRollOver = function() {
							enlight(colorId);
						};
						mc.onRollOut = function() {
							delight(colorId);
						};
						mc.onDragOut = function() {
							delight(colorId);
						};
						mc.useHandCursor = true;
					}
				}
			}
		}
	}

	public function selectFromCell(x:Int, y:Int) {
		if (x < 0 || y < 0 || x >= Cs.GRID_MAX || y >= Cs.GRID_MAX) {
			return;
		}
		var mc = grid[x][y];
		if (mc == null) {
			return;
		}
		select(mc._currentframe - 1);
	}

	public function emptySel() {
		while (sel.length > 0) {
			var list = sel.pop();
			while (list.length > 0) {
				var p = list.pop();
				var mc = grid[p.x][p.y];
				mc.onPress = null;
				mc.onRollOver = null;
				mc.onRollOut = null;
				mc.onDragOut = null;
				mc.useHandCursor = false;
				KKApi.registerButton(mc);
			}
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

	//
	public function addChain(x, y, list) {
		var base = grid[x][y];
		for (d in Cs.DIR) {
			var nx = x + d[0];
			var ny = y + d[1];
			var mc = grid[nx][ny];
			if (mc != null && base != null && mc._currentframe == base._currentframe && !mc.flDead) {
				list.push({x: nx, y: ny});
				mc.flDead = true;
			}
		}
	}

	public function free(x, y) {
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
		var rnd = Std.random(Cs.PROB_SUM);
		var sum = 0;
		for (i in 0...Cs.PROB.length) {
			sum += Cs.PROB[i];
			if (sum >= rnd)
				return i;
		}
		trace("RANDOM ID ERROR");
		return null;
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
			partB.loop = true;
			partB.play();
			var p = new Part(partB);
			var a = Math.random() * 6.28;
			var sp = 2 + Math.random() * 3;
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.vr = (Math.random() * 2 - 1) * 30;
			p.timer = 10 + Math.random() * 10;
			p.frict = 0.92;
			var dist = Math.random() * 10;
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
			for (y in 0...Cs.GRID_MAX) {
				if (grid[x][y] != null && (x == 0 || x == Cs.GRID_MAX - 1 || y == 0 || y == Cs.GRID_MAX - 1) && grid[x][y] != null) {
					safe[x][y] = true;
				}
			}
		}

		for (x in 1...Cs.GRID_MAX - 1) {
			for (y in 1...Cs.GRID_MAX - 1) {
				if (safe[x][y] == null) {
					var list = [];
					var verdict = findWay(x, y, safe, list);
					for (p in list) {
						safe[p.x][p.y] = verdict;
					}
				}
			}
		}

		var list = [];
		for (x in 1...Cs.GRID_MAX - 1) {
			for (y in 1...Cs.GRID_MAX - 1) {
				if (safe[x][y] == false)
					list.push({x: x, y: y});
			}
		}

		return list;
	}

	public function findWay(x:Int, y:Int, safe:Array<Array<Bool>>, list:Array<{x:Int, y:Int}>):Bool {
		var st = safe[x][y];
		if (st)
			return true;
		if (st == false || grid[x][y] == null)
			return false;
		for (p in list) {
			if (p.x == x && p.y == y)
				return false;
		}
		list.push({x: x, y: y});
		for (d in Cs.DIR) {
			var nx = x + d[0];
			var ny = y + d[1];
			if (findWay(nx, ny, safe, list))
				return true;
		}
		return false;

		/*
			var list = [{x:x,y:y}]
			for( var i=0; i<Cs.DIR.length; i++ ){
				var d = Cs.DIR[i]
				var nx = x+d[0]
				var ny = y+d[1]
				if()
				if ( grid[nx][ny]!=null && ( safe[nx][ny] || findWay(nx,ny,safe) ) ){
					for( var n=0; n<list.length; n++){
						var p = list[n]
						safe[p.x][p.y] = true
					}
					return true
				}

			}

			return false;
		 */
	}
}
