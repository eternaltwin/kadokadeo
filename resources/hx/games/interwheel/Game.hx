package interwheel;

import pixi.core.text.Text;
import js.html.KeyboardEvent;
import mt.Timer;
import common_haxe_avm1.KeyboardManager;
import mt.DepthManager;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.KKApi;

class McPanel extends ASprite {
	public var panel:ASprite;
	public var txt:Text;
}

typedef FocusTarget = {
	var x:Float;
	var y:Float;
}

@:expose('GameInterwheel')
class Game implements kado.GameInterface {
	public var kkm:kado.KadoKadeoManager;

	public static var DP_BG = 1;
	public static var DP_SHADE = 2;
	public static var DP_OIL = 3;
	public static var DP_BLOB = 4;
	public static var DP_WHEEL = 5;
	public static var DP_STAR = 6;
	public static var DP_PART = 8;
	public static var DP_WATER = 10;
	public static var DP_WPART = 12;

	public static var DEBUG = false;

	var flCameraJump:Bool;

	var genStep:Int;
	var timer:Float;
	var maxHeight:Float;
	var svy:Float;
	var roof:Float;
	var waterBoost:Float;

	public var blob:Blob;
	public var step:Int;
	public var dm:DepthManager;
	public var gdm:DepthManager;
	public var focus:FocusTarget;
	public var eList:Array<{s:Int, e:Int, list:Array<Element>}>;
	public var sList:Array<Sprite>;
	public var sparkList:Array<Spark>;
	public var water:ASprite;
	public var map:ASprite;

	var gList:Array<{
		x:Float,
		y:Float,
		mc:ASprite,
		type:Int
	}>;
	var awList:Array<Wheel>;
	var bg:ASprite;
	var bgs:ASprite;
	var wheelLoading:ASprite;
	var panel:McPanel;

	public var stats:{
		b:Array<Int>,
		hm:Int,
		jp:Int,
		pl:Int,
		bl:Int
	};

	public function new(kkm:kado.KadoKadeoManager, root:ASprite) {
		this.kkm = kkm;
		Cs.init();
		Cs.game = this;

		gdm = new DepthManager(root);
		map = gdm.empty(1);
		map._y = Cs.mch;
		map._x = Cs.mcw;

		dm = new DepthManager(map);
		// bg = gdm.attach("mcBg",0)
		// bgs = gdm.attach("mcBackground",0)

		sList = new Array();
		eList = new Array();
		sparkList = new Array();

		svy = 0;
		waterBoost = 0;

		stats = {
			b: [0, 0, 0],
			hm: 0,
			jp: 0,
			pl: 0,
			bl: 0
		};

		maxHeight = 0;
		focus = {x: Cs.mcw, y: 0};

		initStep(1);
	}

	function initDecor(n) {
		var size = 40 * Cs.NEW_GEN_SCALE;
		var height = 2000 * Cs.NEW_GEN_SCALE;
		var xMax = Std.int(Cs.mcw / size);
		var yMax = Std.int(height / size);

		var bmp = RenderTexture.create(Cs.mcw, height);
		var bg = new ASprite();
		bg.getGraphics().beginFill(0xe5be6a);
		bg.getGraphics().drawRect(0, 0, Cs.mcw, height);
		Cs.drawMcAt(bmp, bg, 0, 0);
		bg.removeMovieClip();
		for (x in 0...xMax) {
			for (y in 0...yMax) {
				var mc = gdm.attach("mcTile", 10);
				mc.gotoAndStop(n * 10 + Std.random(10) + 1);
				Cs.drawMcAt(bmp, mc, x * size, y * size);
				mc.removeMovieClip();
			}
		}
		var by:Float = 100 * Cs.NEW_GEN_SCALE;
		while (by < height) {
			if (Math.random() < 0.2) {
				var link = "mcMotif";
				var bx:Float = Std.random(Cs.mcw);
				if (Math.random() < 0.2) {
					link = "mcFrise";
					bx = Cs.mcw * 0.5;
				}
				var mc = gdm.attach(link, 10);
				by += mc._height * 0.5;
				mc.gotoAndStop(Std.random(mc._totalframes) + 1);
				Cs.drawMcAt(bmp, mc, bx, by);
				by += mc._height * 0.5;
				mc.removeMovieClip();
			}

			by += Std.random(100 * Cs.NEW_GEN_SCALE);
		}

		for (y in 0...yMax) {
			for (i in 0...2) {
				var mc = gdm.attach("mcSide", 10);
				Cs.drawMcAt(bmp, mc, i * (Cs.mcw - Cs.SIDE), y * size);
				mc.removeMovieClip();
			}
		}
		var skin = dm.empty(DP_BG);
		skin.attachBitmap(bmp, 1);
		skin._y = -(n + 1) * height;
	};

