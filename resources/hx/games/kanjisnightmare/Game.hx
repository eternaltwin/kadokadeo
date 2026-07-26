package kanjisnightmare;

import mt.bumdum.Lib;
import mt.bumdum.Lib.PointWithGetter;
import pixi.core.math.Point;
import common_haxe_avm1.KKApi;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import haxe.io.UInt16Array;
import kado.KadoKadeoManager;
import mt.DepthManager;
import mt.Timer;
import mt.bumdum.Plasma;
import mt.bumdum.Sprite;
import pixi.core.Pixi.BlendModes;
import pixi.filters.blur.BlurFilter;
import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.filters.extras.GlowFilter;

class PlanSprite extends ASprite {
	public var c:Float;
	public var w:Float;
	public var dy:Float;
	public var type:Int;
}

@:expose('GameKanjisNightmare')
class Game implements kado.GameInterface {
	static var DEBUG_SCALE = null;

	static var FRONT_VISIBILITY_FX = 0;
	//
	public static var DP_BG = 1;
	public static var DP_MAP = 2;
	public static var DP_FRONT = 3;
	public static var DP_INTER = 4;

	//
	public static var DP_BACK = 2;
	public static var DP_PLAT = 2;
	public static var DP_ROPE = 3;
	public static var DP_MONS = 4;
	public static var DP_HERO = 5;
	public static var DP_BONUS = 6;
	public static var DP_MEDUSA = 7;
	public static var DP_SHOT = 8;
	public static var DP_PARTS = 9;
	public static var DP_DECOR = 10;

	var genPlatCoef:Int;
	var dif:Float;

	public var flMouseDead:Bool;
	public var mouseDeadTimer:Float;
	public var mousePos:PointWrapper;
	public var medusa:Medusa;

	var parc:Float;
	var handicap:Float;

	public var scrollMin:Float;

	var scrollSpeed:Float;

	public var pList:Array<Part>;
	public var mList:Array<Monster>;
	public var nsList:Array<Star>;
	public var bonusList:Array<Bonus>;
	public var platList:Array<Plat>;
	public var hero:Hero;

	public var stats:{opt:Array<Int>, bads:Array<Int>, dif:Int};
	public var dm:DepthManager;
	public var mdm:DepthManager;
	public var root:ASprite;
	public var map:ASprite;
	public var mcLine:ASprite;
	public var auraPlasma:Plasma;
	public var focus:PointWithGetter;

