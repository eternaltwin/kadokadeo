package kanji;

import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;
import common_haxe_avm1.KeyboardManager;
import haxe.io.UInt16Array;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;

class FeatherMain extends ASprite {
	public var timer:Int;

	public var fList:Array<FeatherSprite> = [];
}

class FeatherSprite extends ASprite {
	public var t:Int;
}

@:expose('GameKanji')
class Game implements kado.GameInterface {
	public var root:ASprite;
	public var hero:Hero;

	var death:ASprite;
	var game_over:Bool;

	public var dmanager:DepthManager;
	public var entities:Array<ASprite>;

	var bonuses:Array<Bonus>;
	var jamas:Array<Jama>;
	var bonusProbas:Array<Int>;
	var nb:Int;

	public var level:Int;

	var dbg:ASprite;
	var avg_tmod:Float;
	var death_y:Float;

	var stats:{
		t:Int,
		l:Int,
		n:Int,
		b:Array<Int>,
		m:Array<Int>
	};

	public var feathers:Array<FeatherMain>;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(5);
		replayKeys[0] = KeyboardManager.LEFT;
		replayKeys[1] = KeyboardManager.RIGHT;
		replayKeys[2] = KeyboardManager.UP;
		replayKeys[3] = KeyboardManager.DOWN;
		replayKeys[4] = KeyboardManager.SPACE;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		this.root = root;
		nb = 0;
		level = 0;
		avg_tmod = 0;

		bonusProbas = Cs.BONUS_PROBAS_TBL.copy();
		if (Seed.random(1000) == 0) {
			bonusProbas[2] = 3;
		}

