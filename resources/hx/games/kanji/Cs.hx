package kanji;

import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;

class Cs {
	public static var DEBUG = false;

	public static var PLAN_BONUS = 3;
	public static var PLAN_HERO = 4;
	public static var PLAN_JAMA = 5;

	public static var MINX = KadoKadeoManager.I(15);
	public static var MAXX = KadoKadeoManager.I(285);
	public static var MAXY = KadoKadeoManager.I(280);

	public static var BONUS_PROBAS = 100;
	public static var BONUS_PROBAS_TBL = [50, 10, 1];
	public static var JAMA_PROBAS_TBL = [100, 40, 10];
	public static var BONUS_POINTS = KKApi.aconst([200, 500, 3000]);

	public static var BONUS_RAY2 = KadoKadeoManager.I(KadoKadeoManager.I(600));

	public static var LEVEL_DELTA = 15;
	public static var JAMA_PROBAS = [50, 35, 20, 10, 5, 4, 4, 3, 3, 2, 1];
}
