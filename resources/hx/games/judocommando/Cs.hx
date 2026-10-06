package judocommando;

class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	// SPACE
	public static var MARGIN = -1;
	public static var XMAX = 19;
	public static var YMAX = 19;
	public static var CS = 16;

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];
	public static var RAINBOW = [0xFF0000, 0xFF8800, 0xFFCC00, 0x00FF00, 0x00FFFF, 0x4444FF, 0xCC00FF, 0xFF00FF];
	public static var DIAMS = 8;

	// GAMEPLAY
	public static var SCORE_MONSTERS = KKApi.aconst([400, 600, 800, 800, 1000]);
	public static var SCORE_HIT = KKApi.const(5);
	public static var SCORE_TEC = KKApi.const(20);
	public static var SCORE_FINISH = KKApi.const(1500);
	public static var SCORE_GEM = KKApi.const(200);
	public static var SCORE_ALL_GEM = KKApi.const(6000);

	public static var DAMAGE_PILEDRIVER = 8;
	public static var DAMAGE_PILEDRIVER_SIDE = 2;
	public static var DAMAGE_HEAD_CRUSHER = 5;
	public static var DAMAGE_OSOTOGARI = 4;
	public static var DAMAGE_IPPONSEOI = 3;
	public static var DAMAGE_KATAGURUMA = 3;
	public static var DAMAGE_TOMOENAGE = 3;
	public static var DAMAGE_LIFT_KICK = 1;
	public static var DAMAGE_FIST_HEAD = 1;
	public static var DAMAGE_WALL_COLLISION = 2;
	public static var DAMAGE_WALL_PIERCE = 3;
	public static var DAMAGE_BODY_COLLISION = 1;
	public static var DAMAGE_CHANDELLE = 2;
	public static var DAMAGE_ARMLOCK = 5;

	public static var DAMAGE_BULLET = 2;
	public static var DAMAGE_SHURIKEN = 2;
	public static var DAMAGE_PUNCH = 2;
	public static var DAMAGE_JUMP_KICK = 2;
	public static var DAMAGE_SWORD = 3;
	public static var DAMAGE_FREEDOM = 1;

	public static var PROBA_PIERCE_WALL = 10;

	public static var PROBA_YAKITORI = 15;
	public static var PROBA_BURGER = 60;
	public static var PROBA_GEM = 2;

	public static inline function getX(x:Float):Float {
		return x * CS + MARGIN;
	}

	public static inline function getY(y:Float):Float {
		return y * CS + MARGIN;
	}

	public static inline function getPX(x:Float):Int {
		return Std.int((x - MARGIN) / CS);
	}

	public static inline function getPY(y:Float):Int {
		return Std.int((y - MARGIN) / CS);
	}

	// a random frame of a picture (particles, tiles of the level, twinkles): visual random
	public static function randomize(mc:MC) {
		mc.gotoAndStop(Seed.randomVfx(mc._totalframes) + 1);
	}

	public static function randomizeClip(c:Clip) {
		if (c != null)
			c.gotoAndStop(Seed.randomVfx(c.def.n) + 1);
	}

	// (the original assigns the shuffled list to its own argument: the caller's list is unchanged, only the random
	// draws are made, Mon.genJumpData; kept)
	public static function randomizeList(a:Array<Dynamic>) {
		var b = a.copy();
		a = [];
		while (b.length > 0) {
			var index = Seed.random(b.length);
			a.push(b[index]);
			b.splice(index, 1);
		}
	}

	// Math.sqrt / atan2 / cos / sin entering the game state: rounded to 1/65536 (an exact binary fraction), the last
	// bits of these functions can differ between browsers
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
