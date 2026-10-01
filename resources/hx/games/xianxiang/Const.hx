package xianxiang;

import common_haxe_avm1.KKApi;

class Const {
	public static var LVL_WIDTH = 6;
	public static var LVL_HEIGHT = 7;

	public static var BASE_X = KadoKadeoManager.I(23);
	public static var BASE_Y = KadoKadeoManager.I(20);
	public static var CARD_WIDTH = KadoKadeoManager.I(43);
	public static var CARD_HEIGHT = KadoKadeoManager.I(34);

	// Button area of the "card" clip (40x45 socle bitmap)
	public static var CARD_HIT_WIDTH = KadoKadeoManager.I(40);
	public static var CARD_HIT_HEIGHT = KadoKadeoManager.I(45);

	// "match" clip position relative to the card
	public static var MATCH_X = KadoKadeoManager.I(17);
	public static var MATCH_Y = KadoKadeoManager.I(10);

	public static var auto = 0;
	public static var PLAN_BG = auto++;
	public static var PLAN_CARD = auto++;
	public static var PLAN_PATH = auto++;
	public static var PLAN_MATCH = auto++;
	public static var PLAN_FX = auto++;

	public static var NTURNS = 1;

	public static var POINTS_ENCODE = KKApi.aconst([1, 50, 300, 1000]);

	// socle frames 1..3, each one has its own "color" clip
	public static var SOCLE_NAMES = ['circle', 'triangle', 'square'];

	// "match" clip timeline (16 frames then stop()): scale and alpha of its "sub" digit
	public static var MATCH_SCALE = [
		0.1, 0.216, 0.324, 0.424, 0.516, 0.6, 0.676, 0.744, 0.804, 0.856, 0.9, 0.936, 0.964, 0.984, 0.996, 1
	];
	public static var MATCH_ALPHA = [
		0, 0.129, 0.25, 0.359, 0.461, 0.555, 0.641, 0.715, 0.781, 0.84, 0.891, 0.93, 0.961, 0.98, 0.996, 1
	];

	// "explosion" clip: stop(); this.removeMovieClip(); on its last frame
	public static var EXPLOSION_END_FRAME = 11;
}
