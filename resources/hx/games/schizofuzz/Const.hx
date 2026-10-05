package schizofuzz;

// Const.hx of the original
class Const {
	public static inline var PLAN_BG = 0;
	public static inline var PLAN_ITEM = 1;
	public static inline var PLAN_HERO = 2;
	public static inline var PLAN_ITEM_FRONT = 3;
	public static inline var PLAN_FX = 4;
	public static inline var PLAN_ARROW = 5;
	public static inline var PLAN_FRONT = 6;

	// (PROBAS[3], the stump, grows during a game: the SWF was reloaded for every game, reset by Game)
	public static var PROBAS:Array<Int>;
	public static var POINTS:Array<KKConst>;

	public static function reset() {
		PROBAS = [50, 50, 50, 5, 20, 10];
		POINTS = KKApi.aconst([0, 0, 0, 0, 0, 20000]);
	}
}
