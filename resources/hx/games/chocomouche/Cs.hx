package chocomouche;

import mt.bumdum.Sprite;

class Cs {
	// GAME SIZE
	public static var mcw = 900;
	public static var mch = 900;

	// BOARD
	static public var GRID_WIDTH = 8;
	static public var GRID_HEIGHT = 9;

	static public var SLOT_SIZE = 90;

	/*public static var GRID_X = 43.5 ;
		public static var GRID_Y = 35 ; */
	public static var GRID_X = 138;
	public static var GRID_Y = 81;

	public static var GRID_ALPHA = 0;

	public static var TIME_X = 330;
	public static var TIME_Y = 861;

	public static var LIFE_X = 18;
	public static var LIFE_Y = GRID_Y + GRID_HEIGHT * SLOT_SIZE - 108;

	public static var bombs = [10, 10, 11, 11, 12, 12, 12, 13, 13, 13, 15];

	public static var INITIAL_TIME = 26000.0;

	public static function getLevelTime(level):Float {
		return Math.max(INITIAL_TIME - level * 4000.0, 3000.0);
	}

	public static function getLevelBombs(level):Int {
		var b = bombs[level];
		return if (b == null) 15 else b;
	}

	// POINTS
	public static var LEVEL_BONUS = common_haxe_avm1.KKApi.const(20000);
	public static var POINTS = 1000;
	public static var MULT_LEVEL = 5;
}