		stats = {
			t: 0,
			l: 0,
			n: 0,
			b: [0, 0, 0],
			m: [0, 0, 0]
		};
		dmanager = new DepthManager(root);
		dmanager.attach("bg", 0);
		dbg = dmanager.empty(30);
		hero = new Hero(this);
		jamas = [];
		entities = [];
		bonuses = [];
		entities.push(hero.mc);
		feathers = [];
	}

	function genPlace(r:Int, bx:Null<Float>):Null<{x:Float, y:Float}> {
		var x:Float = bx == null ? 0 : bx;
		var y:Float = 0;
		var ntrys = 50;
		var l = entities.length;
		var r2 = r * r;
		while (ntrys-- > 0) {
			if (bx == null) {
				x = Seed.random(300 * Cs.NEW_GEN_SCALE - r * 2) + r;
			}
			y = Seed.random(Cs.MAXY - r * 2) + r;
			var hit = false;
			for (i in 0...l) {
				var b = entities[i];
				var dx = Num.q(b._x - x);
				var dy = Num.q(b._y - y);
				if (dx * dx + dy * dy < r2) {
					hit = true;
					break;
				}
			}
			if (!hit) {
				return {x: x, y: y};
			}
		}
		return null;
	}

	public function updateFeathers() {
		var i = 0;
		while (i < feathers.length) {
			var f = feathers[i];
			if (f == null) {
				i++;
				continue;
			}
			f.update();

			var j = 0;
			while (j < f.fList.length) {
				var mc = f.fList[j];
				if (mc == null) {
					j++;
					continue;
				}
				mc.update();
				mc.t--;
				if (mc.t < 10) {
					mc._alpha = 10 * mc.t;
				}
				var c = (mc._currentframe * 2 - mc._totalframes) / mc._totalframes;
				mc._y += (0.5 + Math.abs(c) * 1) * Cs.NEW_GEN_SCALE;
				if (mc.t == 0) {
					mc.removeMovieClip();
					f.fList.splice(j--, 1);
				}
				j++;
			}

			if (f.timer-- < 0) {
				f.removeMovieClip();
				feathers.splice(i--, 1);
			}
			i++;
		}
	}

	public function kill():Void {
		if (game_over) {
			return;
		}
		game_over = true;
		hero.mc.removeMovieClip();
		death = dmanager.attach("death", Cs.PLAN_HERO);
		death.play();
		death.removeOnFrame = 16;
		death._x = hero.x;
		death._y = hero.y - 15 * Cs.NEW_GEN_SCALE;

		death = dmanager.attach("fall", Cs.PLAN_HERO);
		death.play();
		death.loop = true;
		death_y = -5 * Cs.NEW_GEN_SCALE;
		death._x = hero.x;
		death._y = hero.y;
		hero.jump_dx = (hero.x < 150 * Cs.NEW_GEN_SCALE) ? Cs.NEW_GEN_SCALE : -Cs.NEW_GEN_SCALE;
	}

	function genBonus():Void {
		var p = genPlace(5 * Cs.NEW_GEN_SCALE + Std.int(Math.sqrt(Cs.BONUS_RAY2)), null);
		if (p == null) {
			return;
		}
		var t = randomProbas(bonusProbas);
		var b = new Bonus(this, p, t);
		bonuses.push(b);
	}

	public function getBonus(b:Bonus):Void {
		KadoKadeoManager.kkm.addScore(Cs.BONUS_POINTS[b.t]);
		nb++;
		stats.n++;
		stats.b[b.t]++;
		if (nb % Cs.LEVEL_DELTA == 0) {
			level++;
		}
	}

	function genJama():Void {
		var w = Seed.random(2) == 0;
		var p = genPlace(40 * Cs.NEW_GEN_SCALE, w ? 320 * Cs.NEW_GEN_SCALE : -20 * Cs.NEW_GEN_SCALE);
		if (p == null) {
			return;
		}
		var t = randomProbas(Cs.JAMA_PROBAS_TBL.slice(0, level + 1));
		var j = new Jama(this, p, t);
		stats.m[t]++;
		jamas.push(j);
	}

	public function drawBox(b, x:Float, y:Float, color = 0xFF00FF):Void {
		dbg.moveTo(Std.int(b.xMin + x), Std.int(b.yMin + y));
		dbg.lineStyle(4, color, 100);
		dbg.lineTo(Std.int(b.xMax + x), Std.int(b.yMin + y));
		dbg.lineTo(Std.int(b.xMax + x), Std.int(b.yMax + y));
		dbg.lineTo(Std.int(b.xMin + x), Std.int(b.yMax + y));
		dbg.lineTo(Std.int(b.xMin + x), Std.int(b.yMin + y));
	}

	function randomProbas(probas:Array<Int>):Int {
		var total = 0;
		for (v in probas) {
			total += v;
		}
		if (total <= 0) {
			return 0;
		}
		var rnd = Seed.random(total);
		for (i in 0...probas.length) {
			rnd -= probas[i];
			if (rnd < 0) {
				return i;
			}
		}
		return probas.length - 1;
	}

	inline function getCheat<T>(arr:Array<T>):Bool {
		return false;
	}

	public function update(delta:Float):Void {
		avg_tmod = avg_tmod * 0.99 + Timer.calc_tmod * 0.01;

		dbg.clear();

		#if debug
		if (KeyboardManager.isDown(KeyboardManager.D)) {
			Cs.DEBUG = !Cs.DEBUG;
		}
		#end

		if (game_over) {
			death._x += hero.jump_dx * Timer.tmod;
			death._y += death_y * Timer.tmod;
			death_y += Timer.tmod * Cs.NEW_GEN_SCALE;
			if (death._y > 330 * Cs.NEW_GEN_SCALE) {
				stats.l = level;
				stats.t = Std.int(avg_tmod * 100);
				KadoKadeoManager.kkm.gameOver(stats);
				game_over = false;
			}
		} else {
			hero.update();
		}

		if (bonuses.length < 3 && Seed.random(Std.int(Cs.BONUS_PROBAS * bonuses.length / Timer.tmod)) == 0) {
			genBonus();
		}

		var l = level;
		if (l >= Cs.JAMA_PROBAS.length) {
			l = Cs.JAMA_PROBAS.length - 1;
		}
		if (jamas.length < 10 && Seed.random(Std.int(Cs.JAMA_PROBAS[l] * jamas.length / Timer.tmod)) == 0) {
			genJama();
		}

		var i = 0;
		while (i < bonuses.length) {
			if (!bonuses[i].update()) {
				bonuses.splice(i--, 1);
			}
			i++;
		}

		i = 0;
		while (i < jamas.length) {
			if (!jamas[i].update()) {
				jamas.splice(i--, 1);
			}
			i++;
		}

		updateFeathers();

		hero.mc._xscale = hero.way * 100;
		hero.mc._prevState.xscale = hero.mc._curState.xscale;

		if (getCheat(entities) || getCheat(bonuses) || getCheat(jamas)) {
			KKApi.flagCheater();
		}
	}

	public function destroy():Void {}
}
