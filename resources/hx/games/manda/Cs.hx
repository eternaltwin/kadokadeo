package manda;

// Const of the original
class Cs {
	// GFX
	public static inline var WIDTH = 300;
	public static inline var HEIGHT = 300;

	public static inline var COLOR_SNAKE_DEFAULT = 0x009900;
	public static inline var COLOR_SNAKE_BORDER_DEFAULT = 0x006C00;
	public static inline var COLOR_SNAKE_INVINCIBLE = 0x89A6B5;
	public static inline var COLOR_SNAKE_BORDER_INVINCIBLE = 0x61869A;
	public static inline var COLOR_SNAKE_SHADE = 0xB7EF7C;

	public static inline var PLAN_FRUITS_SHADE = 1;
	public static inline var PLAN_SNAKE = 2;
	public static inline var PLAN_FRUITS = 3;
	public static inline var PLAN_PARTICULES = 4;
	public static inline var PLAN_POPSCORE = 5;
	public static inline var PLAN_JACKPOT = 1;

	// PHYSICS
	public static inline var SNAKE_DEFAULT_SPEED = 2.3;
	public static inline var SNAKE_MIN_SPEED = SNAKE_DEFAULT_SPEED / 2;
	public static inline var SNAKE_FAST_SPEED_COEF = 3;
	public static inline var SNAKE_DEFAULT_TURN = 0.125;
	public static inline var SNAKE_DEFAULT_LENGTH = 3;
	public static inline var SNAKE_QUEUE_ELT_SIZE = 4;
	public static inline var SNAKE_SPEED_INCREMENT = 0.001;

	public static inline var FRICTION = 0.97;

	// GAMEPLAY
	public static var BONUS_PROBAS = [
		100, // CISEAUX
		40, // COFFRE
		30, // POTION BLEUE
		8, // CANNE
		80, // MOLECULE
		20, // PLUME
		2, // CLOCHE
		500, // JACKPOT
	];

	public static inline var BONUS_FREQ = 250;
	public static inline var BONUS_MAX = 7;

	public static inline var FRUITS_FREQ = 350;
	public static inline var FRUITS_MAX = 200;

	public static inline var FBARRE_MAX = 150;
	public static inline var FBARRE_FRUIT_BASE = 20;
	public static inline var FBARRE_FRUIT_TIMEOUT = -1.5;
	public static inline var FBARRE_FRUIT_EAT = 2;

	public static inline var C5 = 5;
	public static inline var C10 = 10;
	public static inline var C20 = 20;
	public static inline var C30 = 30;
	public static inline var C50 = 50;
	public static inline var C100 = 100;
	public static inline var C200 = 200;
	public static inline var C700 = 700;
	public static inline var C1900 = 1900;
	public static inline var C3000 = 3000;
	public static inline var C4000 = 4000;
	public static inline var C6000 = 6000;

	public static var LEVEL_BOUNDS = {
		left: 3.0,
		top: 3.0,
		right: 297.0,
		bottom: 267.0
	};

	// results of Math.cos / sin / pow used by the gameplay, rounded to 1e-9: the replays stay identical on every
	// browser even if their Math functions differ in the last bits (the rest is exact IEEE arithmetic)
	public static inline function qt(v:Float):Float {
		return Math.round(v * 1e9) / 1e9;
	}

	// Tools.randomProbas of the original
	public static function randomProbas(probas:Array<Int>):Int {
		var total = 0;
		for (v in probas)
			total += v;
		var rnd = Seed.random(total);
		for (i in 0...probas.length) {
			rnd -= probas[i];
			if (rnd < 0)
				return i;
		}
		return probas.length - 1;
	}
}
