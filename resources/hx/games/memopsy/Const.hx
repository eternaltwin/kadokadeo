package memopsy;

class Const {
	public static var NUMCARDS = 10;
	public static var MAXLIFE = 20;
	public static var STARTLIFE = 10;

	public static var LEVELS = [
		{width: 4, height: 2},
		{width: 4, height: 3},
		{width: 4, height: 4},
		{width: 5, height: 4},
		{width: 5, height: 4},
		{width: 5, height: 4},
		{width: 6, height: 4},
	];

	// static var inc = 0; PLAN_* = inc++ in the original
	public static var PLAN_BG = 0;
	public static var PLAN_FX = 1;
	public static var PLAN_CARD = 2;
	public static var PLAN_LIFE = 3;

	public static var POINTS = KKApi.aconst([1000, 500, 400, 300, 300, 200, 200, 200, 100]);
}