	function initWheels() {
		var list = new Array();

		var ow = new Wheel();
		ow.ray = (Cs.mcw - 2 * (Cs.SIDE + Cs.SPACE)) * 0.5;
		ow.x = Cs.mcw * 0.5; // Math.random()*Cs.mcw - Cs.SIDE*2
		ow.y = 0;
		ow.speed = 0.1;

		list.push(ow);

		for (i in 0...Cs.WMAX) {
			var c = Cs.mm(0, (i / Cs.WMAX) + (Math.random() * 2 - 1) * Cs.DIF_RANDOMIZER, 1);
			var c2 = Cs.mm(0, (i / Cs.WMAX) + (Math.random() * 2 - 1) * Cs.DIF_RANDOMIZER, 1);
			var c3 = Cs.mm(0, (i / Cs.WMAX) + (Math.random() * 2 - 1) * Cs.DIF_RANDOMIZER, 1);

			var w = new Wheel();
			w.ray = Cs.WHEEL_RAY_MIN + (1 - c2) * (Cs.WHEEL_RAY_MAX - Cs.WHEEL_RAY_MIN) + Math.random() * Cs.WHEEL_RAY_RANDOM;
			w.speed = Cs.WHEEL_SPEED_MIN + c3 * (Cs.WHEEL_SPEED_MAX - Cs.WHEEL_SPEED_MIN) + Math.random() * Cs.WHEEL_SPEED_RANDOM;

			var dist = Cs.WHEEL_DIST_MIN + c * (Cs.WHEEL_DIST_MAX - Cs.WHEEL_DIST_MIN) + (ow.ray + w.ray);
			var a = null;
			var lim = Cs.SIDE + Cs.SPACE + w.ray;
			var flBreak = null;
			while (true) {
				a = -1.57 + (Math.random() * 2 - 1) * 1.4;
				w.x = ow.x + Math.cos(a) * dist;
				w.y = ow.y + Math.sin(a) * dist;
				flBreak = w.x > lim && w.x < Cs.mcw - lim;
				if (flBreak) {
					var w2 = list[list.length - 2];
					if (w2 != null) {
						if (Cs.getDist(w, w2) < w.ray + w2.ray) {
							flBreak = false;
						}
					}
				}
				if (flBreak)
					break;
			}
			// w.addMine();
			while (Math.random() + 0.4 < c) {
				w.addMine();
			}

			// INTER WHEEL
			if (Math.random() > c) {
				var nw = new Wheel();
				nw.y = (w.y + ow.y) * 0.5;
				var tr = 0;
				while (true) {
					flBreak = true;

					nw.ray = Cs.WHEEL_RAY_MIN + 10 + Math.random() * (Cs.WHEEL_RAY_MAX - Cs.WHEEL_RAY_MIN);
					nw.speed = Cs.WHEEL_SPEED_MIN + Math.random() * (Cs.WHEEL_SPEED_MAX - Cs.WHEEL_SPEED_MIN);
					var m = Cs.SIDE + Cs.SPACE + nw.ray;
					nw.x = m + Cs.mcw - (2 * m);
					var lst = [w, ow];
					for (w2 in lst) {
						if (Cs.getDist(nw, w2) < nw.ray + w2.ray + Cs.SPACE) {
							flBreak = false;
							break;
						}
					}

					if (flBreak) {
						list.push(nw);
						break;
					}
					if (tr++ > 30)
						break;
				}
			}

			//
			ow = w;
			list.push(w);
		}
		roof = ow.y - ow.ray;
		eList.push({list: cast list, s: Cs.START_WHEEL_ID, e: Cs.START_WHEEL_ID - 1});
	}

	function initPastilles() {
		var list = new Array();
		var y = -100 * Cs.NEW_GEN_SCALE;
		while (y > roof) {
			if (Math.random() < y / roof) {
				var p = new Pastille();
				var m = Cs.SIDE + p.ray;
				p.x = m + Math.random() * (Cs.mcw - 2 * m);
				p.y = y;
				list.push(p);
			}
			y -= 20 * Cs.NEW_GEN_SCALE;
		}
		eList.push({list: cast list, s: Cs.START_WHEEL_ID, e: Cs.START_WHEEL_ID - 1});
	}

