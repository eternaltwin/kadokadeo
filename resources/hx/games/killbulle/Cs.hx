package killbulle;

import common_haxe_avm1.KKApi;

class Cs {
	public static var NEW_GEN_SCALE = 3;

	public static var PLAN_CORDE = 2;
	public static var PLAN_GRAPIN = 4;
	public static var PLAN_BONUS = 4;

	public static var PLAN_HERO = 3;
	public static var PLAN_BLOB = 4;

	public static var WIDTH = 450 * NEW_GEN_SCALE;

	public static var BLOB_PROBAS = 3000;
	public static var MINY = 290 * NEW_GEN_SCALE;

	public static var C20 = KKApi.const(20);
	public static var C5000 = KKApi.const(5000);

	public static var BONUS_START_LEVEL = 10;

	public static var BONUS_PROBAS = [
		500, // nobonus
		100, // time
		10, // grapin
		30, // shuriken
		50 // points
	];
}
