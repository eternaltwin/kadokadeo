package kanjigaiden;

// Cs.hx of the original
class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var PW = 900;

	public static var pdf = 150;

	public static var AMMO = 20;

	public static var DEV = 0.020;
	public static var SHURIKEN = 0.25;
	public static var SHURIKEN2 = 0.35;

	public static var sCool = 10;
	public static var sCool2 = 7;

	public static var bLife = 250;

	public static var mCool = 50;
	public static var MSPEED = 7;

	public static var DIFFBASE = 500;

	public static var SPHERATIO = 15;
	public static var SPHERANGLE = 6;

	public static var PTS:Array<KKConst> = [KKApi.const(50), KKApi.const(150), KKApi.const(350)];
	public static var BONUS:Array<KKConst> = [KKApi.const(0), KKApi.const(500), KKApi.const(1500), KKApi.const(3500)];

	// port: a power whose result enters the game state, rounded to 1/65536 (Math.pow may differ in the last bits
	// between browsers; the replays must not)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
