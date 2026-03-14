package kanji_gaiden;

import mt.flash.Key;
import mt.bumdum.Lib;
import common_haxe_avm1.KKApi;

typedef Point = {x:Int, y:Int};

class AnonSprite2 extends ASprite {
	public var _field:Text;
}

class AnonSprite696460 extends ASprite {
	public var mct:AnonSprite2;
	public var _field:Text;
}

@:expose('GameKanjiGaiden')
class Game implements kado.GameInterface {
	public var kkm:kado.KadoKadeoManager;

	public static var DP_BONUS = 17;
	public static var DP_WARN = 16;
	public static var DP_SC = 15;

	public static var DP_HERO = 14;

	public static var DP_FG = 13;
	public static var DP_DEATH = 12;
	public static var DP_SHOOT = 11;
	public static var DP_PL1 = 10;
	public static var DP_BB1 = 9;
	public static var DP_PL2 = 8;
	public static var DP_BB2 = 7;
	public static var DP_PL3 = 6;
	public static var DP_BB3 = 5;
	public static var DP_PL4 = 4;
	public static var DP_BB4 = 3;
	public static var DP_BG = 1;

	public static var me:Game;

	public var dm:mt.DepthManager;
	public var root:ASprite;
	public var bg:ASprite;
	public var warn_l:ASprite;
	public var warn_r:ASprite;
	public var hero:Kanji;

	var fg:Plan;

	public var plans:Array<Plan>;
	public var shoots:Array<Shot>;
	public var monkeys:Array<Monkey>;
	public var bonus:Array<Bonus>;

	public var pos:Float;

	var monkeyMin:Int;
	var diffCool:Float;

	public var diff:Int;

	var dead:Bool;
	var warnl:Bool;
	var warnr:Bool;

	public var mcScore:AnonSprite696460;

	public function new(kkm:kado.KadoKadeoManager, root:ASprite) {
		this.kkm = kkm;
		ASprite.spriteData = [
			"kanji_gaiden/bamboo" => [75, 448],
			"kanji_gaiden/banana" => [117, 103],
			"kanji_gaiden/bonus" => [339, 153],
			"kanji_gaiden/bottom" => [144, 152],
			"kanji_gaiden/bounce" => [222, 113],
			"kanji_gaiden/feuilles" => [319, 107],
			"kanji_gaiden/fg" => [458, 347],
			"kanji_gaiden/herbes" => [398, 102],
			"kanji_gaiden/hero" => [309, 220],
			"kanji_gaiden/hero_wait" => [524, 373],
			"kanji_gaiden/kunai" => [84, 60],
			"kanji_gaiden/mcBg" => [921, 301],
			"kanji_gaiden/monkey_1" => [350, 251],
			"kanji_gaiden/monkey_2" => [350, 251],
			"kanji_gaiden/monkey_3" => [349, 251],
			"kanji_gaiden/part" => [23, 36],
			"kanji_gaiden/score" => [195, 359],
			"kanji_gaiden/warning" => [85, 29],
			"kanji_gaiden/taupe" => [566, 391],
			"kanji_gaiden/bamboo_bottom" => [143, 151],
			"kanji_gaiden/kunai_bounce" => [192, 42],
		];

		dm = new mt.DepthManager(root);
		me = this;

		diffCool = Cs.DIFFBASE;
		monkeyMin = 4;
		diff = 0;
		pos = 0.5;

		shoots = [];
		monkeys = [];
		bonus = [];

		warnr = false;
		warnl = false;
		dead = false;

		Key.init();

		warn_l = dm.attach("kanji_gaiden/warning", DP_WARN);
		warn_l.anchor.set(0.5, 0.5);
		warn_l.loop = true;
		warn_l.play();
		warn_r = dm.attach("kanji_gaiden/warning", DP_WARN);
		warn_r.anchor.set(0.5, 0.5);
		warn_r.loop = true;
		warn_r.play();
		warn_l._x = warn_l._width * 0.5 + 5;
		warn_l._y = warn_l._height * 0.5 + 5;

		spriteList.push(warn_l);
		spriteList.push(warn_r);

		warn_r._xscale = -100;
		warn_r._x = Cs.mcw - warn_r._width * 0.5 - 5;
		warn_r._y = warn_r._height * 0.5 + 5;
		warn_l._visible = false;
		warn_r._visible = false;
	}

	public function start() {
		hero = new Kanji();
		initPlan();
	}

	public function stop() {
		//
	}

	public function getPos(dev:Float):Point {
		var ret:Point;
		var width = Math.ceil((300 + 600 * (1 - dev)));
		var px = Math.floor(pos * (width - 300));
		var py = Math.floor(Cs.pdf * dev);
		ret = {x: px, y: py};
		return ret;
	}

	public function getPosShot(dev:Float, hint:Float):Point {
		var ret:Point;
		var width = Math.ceil((300 + 600 * (1 - dev)));
		var px = Math.floor(hint * (width - 300) - pos * (width - 300) + Cs.mcw * 0.5);
		var py = Math.floor(Cs.pdf * dev);
		ret = {x: px, y: py};
		return ret;
	}