	var plans:Array<PlanSprite>;
	var caveTopSegments:Array<ASprite>;
	var bg:ASprite;
	var bdm:DepthManager;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(12);
		replayKeys[0] = KeyboardManager.LEFT;
		replayKeys[1] = KeyboardManager.RIGHT;
		replayKeys[2] = KeyboardManager.UP;
		replayKeys[3] = KeyboardManager.DOWN;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.CONTROL;
		replayKeys[6] = KeyboardManager.Q;
		replayKeys[7] = KeyboardManager.A;
		replayKeys[8] = KeyboardManager.D;
		replayKeys[9] = KeyboardManager.W;
		replayKeys[10] = KeyboardManager.Z;
		replayKeys[11] = KeyboardManager.S;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: new UInt16Array(0),
		});

		Cs.game = this;
		Hero.SPEED = KadoKadeoManager.I(6);
		dm = new DepthManager(root);
		this.root = root;
		bg = dm.attach("mcBg", DP_BG);
		mousePos = new PointWrapper({x: 0, y: 0});

		// LISTS
		mList = new Array();
		pList = new Array();
		nsList = new Array();
		platList = new Array();
		bonusList = new Array();

		initMap();
		initAuraPlasma();

		flMouseDead = false;

		scrollSpeed = KadoKadeoManager.S(0.5);
		dif = 0;
		parc = 0;
		genPlatCoef = 10;
		handicap = 0;

		stats = {opt: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], bads: [0, 0, 0], dif: null};

		scrollMin = map._x + KadoKadeoManager.I(300);

		hero = new Hero(mdm.empty(DP_HERO));

		medusa = new Medusa(this);

		genPlat(0, KadoKadeoManager.I(270), KadoKadeoManager.I(1000));
		genPlat(Cs.mcw * 2, KadoKadeoManager.I(200), KadoKadeoManager.I(1000));

		focus = hero;

		if (DEBUG_SCALE != null) {
			root._xscale = DEBUG_SCALE;
			root._yscale = root._xscale;
			root._x += KadoKadeoManager.I(100);
		}
	}

	public function destroy():Void {
		Hero.SPEED = KadoKadeoManager.I(6);
	}

	function initAuraPlasma() {
		var mc = mdm.empty(DP_HERO);
		mc.blendMode = BlendModes.ADD;
		mc._alpha = 80;
		var pq = 0.5;
		auraPlasma = new Plasma(mc, Std.int(Cs.mcw * 3 * pq), Std.int(Cs.mch * 2 * pq), pq);
		var fade = new ColorMatrixFilter();
		fade.matrix = [
			1, 0, 0, 0,        0,
			0, 1, 0, 0,        0,
			0, 0, 1, 0,        0,
			0, 0, 0, 1, -20 / 255,
		];
		auraPlasma.ct = fade;
		var blur = new BlurFilter();
		blur.blurX = Std.int(KadoKadeoManager.I(4));
		blur.blurY = Std.int(KadoKadeoManager.I(20));
		auraPlasma.filters = [cast blur];
	}

	function initMap() {
		// INIT PLANS
		plans = [];
		var cl = [0.1, 0.4, 0.8, 1, 1.5];
		for (i in 0...cl.length) {
			var c = cl[i];
			if (c == 1) {
				map = dm.empty(DP_MAP);
				(cast map).c = 1;
				mdm = new DepthManager(map);
			} else {
				for (n in 0...2) {
					var plan:PlanSprite = cast dm.attach("mcPlan", DP_MAP);
					plan.gotoAndStop(i + 1);
					plan.w = plan._width;
					plan.x = plan.w * n;
					plan.y = 0;
					plan.c = c;
					plan.type = 0;
					plans.push(plan);
				}
			}
		}

		// CAVE TOP
		caveTopSegments = [];
		for (i in 0...4)
			caveTopSegments.push(createCaveTopSegment(Cs.mcw * i));

		// LINE
		mcLine = mdm.empty(DP_ROPE);
	}

	public function update(delta:Float) {
		mcLine.clear();
		dif += Timer.tmod;
		stats.dif = Std.int(dif);

		bg._y = map._y * 0.5;

		medusa.update();
		updateScroll();
		updateEnvFX();

		var oldMousePos = {x: mousePos.x, y: mousePos.y};
		mousePos.x = Num.q(MouseManager.getX());
		mousePos.y = Num.q(MouseManager.getY());
		if (oldMousePos.x != mousePos.x || oldMousePos.y != mousePos.y) {
			mouseMove();
		}

		Sprite.updateAll();
	}

	// SCROLL
	function updateScroll() {
		var base = focus;

		if (hero.flEat) {
			var c = 0.9;
			base = {
				x: focus.x * c + medusa.medusa.x * (1 - c),
				y: focus.y * c + medusa.medusa.y * (1 - c)
			};
		}

		var dec = KadoKadeoManager.I(300);
		scrollMin = Math.min(scrollMin - scrollSpeed * Timer.tmod, map._x + dec);
		scrollSpeed += KadoKadeoManager.S(0.001) * Timer.tmod;

		var ox = map._x;
		map._x = Cs.mcw * 0.5 - base.x;
		map._y = Math.min(Cs.mcw * 0.5 - base.y, 0);

		// SCROLL PLANS
		var delta = map._x - ox;
		scrollDecor(delta);

		/// RECAL
		if (Num.q(map._x) < -Cs.mcw * 2) {
			scrollMin += Cs.mcw;
			map._x += Cs.mcw;
			map._prevState.x = map._x - delta;
			for (i in 0...Sprite.spriteList.length) {
				var sp = Sprite.spriteList[i];
				sp.x -= Cs.mcw;
				if (sp.root._prevState != null) {
					sp.root._prevState.x -= Cs.mcw;
				}
			}
			// CaveTop
			recalCaveTop(Cs.mcw, delta);

			// Build Level
			if (Seed.random(Std.int(Math.pow(Num.q(dif), 0.24) * genPlatCoef)) < 40) {
				genPlatCoef = 10;
				genPlat(null, null, null);
			} else {
				genPlatCoef -= 3;
			}
		}

		auraPlasma.update();

		// CHECK PLAT
		var i = 0;
		while (i < platList.length) {
			var pl = platList[i];
			if (Num.q(pl.x + pl.w) < Num.q(-scrollMin)) {
				pl.kill();
				i--;
			}
			i++;
		}
	}

	function scrollDecor(vx:Float) {
		handicap -= vx;
		var lap = KadoKadeoManager.I(20);
		while (handicap > lap) {
			handicap -= lap;
			if (!hero.flDeath) {
				KadoKadeoManager.kkm.addScore(Cs.C10);
			}
		}

		parc -= vx;
		var i = 0;
		while (i < plans.length) {
			var p = plans[i];
			p._x += p.c * vx;
			p._y = map._y * (0.5 + p.c * 0.5);
			switch (p.type) {
				case 0:
					if (p._x > Cs.mcw) {
						var wrap = p.w * 2;
						p._x -= p.w * 2;
						if (p._prevState != null)
							p._prevState.x -= wrap;
					}
					if (p._x + p.w < 0) {
						var wrap = p.w * 2;
						p._x += p.w * 2;
						if (p._prevState != null)
							p._prevState.x += wrap;
					}
				case 1:
					p._y += p.dy;
					if (Num.q(p._x) < Num.q(-p.w * 0.5)) {
						p.removeMovieClip();
						plans.splice(i--, 1);
					}
			}
			// p._x = p.x;
			// p._y = p.y;
			i++;
		}

		// ADD SCROLL ELEMENTS
		var lim = KadoKadeoManager.I(50);
		while (plans.length < 20 && Num.q(parc) > lim) {
			parc -= lim;
			addScrollElement();
			// parc-=lim
		}

		if (FRONT_VISIBILITY_FX == 0)
			return;
		// CHECK FRONT ALPHA

		for (i in 0...plans.length) {
			var p = plans[i];
			if (p.type == 1 && p.c > 1) {
				if (p.hitTest(hero.x + map._x, hero.y + map._y, true)) {
					p._alpha += (20 - p._alpha) * 0.5;
				} else {
					p._alpha += (100 - p._alpha) * 0.5;
				}
			}
		}
	}

	function addScrollElement() {
		var mc:PlanSprite = cast dm.attach("mcScrollElement", DP_MAP);
		mc.gotoAndStop(Seed.randomVfx(mc._totalframes) + 1);
		mc.c = 0.1 + Seed.randVfx() * 1.2;
		mc._xscale = (0.3 + mc.c * 0.7) * 100;
		mc._yscale = mc._xscale;
		mc._xscale *= (Seed.randomVfx(2) * 2 - 1);
		mc.w = mc._width;
		mc._x = Cs.mcw + mc.w * 0.5;
		mc._y = 0;
		mc.dy = (1 - mc.c) * KadoKadeoManager.I(50);
		mc.type = 1;
		#if debug
		mc._alpha = 50;
		#end

		// mc._x = mc.x;

		Col.setPercentColor(mc, (1 - mc.c) * 70, 0x984e71);
		/*
			if( mc.c>1 ){
				var bc = 1-(1.3-mc.c)/0.3
				var fl = new BlurFilter();
				fl.blurX = int(bc*40);
				fl.blurY = int(bc*40);
				mc.filters = [fl];
			}
		 */

		plans.push(mc);
		orderPlans();

		// Cs.glow(mc,4,4,0xFFFFFF)
		// Cs.glow(mc,20,1,0xFFCC00)
	}

	function orderPlans() {
		var f = function(a:PlanSprite, b:PlanSprite) {
			if (a.c < b.c)
				return -1;
			return 1;
		};
		var list:Array<PlanSprite> = plans.copy();
		list.push(cast map);
		list.sort(f);
		for (i in 0...list.length)
			dm.over(cast list[i]);
	}

	function createCaveTopSegment(x:Float):ASprite {
		var seg:ASprite = cast mdm.empty(DP_DECOR);
		seg._x = x;
		printCaveTop(seg);
		return seg;
	}

	function recalCaveTop(m:Float, delta:Float) {
		var max = 0.0;
		for (seg in caveTopSegments) {
			seg._x -= m;
			if (seg._prevState != null) {
				seg._prevState.x -= m;
			}
			if (seg._x > max)
				max = seg._x;
		}

		for (i in 0...caveTopSegments.length) {
			var seg = caveTopSegments[i];
			if (seg._x + Cs.mcw <= 0) {
				seg.removeMovieClip();
				seg = createCaveTopSegment(max + Cs.mcw);
				caveTopSegments[i] = seg;
				max = seg._x;
			}
		}
	}

	function printCaveTop(seg:ASprite) {
		// BASE
		{
			var mc = seg.attachMovie("mcCaveTop", "base", 0);
			mc._x = 0;
			mc._y = 0;
		}

		// TOP ELEMENTS
		{
			for (i in 0...5) {
				var mc = seg.attachMovie("mcTopElement", "top" + i, i + 1);
				mc.gotoAndStop(Seed.random(mc._totalframes) + 1);
				var px = mc._width * 0.5 + Seed.rand() * (Cs.mcw - mc._width);
				var py = KadoKadeoManager.I(Seed.random(10));
				mc._x = px;
				mc._y = py;
			}
		}
	}

	// PLATEFORMES
	function genPlat(x, y, w) {
		if (x == null)
			x = Cs.mcw * 3 + KadoKadeoManager.I(8) + KadoKadeoManager.S(Seed.rand() * 100);
		if (y == null)
			y = KadoKadeoManager.I(140) + KadoKadeoManager.S(Seed.rand() * 150);
		if (w == null)
			w = Math.max(KadoKadeoManager.I(60), KadoKadeoManager.I(800) - Num.q(dif) * KadoKadeoManager.S(0.25)) + KadoKadeoManager.S(Seed.rand() * 200);

		var to = 0;
		while (true) {
			var flBreak = true;
			for (i in 0...platList.length) {
				var pl = platList[i];
				if (Num.q(pl.x + pl.w) > Num.q(x) && Num.q(Math.abs(y - pl.y)) < KadoKadeoManager.I(60)) {
					flBreak = false;
				}
			}
			if (flBreak)
				break;
			x = Cs.mcw * 2 + KadoKadeoManager.I(8) + KadoKadeoManager.S(Seed.rand() * 100);
			y = KadoKadeoManager.I(140) + KadoKadeoManager.S(Seed.rand() * 150);
			if (to++ > 20)
				return;
		}

		// var mc = downcast(mdm.attach("mcPlat",DP_PLAT));
		var pl = new Plat(mdm.empty(DP_PLAT));
		pl.x = x;
		pl.setPlat(x, y, w);
		pl.root.updateState();

		/// MONSTER
		// var mmax = Math.min(Math.ceil(mc.w*0.01), Math.pow(dif,0.2))
		// var max = Seed.random(int(mmax))
		var rand = Seed.random(Std.int(Math.pow(Num.q(dif), 0.2)));
		var max = Std.int(Math.min(Math.ceil((pl.w / KadoKadeoManager.I(1)) * 0.02), rand));
		if (max == 0 && Num.q(pl.w) > KadoKadeoManager.I(160))
			max++;
		var xl:Array<Float> = [];
		to = 0;

		for (i in 0...max) {
			var m = new Monster(mdm.empty(DP_MONS));
			var px = null;
			do {
				px = pl.x + Seed.rand() * pl.w;
				var flBreak = true;
				for (k in 0...xl.length) {
					if (Num.q(Math.abs(xl[k] - px)) < KadoKadeoManager.I(20)) {
						flBreak = false;
						break;
					}
				}
				if (flBreak)
					break;
				if (to++ > 200) {
					trace("MONSTER POS ERROR !!! ");
					break;
				}
			} while (true);

			if (max == 1 && platList.length == 1)
				px = pl.x + pl.w - KadoKadeoManager.I(10);

			xl.push(px);
			m.x = px;
			m.y = pl.y - m.ray;
			m.plat = pl;
			var maxId = 1;
			if (Num.q(dif) > 1000)
				maxId++;
			if (Num.q(dif) > 2800)
				maxId++;
			var id = Seed.random(Std.int(Math.min(maxId, max - i)));
			m.setSkin(id);
			max -= id;
			m.root.updateState();
		}
	}

	/*
		function setPlat(mc,x,y,w){
			mc._x = x;
			s_y = y;
			mc.w  = w;
			mc.mask._xscale = mc.w-38;
			mc.corner._x = mc.w-19;
			mc.text._x = mc.bx-mc._x
		}
	 */
	// FX
	function updateEnvFX() {
		if (Num.q(hero.y) > Cs.mch) {
			var c = (hero.y - Cs.mch) / Cs.mch;
			if (Seed.randVfx() * c > 0.2) {
				var p = newPart("partLargeLight");
				p.x = Seed.randVfx() * Cs.mcw + -map._x;
				p.y = Cs.mch + KadoKadeoManager.I(10) + KadoKadeoManager.S(Seed.randVfx() * 20) - map._y;
				p.vy = KadoKadeoManager.S(Seed.randVfx() * 6);
				p.timer = 10 + Seed.randVfx() * 10;
				p.fadeType = 0;
				p.setScale(100 + (hero.y / KadoKadeoManager.I(1)) * 0.2 + Seed.randVfx() * 100);
				p.root.blendMode = BlendModes.ADD;
			}
		}
		// MOUSEDEAD
		if (mouseDeadTimer > 0)
			mouseDeadTimer -= Timer.tmod;

		// MEDUSE PLONGE
		if (hero.flDeath) {
			scrollMin -= KadoKadeoManager.I(13);
		}
	}

	// MOUSE
	function mouseMove() {
		if (flMouseDead && mouseDeadTimer <= 0) {
			flMouseDead = false;
			untyped dm.root_mc.cursor = "default";
		}
	}

	//
	public function newPart(link):Part {
		var p:Part = cast new Part(mdm.attach(link, DP_PARTS));
		return p;
	}

	public function drawAura(mc:ASprite, col:{r:Int, g:Int, b:Int}) {
		if (auraPlasma == null)
			return;
		var ct = new ColorMatrixFilter();
		ct.matrix = [
			0, 0, 0,    0, col.r / 255,
			0, 0, 0,    0, col.g / 255,
			0, 0, 0,    0, col.b / 255,
			0, 0, 0, 0.65,           0,
		];
		mc._xscale = mc._xscale < 0 ? -120 : 120;
		mc._yscale = 120;
		auraPlasma.drawMc(mc, 0, 0, ct);
		mc._xscale = mc._xscale < 0 ? -100 : 100;
		mc._yscale = 100;
	}

	public function spawnBonus(x, y, id) {
		if (id == 0)
			return;
		if ((id >= 20 && hero.optList[id - 20]) || (id == 7 && hero.hp > 0)) {
			id = 1;
		}
		if (Num.q(dif) < 500 && Cs.game.hero.hp == 0 && Seed.random(4) == 0) {
			id = 7;
		}

		var b = new Bonus(mdm.attach("bonus" + id, DP_BONUS), id);
		b.x = x;
		b.y = y;
	}

	public function getMapMouse():PointWithGetter {
		return {
			x: Num.q(MouseManager.getX() - map._x),
			y: Num.q(MouseManager.getY() - map._y),
		};
	}

	public function genScore(x, y, sc) {
		KadoKadeoManager.kkm.addScore(sc);
		var p:Part = cast new Part(mdm.empty(DP_PARTS));
		var field = p.root.initTextField("field", {
			font: "Arial",
			size: 30,
			color: 0xFFFFFF,
			align: "center",
		});
		p.x = x;
		p.y = y;
		p.vy = KadoKadeoManager.I(-1);
		p.timer = 24;
		field.text = Std.string(KKApi.val(sc));
		Filt.glow(p.root, 4, 2, 0);
	}

	// X Bave au levre
	// X Ajustementgameplay des mosntres
	// E Glow orange sur element decor passe devant soleil;
	// X Souris rebond marche pas;
	// X Scoring sur course
	// X Option pour recup ses habits
	// fleche bas pour lacher corde
	// Double strike
	// Poses rebonds a la nba jam
	// REMI
	// ajouter option invincible + kick
}
