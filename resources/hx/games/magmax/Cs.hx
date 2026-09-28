package magmax;

import common_haxe_avm1.KKApi;

class Cs {
	public static var PLAN_BG = 0;
	public static var PLAN_HERO = 1;
	public static var PLAN_MONSTER = 1;
	public static var PLAN_TIR = 1;
	public static var PLAN_PART = 1;
	public static var PLAN_BONUS = 1;

	public static var BONUS = [500, 100, 10, 30, 3];
	public static var BONUS_POINTS = KKApi.aconst([200, 500, 3000]);
	public static var MONSTER_POINTS = KKApi.aconst([10, 30, 50]);
	public static var COMBOS = KKApi.aconst([100, 200, 300, 400]);

	public static function randomProbas(probas:Array<Int>):Int {
		var total = 0;
		for (value in probas)
			total += value;
		var random = Seed.random(total);
		for (i in 0...probas.length) {
			random -= probas[i];
			if (random < 0)
				return i;
		}
		return 0;
	}
}