	function checkWarn() {
		warnr = false;
		warnl = false;
		for (m in monkeys) {
			if ((m.pl == 0)) {
				if (m.mcMonkey._x < (plans[0].width * pos) - 200)
					warnl = true;
				if (m.mcMonkey._x > (plans[0].width * pos) + 200)
					warnr = true;
			}
		}
	}

	function updateBg() {
		var pos = getPos(0);
		bg._x = -pos.x + bg._width * 0.5;
	}

	function addMonkeyDebug() {
		plans[2].addMonkey();
	}

	public function addAMonkey(pl:Int) {
		if (pl >= 0) {
			plans[pl].addMonkey();
		} else {
			if (!dead) {
				dead = true;
				KKApi.gameOver({});
				var monkeyDeath = dm.attach("kanji_gaiden/monkey", DP_DEATH);
				monkeyDeath.smc.gotoAndPlay("_land");

				monkeyDeath._x = 150;
				monkeyDeath._y = 270;
			}
		}
	}

	public function addAMonkeySpecial(pl:Int, mtype:Int, life:Int, diff:Int, btype:Int) {
		if (pl >= 0) {
			plans[pl].addMonkeyTyped(mtype, life, diff, btype);
		} else {
			if (!dead) {
				dead = true;
				KKApi.gameOver({});
				var monkeyDeath = dm.empty(DP_DEATH);
				Monkey.createMonkeyMC(monkeyDeath, diff);
				monkeyDeath.smc.play();

				if (mtype != 4)
					monkeyDeath.smc.smc.gotoAndStop(mtype + 1);
				else
					monkeyDeath.smc.smc.gotoAndStop(5 + btype);

				monkeyDeath._x = 150;
				monkeyDeath._y = 270;
				spriteList.push(monkeyDeath);
			}
		}
	}

	function initPlan() {
		plans = [];

		var mcfg = dm.attach("kanji_gaiden/fg", DP_FG);
		fg = new Plan(mcfg, 0, 0.75, 1);

		var mcBamboo1 = dm.empty(DP_BB1);
		var Bamboo1 = new Plan(mcBamboo1, 0, 0.5, 0);
		plans.push(Bamboo1);

		var mcBamboo2 = dm.empty(DP_BB2);
		var Bamboo2 = new Plan(mcBamboo2, 1, 0.25, 0);
		plans.push(Bamboo2);
		Col.setPercentColor(mcBamboo2, 25, 0xD4FBA2);

		var mcBamboo3 = dm.empty(DP_BB3);
		var Bamboo3 = new Plan(mcBamboo3, 2, 0.125, 0);
		plans.push(Bamboo3);
		Col.setPercentColor(mcBamboo3, 50, 0xD4FBA2);

		bg = dm.attach("kanji_gaiden/mcBg", DP_BG);
		var bgPlan = new Plan(bg, 3, 0, 1);

		plans.push(bgPlan);

		addMonkeyDebug();
	}

	static public var spriteList:Array<ASprite> = [];

	public function update(f:Float) {
		for (i in spriteList) {
			i.update();
		}

		hero.update();
		if (!dead) {
			if (Key.isDown(mt.flash.Key.ARROW_RIGHT))
				move(0);
			else if (mt.flash.Key.isDown(mt.flash.Key.ARROW_LEFT))
				move(1);

			// if( mt.flash.Key.isDown(mt.flash.Key.UP) ) trace("[ FPS ] : "+mt.Timer.fps()) ;

			if (mt.flash.Key.isDown(mt.flash.Key.SPACE))
				hero.shoot();
		}
		for (pl in plans)
			pl.update();
		for (s in shoots)
			s.update();
		for (m in monkeys)
			m.update();
		for (b in bonus)
			b.update();
		fg.update();
		if (monkeys.length < monkeyMin)
			addMonkeyDebug();

		incDifficulty();
		checkWarn();

		if (warnr)
			warn_r._visible = true;
		else
			warn_r._visible = false;
		if (warnl)
			warn_l._visible = true;
		else
			warn_l._visible = false;
	}

	public function move(dir:Int) {
		hero.move(dir);
	}

	public function scoreIt(sc:Int) {
		trace('Add score $sc');
		mcScore = cast dm.attach("kanji_gaiden/score", DP_SC);
		// mcScore.mct._field.text = "" + KKApi.val(sc);
		mcScore._x = 300;
		mcScore._y = 300;
		KKApi.addScore(sc);
	}

	function incDifficulty() {
		if (diffCool < 0) {
			diff++;
			monkeyMin++;
			// trace(" Diff "+diff+"  monkey min:"+monkeyMin);
			diffCool = Cs.DIFFBASE + Std.random(Cs.DIFFBASE);
		} else {
			diffCool -= mt.Timer.tmod;
		}
	}

	public function bonusMe(bt:Int) {
		if (bonus.length == 0) {
			var b = new Bonus(bt);
			bonus.push(b);
		} else {
			bonus[0].destroy();
			var b = new Bonus(bt);
			bonus.push(b);
		}
	}
}
