package zipzap;

import common_haxe_avm1.KKApi;

class Cs {
	public static var PLAN_BG:Int = 0;
	public static var PLAN_BALLON:Int = 1;
	public static var PLAN_HERO:Int = 2;
	public static var PLAN_PART:Int = 3;
	public static var PLAN_INTERF:Int = 4;

	public static var POINTS:Array<Int> = KKApi.aconst([100, 250, 500, 1000, 5000]);

	public static var LEVEL:Array<{n:Int, m:Int}> = [
		{n: 3, m: 0},
		{n: 3, m: 1},
		{n: 4, m: 1},
		{n: 4, m: 2},
		{n: 5, m: 2},
		{n: 5, m: 3},
		{n: 6, m: 3},
		{n: 7, m: 3},
		{n: 7, m: 4},
		{n: 8, m: 4},
		{n: 9, m: 4},
		{n: 9, m: 4},
		{n: 10, m: 4},
		{n: 5, m: 1},
		{n: 15, m: 0}
	];
}