	public function initStep(s:Int) {
		step = s;

		switch (step) {
			case 0: //
				initWheels();
				initPastilles();

				//
				blob = new Blob(dm.attach("mcBlob", DP_BLOB));
				blob.x = Cs.mcw * 0.5;
				blob.y = 0;
				blob.cw = cast eList[0].list[Cs.START_WHEEL_ID];
				blob.initStep(2);

				// water = dm.attach("mcWater", DP_WATER);
				water = dm.empty(DP_WATER);
				water.getGraphics().beginFill(0x30d8d8, 0.5);
				water.getGraphics().drawRect(0, 0, 900, 3060);
				water._y = -300;

				flCameraJump = true;

				KKApi.processing(false);
				map._x = 0;

				panel = new McPanel();
				panel.panel = gdm.attach("mcPanel", 5);
				panel.txt = panel.panel.initTextField('field', {
					color: 0xe1bd6a,
					align: "left",
					font: "Chubby Cheeks",
					size: 46,
					bold: false,
					x: 28,
					y: 16
				});

				wheelLoading.removeMovieClip();
			case 1: // INITDECOR
				wheelLoading = gdm.attach("mcWheelLoading", 5);
				wheelLoading._x = Cs.mcw * 0.5;
				wheelLoading._y = Cs.mcw * 0.5;
				KKApi.processing(true);
				genStep = 0;
			case 9: // ENDGAME
				timer = 30;
				focus = {x: blob.x, y: blob.y};
		}
	}

	public function update(delta:Float) {
		dm.root_mc.update();
		timer -= Timer.tmod;
		#if debug
		if (KeyboardManager.isDown(KeyboardEvent.DOM_VK_RETURN)) {
			water._y -= 4 * Timer.tmod;
		}
		#end

		updateElements();

		switch (step) {
			case 0:
				waterBoost += Cs.WATER_SPEED_INC * Timer.tmod;
				water._y -= (Cs.WATER_SPEED + waterBoost) * Timer.tmod;
				blob.checkDeath();

				var dx = -blob.y - maxHeight;
				if (dx > 0)
					kkm.addScore(KKApi.const(Std.int(dx)));
				maxHeight = Math.max(-blob.y, maxHeight);
				var n = Std.int(maxHeight * 0.2);
				panel.txt.text = n + "m";
				stats.hm = n;
			case 1:
				initDecor(genStep);
				genStep++;
				if (genStep == 5)
					initStep(0);
			case 9:
				if (timer < 0) {
					kkm.gameOver(stats);
					initStep(10);
				}
		}

		// SPARKS BOUNCE
		var i = 0;
		while (i < sparkList.length) {
			var p0 = sparkList[i];
			var n = i + 1;
			while (n < sparkList.length) {
				var p1 = sparkList[n];
				var dif = 16 - p0.getDist(p1);

				if (dif > 0) {
					var a = p0.getAng(p1);
					var cx = Math.cos(a) * dif * 0.5;
					var cy = Math.sin(a) * dif * 0.5;
					p0.x -= cx;
					p0.y -= cy;
					p1.x += cx;
					p1.y += cy;
				}
				n++;
			}
			i++;
		}
		// SCROLL
		scrollMap();

		// SPRITES
		var list = sList.copy();
		for (e in list) {
			e.update();
		}
	}

	function scrollMap() {
		var fy = focus.y;
		var ty = Cs.mch * 0.5 - fy;
		var dy = ty - map._y;
		svy += dy * 0.1 * Timer.tmod;
		svy *= Math.pow(0.6, Timer.tmod);

		// map._y = Math.max( Cs.mch-10,map._y+svy*Timer.tmod )
		map._y += svy * Timer.tmod;
		// bgs._y = Cs.mch + map._y * 0.1;

		if (flCameraJump) {
			map._y = ty;
			svy = 0;
			flCameraJump = false;
		}
	}

	function updateElements() {
		for (o in eList) {
			var flAgain = false;

			var flFirst = true;
			var tr = 0;
			while (true) {
				var flBreak = true;
				var i = o.s;
				while (i <= o.e) {
					var w = o.list[i];
					if (flFirst)
						w.update();

					if (w.flRemove) {
						o.e--;
						w.detach();
						o.list.splice(i--, 1);
						flBreak = false;
					} else if (w.y - w.ray > -map._y + Cs.mcw) {
						o.s++;
						w.detach();
						flBreak = false;
					} else if (w.y + w.ray < -map._y) {
						o.e--;
						w.detach();
						flBreak = false;
					}
					i++;
				}

				var w = o.list[o.s - 1];
				if (w != null) {
					if (w.y - w.ray < -map._y + Cs.mcw) {
						o.s--;
						w.attach();
						flBreak = false;
					}
				}

				w = o.list[o.e + 1];
				if (w != null) {
					if (w.y + w.ray > -map._y) {
						o.e++;
						w.attach();
						flBreak = false;
					}
				}
				flFirst = false;
				if (flBreak || tr++ > 20)
					break;
			}
		}
	}
}
