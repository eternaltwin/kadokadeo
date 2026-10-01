package elloninthedark;

class Cs {
	public static var mcw = KadoKadeoManager.I(300);
	public static var mch = KadoKadeoManager.I(300);

	public static var bact = 0;

	// GAMEPLAY
	public static var DAMAGE_FIREBALL = 1.0;
	public static var DAMAGE_SPARK = 1.0;
	public static var DAMAGE_LASER = 0.25;

	public static var DAMAGE_BOMB = 4.0;
	public static var DAMAGE_TENTACULE = 0.25;
	public static var DAMAGE_HOMING = 2.5;

	// SCORES
	public static var C1 = KKApi.const(1);
	public static var C1000 = KKApi.const(1000);
	public static var C3000 = KKApi.const(3000);
	public static var C10000 = KKApi.const(10000);
	public static var C500 = KKApi.const(500);

	public static var SCORE_GOLGOTH = KKApi.const(5000);
	public static var SCORE_FROG = KKApi.const(1500);
	public static var SCORE_DRAGON = KKApi.const(100);
	public static var SCORE_DRONE = KKApi.const(15);
	public static var SCORE_CARRIER = KKApi.const(100);
	public static var SCORE_RUNNER = KKApi.const(300);
	public static var SCORE_BACTERY = KKApi.const(400);
	public static var SCORE_MEDUSA = KKApi.const(7500);

	//
	public static var GROUND = KadoKadeoManager.I(14);
	public static var MY = KadoKadeoManager.I(40);
	public static var GL = mch + MY - GROUND;

	// GFX
	public static var SCROLL_SPEED = KadoKadeoManager.I(5);

	public static var game:Game;

	// value expressed in 1x units (speed coefficients of the original formulas)
	public static inline function u(v:Float):Float {
		return v / KadoKadeoManager.NEW_GEN_SCALE;
	}
}
