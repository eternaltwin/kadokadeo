package alphabounce;

import mt.bumdum.Sprite;

class Cs {
	public static var BW = 28;
	public static var BH = 12;

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];
	public static var XMAX:Int;
	public static var YMAX:Int;
	public static var SIDE:Float;

	public static var mcw = 300;
	public static var mch = 300;

	public static var SCORE_BONUS = [250, 1000, 5000];
	public static var SCORE_BLOCK = 50;
	public static var SCORE_BOUNCE = 5;
	public static var SCORE_ICE = 120;
	public static var SCORE_0 = 0;

	public static var MAX_BALL = 32;
	public static var MAX_OPTION = 6;

	public static inline var BALL_STANDARD = 0;
	public static inline var BALL_FIRE = 1;
	public static inline var BALL_ICE = 2;
	public static inline var BALL_DRUNK = 3;
	public static inline var BALL_KAMIKAZE = 4;
	public static inline var BALL_YOYO = 5;
	public static inline var BALL_HALO = 6;
	public static inline var BALL_SHADE = 7;

	public static inline var PAD_STANDARD = 0;
	public static inline var PAD_GLUE = 1;
	public static inline var PAD_TIME = 2;
	public static inline var PAD_LASER = 3;
	public static inline var PAD_PROTECTION = 4;
	public static inline var PAD_AIMANT = 5;
	public static inline var PAD_SHAKE = 6;

	// GAMEPLAY
	public static var TEMPO = 100;
	public static var DOOR_COEF = 0.25;
	public static var OPTION_COEF = 0.2;

	// GFX
	public static var PQ = 0.3;
	public static var SKIN = [
		{back: 0x888888, br: 55, rr: 200, bg: 55, rg: 200, bb: 55, rb: 200},
		{back: 0xAAAA22, br: 90, rr: 140, bg: 155, rg: 100, bb: 0, rb: 50}
	];

	// TOOLS
	public static function init() {
		XMAX = Std.int((mcw - 10) / BW);
		YMAX = Std.int((mch - 30) / BH);
		SIDE = (mcw - XMAX * BW) * 0.5;
	}

	public static function getX(px:Float) {
		return SIDE + px * BW;
	}

	public static function getY(py:Float) {
		return py * BH;
	}

	public static function getPX(x:Float) {
		return Std.int((x - SIDE) / BW);
	}

	public static function getPY(y:Float) {
		return Std.int(y / BW);
	}

	public static function getPerfCoef() {
		return Math.max(0, 1 - (Sprite.spriteList.length / 120));
	}

	// Col.setColor(mc, col) of the original on a grey `level` of the picture: (colour - 255) added to each channel
	public static function offCol(col:Int, level:Int):Int {
		var d = level - 255;
		var r = Std.int(Math.max(0, Math.min(255, ((col >> 16) & 255) + d)));
		var g = Std.int(Math.max(0, Math.min(255, ((col >> 8) & 255) + d)));
		var b = Std.int(Math.max(0, Math.min(255, (col & 255) + d)));
		return (r << 16) | (g << 8) | b;
	}

	// trigonometry of the gameplay rounded to 1e-9: the same on every browser (replays)
	public static inline function qt(v:Float):Float {
		return Math.round(v * 1e9) / 1e9;
	}

	public static inline function cos(a:Float):Float {
		return qt(Math.cos(a));
	}

	public static inline function sin(a:Float):Float {
		return qt(Math.sin(a));
	}

	public static inline function atan2(y:Float, x:Float):Float {
		return qt(Math.atan2(y, x));
	}

	public static inline function pow(a:Float, b:Float):Float {
		return qt(Math.pow(a, b));
	}
}
