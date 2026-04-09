package kslash;

import haxe.io.UInt16Array;
import common_haxe_avm1.KeyboardManager;
import kado.TouchControlsConfig.TouchControlsMode;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import pixi.core.Pixi.BlendModes;
import pixi.core.graphics.Graphics;
import pixi.core.text.Text;
import mt.DepthManager;
import mt.Timer;
import mt.bumdum.Lib;

class Inter extends ASprite {
	public var fieldStar:Text;
}

@:expose('GameKSlash')
class Game implements kado.GameInterface {
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "action",
				label: "",
				size: 4000,
				action: "tap_action",
				invisible: true,
			},
			{
				id: "left",
				label: "<",
				leftPx: 10,
				bottomPx: 10,
				size: 72,
				keyCode: KeyboardManager.LEFT,
			},
			{
				id: "right",
				label: ">",
				leftPx: 82,
				bottomPx: 10,
				size: 72,
				keyCode: KeyboardManager.RIGHT,
			},
			{
				id: 'up',
				label: '^',
				rightPx: 10,
				bottomPx: 82,
				size: 72,
				keyCode: KeyboardManager.UP,
			},
			{
				id: 'down',
				label: 'v',
				rightPx: 10,
				bottomPx: 10,
				size: 72,
				keyCode: KeyboardManager.DOWN,
			},
		],
	};

	public static var DP_BG = 1;
	public static var DP_BACK = 2;
	public static var DP_MAP = 3;
	public static var DP_FRONT = 4;
	public static var DP_INTER = 5;

	public static var DP_MAPBG = 1;
	public static var DP_DECOR = 2;
	public static var DP_SHADE = 3;
	public static var DP_BONUS = 4;
	public static var DP_MONSTER = 5;
	public static var DP_HERO = 7;
	public static var DP_SHOOT = 10;
	public static var DP_PARTS = 12;

	public static var XMAX = 25;
	public static var YMAX = 25;

	public var flNight:Bool;
	public var monsterLevel:Int;
	public var monsterLevelMax:Float;
	public var dif:Float;

	var cheatTimer:Float;
	var pendingVirtualKeyUps:Array<{keyCode:Int, framesLeft:Int}>;

	public var pList:Array<Part>;
	public var platList:Array<{
		x:Int,
		y:Int,
		w:Int,
	}>;
	public var mList:Array<Monster>;
	public var sList:Array<Shoot>;
	public var nsList:Array<Shoot>;
	public var bList:Array<Bonus>;
	public var iconList:Array<ASprite>;
	public var planList:Array<{mc:ASprite, c:Float, y:Float}>;
	public var optList:Array<Bool>;

	public var stats:{opt:Array<Int>, bads:Array<Int>, dif:Int};

	public var dm:DepthManager;
	public var mdm:DepthManager;

	public var hero:Hero;

	var root:ASprite;
	var bg:ASprite;
	var map:ASprite;

	public var inter:Inter;

	public var grid:Array<Array<{block:Bool, list:Array<Monster>}>>;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(6);
		replayKeys[0] = KeyboardManager.ARROW_RIGHT;
		replayKeys[1] = KeyboardManager.ARROW_DOWN;
		replayKeys[2] = KeyboardManager.ARROW_LEFT;
		replayKeys[3] = KeyboardManager.ARROW_UP;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.CONTROL;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		Cs.game = this;
		dm = new DepthManager(root);
		this.root = root;
		bg = dm.attach("bg", DP_BG);
		bg.stop();
		inter = cast dm.attach("inter", DP_INTER);
		var txt = inter.initTextField("fieldStar", {
			font: "Impact",
			size: 40,
			color: 0x000000,
			align: "left",
			stroke: "#FFFFFF",
			strokeThickness: 3,
		});
		txt.x = 60;
		txt.y = 6;

		mList = new Array();
		sList = new Array();
		bList = new Array();
		pList = new Array();
		nsList = new Array();
		iconList = new Array();
		planList = new Array();

		stats = {
			opt: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			bads: [0, 0, 0, 0, 0],
			dif: null
		};

		map = dm.empty(DP_MAP);
		mdm = new DepthManager(map);

		planList.push({mc: bg, c: 0.13, y: 0});
		planList.push({mc: map, c: 1, y: 0});

		for (n in 0...2) {
			for (i in 0...10) {
				var m = null;
				var oy = 0;
				if (n == 0) {
					m = dm.attach("bgFront", DP_FRONT);
				} else {
					m = dm.attach("bgBack", DP_BACK);
					oy = 1350;
				}
				m.gotoAndStop(i + 1);
				var c = (m._width - Cs.mcw) / Cs.mcw;
				planList.push({mc: m, c: c, y: oy});
				if (i + 1 == m._totalframes)
					break;
			}
		}

		hero = new Hero(mdm.attach("mcHero", DP_HERO));

		flNight = false;
		if (Cs.rand() * 500 < 1)
			setNight();
		initGrid();
		initPlat();

		monsterLevelMax = 2;
		monsterLevel = 0;

		dif = 0;

		optList = [false, false, false];
		updateIcons();

		cheatTimer = 0;
		pendingVirtualKeyUps = [];
	}

	public function initGrid() {
		grid = new Array();
		for (x in 0...XMAX) {
			grid[x] = new Array();
			for (y in 0...YMAX) {
				grid[x][y] = {block: false, list: []};
			}
		}
	}

	public function initPlat() {
		var rt = RenderTexture.create(Cs.SIZE * XMAX, Cs.SIZE * YMAX);
		platList = [
			{
				x: 0,
				y: YMAX - 1,
				w: XMAX,
			}
		];
		var y = YMAX - 1;

		while (y > 8) {
			y -= Cs.PLAT_ECART;
			var x = Cs.random(4);
			while (x < XMAX) {
				var w = 2 + Cs.random(8);
				platList.push({
					x: x,
					y: y,
					w: w,
				});
				x += w + 2 + Std.int(Cs.random(8) * (1 - (y / YMAX)));
			}
		}

		for (o in platList) {
			var mc = mdm.attach("mcPlat", DP_DECOR);
			mc.gotoAndStop(flNight ? 2 : 1);

			var m = new Matrix();
			m.translate(Cs.SIZE * o.x, Cs.SIZE * o.y);
			rt.draw(mc, m);
			mc.removeMovieClip();

			var g = (new Graphics()).beginFill(0xFFFFFF).drawRect(0, -5, 3000, Cs.SIZE + 10);
			g.blendMode = untyped BlendModes.ERASE;
			m = new Matrix();
			m.translate(Cs.SIZE * (o.x + o.w) - 19 * Cs.NEW_GEN_SCALE, Cs.SIZE * o.y);
			rt.draw(g, m);

			var c = new ASprite("corner");
			c.gotoAndStop(flNight ? 2 : 1);
			m = new Matrix();
			m.translate(Cs.SIZE * (o.x + o.w) - 20 * Cs.NEW_GEN_SCALE, Cs.SIZE * o.y);
			rt.draw(c, m);
			c.removeMovieClip();

			setPlat(o);
		}
		var b = mdm.empty(DP_DECOR);
		b.attachBitmap(rt, 1);
	}

	public function setPlat(o:{
		x:Int,
		y:Int,
		w:Int,
	}) {
		for (n in 0...o.w) {
			if (o.x + n < XMAX && o.y < YMAX) {
				grid[o.x + n][o.y].block = true;
			}
		}
	}

	public function update(delta:Float) {
		/*
			Log.print(int(monsterLevel))
			Log.print("-")
			Log.print(int(monsterLevelMax))
		 */
		hero.update();
		for (m in mList) {
			m.update();
		}
		for (s in sList) {
			s.update();
		}
		for (b in bList) {
			b.update();
		}
		updateScroll();
		updateParts();

		if (monsterLevel < monsterLevelMax) {
			addMonster();
		}

		monsterLevelMax += 0.0025 * Timer.tmod;
		dif += 1.5 * Timer.tmod;
		flushPendingVirtualKeyUps();
		// monsterLevelMax += 0.025*Timer.tmod;
		// dif+=15*Timer.tmod;

		// cheat();
	}

	public function onTouchAction(action:String):Void {
		switch (action) {
			case "tap_action":
				queueVirtualTap(KeyboardManager.SPACE);
		}
	}

	function queueVirtualTap(keyCode:Int):Void {
		KeyboardManager.queueVirtualKeyDown(keyCode);
		pendingVirtualKeyUps.push({
			keyCode: keyCode,
			framesLeft: 2
		});
	}

	function flushPendingVirtualKeyUps():Void {
		if (pendingVirtualKeyUps == null || pendingVirtualKeyUps.length == 0) {
			return;
		}

		var keep:Array<{keyCode:Int, framesLeft:Int}> = [];
		for (entry in pendingVirtualKeyUps) {
			entry.framesLeft--;
			if (entry.framesLeft <= 0) {
				KeyboardManager.queueVirtualKeyUp(entry.keyCode);
			} else {
				keep.push(entry);
			}
		}
		pendingVirtualKeyUps = keep;
	}

	public function updateScroll() {
		for (info in planList) {
			var mx = 0; // Cs.SIZE * info.c * 0.25;
			var tx = Math.min(Math.max(2 * mx - (XMAX) * Cs.SIZE * 0.5, (Cs.mcw * 0.5 - hero.root._x)), -mx);
			var ty = Math.min(Math.max(-YMAX * Cs.SIZE * 0.5, (Cs.mch * 0.5 - hero.root._y)), 0);
			info.mc._x = tx * info.c;
			info.mc._y = ty * info.c + info.y;
		}
	}

	public function addMonster() {
		// newMonster(4)
		// return;

		// TANKER
		if (dif > 4000 && Cs.random(4) == 0) {
			newMonster(4);
		}
		// FLIER
		if (dif > 1800 && Cs.random(4) == 0) {
			newMonster(3);
		}
		//*/
		// RUNNER
		newMonster(Cs.random(Std.int(Math.min(Math.ceil(dif / 1300), 3))));
	}

	public function newMonster(id) {
		Cs.game.stats.bads[id]++;
		var sens = (hero.x < XMAX * 0.5) ? 1 : 0;
		var m:Monster = null;
		switch (id) {
			case 0 | 1 | 2:
				m = new Soldier(mdm.attach("mcMonster" + (id + 1), DP_MONSTER));
				m.x = sens * XMAX;
				m.y = YMAX - (2 + (Cs.random(6)) * Cs.PLAT_ECART);
				m.dx = Cs.rand() * 10;
				m.setSens(-(sens * 2 - 1));
				untyped m.setLevel(id + 1);
			case 3:
				m = new Flyer(mdm.attach("mcFlyer", DP_MONSTER));
				m.x = Cs.random(XMAX);
				m.y = 0;
			case 4:
				m = new Tanker(mdm.attach("mcTanker", DP_MONSTER));
				m.x = sens * XMAX;
				m.y = YMAX - (2 + (Cs.random(6)) * Cs.PLAT_ECART);
		}

		monsterLevel += m.stLevel;
		m.root.updateState();
		return m;
	}

	public function spawnBonus(x, y, id) {
		if (id == 0)
			return;
		if (id >= 6 && id < 9) {
			if (optList[id - 6])
				id = 1;
		}
		var b = new Bonus(mdm.attach("bonus", DP_BONUS));
		b.root._x = x; // (x+0.5)*Cs.SIZE;
		b.root._y = y; // (y+0.5)*Cs.SIZE;
		b.setId(id);
	}

	public function updateIcons() {
		while (iconList.length > 0)
			iconList.pop().removeMovieClip();
		var x = Cs.mcw;
		for (i in 0...optList.length) {
			if (optList[i]) {
				var mc = dm.attach("mcIcon", DP_INTER);
				mc.gotoAndStop(i + 1);
				mc._x = x;
				x -= 20 * Cs.NEW_GEN_SCALE;
				iconList.push(mc);
			}
		}
	}

	public function checkFree(x, y) {
		if (x < 0 || x >= XMAX || y < 0 || y >= YMAX) {
			return true;
		}
		return !grid[x][y].block;
	}

	public function getClosestMonsters():Array<{m:Monster, d:Float}> {
		var list = new Array<{m:Monster, d:Float}>();

		for (m in mList) {
			var d = Math.max(Math.abs(m.x - hero.x), Math.abs(m.y - hero.y));
			var n = 0;
			do {
				if (list[n] == null || list[n].d > d)
					break;
				n++;
			} while (n < list.length);
			list.insert(n, {m: m, d: d});
		}
		return list;
	}

	public function setNight() {
		if (!flNight) {
			flNight = true;
			bg.gotoAndStop(2);

			for (o in planList) {
				if (o.c != 1 && o.c > 0.5)
					Col.setPercentColor(o.mc, 40, 0x000044);
			}
		}
	}

	// PARTS
	public function updateParts() {
		for (p in pList) {
			p.update();
		}
	}

	public function newPart(link):Part {
		var p = new Part(mdm.attach(link, DP_PARTS));
		p.vx = 0;
		p.vy = 0;
		p.frict = 0.95;
		p.scale = 100;
		pList.push(p);
		return p;
	}

	/*/ DEBUG
		function logGrid(){
			var str = ""
			var max = 18
			for( var y=0; y<max; y++ ){
				for( var x=0; x<max; x++ ){
					var o = grid[x][y]
					str +=o.list.length
				}
				str+="\n"
			}
			Log.print(str)
		}

		function cheat(){
			if(cheatTimer>0){
				cheatTimer-=Timer.tmod

			}else{
				if(Key.isDown(Key.ENTER) && !hero.flInvicible ){
					hero.flInvicible = true

				}
				for(var i=0; i<10; i++ ){
					if( Key.isDown(96+i) ){
						newMonster(i)
						cheatTimer = 10
					}
				}
			}
		}
		// */
	// {
	public function destroy():Void {
		Cs.game = null;
	}
}
