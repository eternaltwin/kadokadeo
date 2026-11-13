package travoltax;

import kado.Seed;
import common_haxe_avm1.KKApi;

enum Step {
	Play;
	Fall;
	Freeze;
	GameOver;
}

class Cs {
	public static var mcw = KadoKadeoManager.I(300);
	public static var mch = KadoKadeoManager.I(300);

	public static var MX = 0.0;
	public static var MY = 0.0;
	public static var XMAX = 10;
	public static var YMAX = 22;
	public static var SIZE = KadoKadeoManager.I(16);
	public static var CONTRAT_MAX = 18;

	public static var COL_NEUTRAL = 0x98ABD4;

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];

	public static var SCORE_BREAK = KKApi.const(15);
	public static var SCORE_LINES = KKApi.aconst([500, 1000, 2000, 4000]);
	public static var SCORE_BONUS = KKApi.aconst([1000, 5000, 12000]);

	public static var SCORE_CONTRAT_BASE = KKApi.const(1000);
	public static var SCORE_CONTRAT_INC = KKApi.const(500);

	public static var SCORE_LINES_BASE = KKApi.const(500);
	public static var SCORE_LINES_INC = KKApi.const(250);

	public static function getContratScore(id) {
		return KKApi.cadd(Cs.SCORE_CONTRAT_BASE, KKApi.cmult(Cs.SCORE_CONTRAT_INC, KKApi.const(id)));
	}

	public static function getLineScore(id) {
		var scoreLine = KKApi.cadd(Cs.SCORE_LINES_BASE, KKApi.cmult(Cs.SCORE_LINES_INC, KKApi.const(id - 1)));
		return KKApi.cmult(scoreLine, KKApi.const(id));
	}

	public static var PROBA_OPTION = 60;
	public static var PROBA_GREEN = 60;
	public static var PROBA_BLUE = 250;
	public static var PROBA_PINK = 2000;

	public static var PIECES = [
		[
			[
				0, 0, 1, 0,
				0, 0, 1, 0,
				0, 0, 1, 0,
				0, 0, 1, 0
			],
			[4, 4]
		],
		[
			[
				0, 0, 0, 0,
				0, 1, 1, 0,
				0, 1, 1, 0,
				0, 0, 0, 0
			],
			[3, 3]
		],
		[
			[
				0, 1, 0, 0,
				0, 1, 0, 0,
				0, 1, 1, 0,
				0, 0, 0, 0
			],
			[2, 2]
		],
		[
			[
				0, 0, 0, 0,
				0, 0, 1, 0,
				0, 1, 1, 0,
				0, 1, 0, 0
			],
			[4, 4]
		],
		[
			[
				0, 0, 0, 0,
				0, 0, 1, 0,
				0, 1, 1, 0,
				0, 0, 1, 0
			],
			[4, 4]
		],
		[
			[
				0, 0, 0, 0,
				0, 1, 0, 0,
				0, 1, 1, 0,
				0, 0, 1, 0
			],
			[4, 4]
		],
		[
			[
				0, 0, 1, 0,
				0, 0, 1, 0,
				0, 1, 1, 0,
				0, 0, 0, 0
			],
			[2, 4]
		]
	];

	// the names of the options: Lang, option_<id>
	public static var OPTION_INFOS = [
		{weight: 50}, // 0
		{weight: 3}, // 1
		{weight: 30}, // 2
		{weight: 3}, // 3
		{weight: 45}, // 4
		{weight: 1}, // 5
		{weight: 20}, // 6
		{weight: 2}, // 7
		{weight: 60}, // 8
		{weight: 15}, // 9
		{weight: 2}, // 10
		{weight: 20}, // 11
		{weight: 20}, // 12
		{weight: 20}, // 13
		{weight: 2}, // 14
		{weight: 15}, // 15
		{weight: 0}
	];

	public static function getRandomOptionId() {
		var sum = 0;
		for (o in OPTION_INFOS)
			sum += o.weight;
		var rnd = Seed.random(sum);
		var sum = 0;
		var id = 0;
		for (o in OPTION_INFOS) {
			sum += o.weight;
			if (sum > rnd)
				return id;
			id++;
		}
		return null;
	}

	public static function getOption(id):Option {
		switch (id) {
			case 0:
				return new travoltax.opt.Breaker(2);
			case 1:
				return new travoltax.opt.Breaker(4);
			case 2:
				return new travoltax.opt.Filler(4);
			case 3:
				return new travoltax.opt.Filler(10);
			case 4:
				return new travoltax.opt.Contrat();
			case 5:
				return new travoltax.opt.Slow();
			case 6:
				return new travoltax.opt.Tresor(4);
			case 7:
				return new travoltax.opt.Tresor(5);
			case 8:
				return new travoltax.opt.Mini();
			case 9:
				return new travoltax.opt.Maxi();
			case 10:
				return new travoltax.opt.Riche();
			case 11:
				return new travoltax.opt.Cut();
			case 12:
				return new travoltax.opt.Faille();
			case 13:
				return new travoltax.opt.Fly(10);
			case 14:
				return new travoltax.opt.Fly(30);
			case 15:
				return new travoltax.opt.Psycho();
			case _:
				return new travoltax.opt.Breaker(2);
		}
		return null;
	}
}
