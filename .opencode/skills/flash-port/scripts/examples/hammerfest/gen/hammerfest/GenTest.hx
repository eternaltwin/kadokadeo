package hammerfest;

// The generator of the levels of Hammerfest alone, for node (no game, no browser): the wells of a few seeds as JSON
// lines, one per level, to draw the sheet of levels (sheet.py), check the rules of the design (check.py) and the
// statistics (stats.py).
//   node run.cjs <seed> <count> [first depth]      the levels first depth..+count of the well of this seed
//   node run.cjs --wells <seed>,<seed>,... <count>  the whole wells of these seeds (count levels each, from 0)
// Each line: {s: seed, d, kind, concept, want, sym, budget, map, bads, px, py, sp, sc, oe, en, bg, t, dark}
// env GEN_FAILS=1: the counters of LevelGen.fails on stderr at the end
class GenTest {
	static function level(seed:Int, d:Int):String {
		LevelGen.fails = new Map();
		LevelGen.failMaps = [];
		var l = Levels.get(d);
		var env:Dynamic = untyped process.env;
		if (env.GEN_WHY != null && LevelGen.failMaps.length > 0 && (env.GEN_AT == null || Std.parseInt(env.GEN_AT) == d))
			untyped console.error("seed " + seed + " depth " + d + "\n" + LevelGen.failMaps.join("\n\n"));
		return haxe.Json.stringify({
			fails: [for (k in LevelGen.fails.keys()) k + "=" + LevelGen.fails.get(k)],
			s: seed,
			d: d,
			kind: LevelGen.lastKind,
			concept: LevelGen.lastConcept,
			want: LevelGen.lastWant,
			sym: LevelGen.lastSym,
			budget: LevelGen.lastBudget,
			map: l.map,
			bads: l.bads,
			px: l.playerX,
			py: l.playerY,
			sp: l.specialSlots,
			sc: l.scoreSlots,
			oe: l.openAtEnd,
			en: l.entry,
			bg: l.skinBg,
			t: l.skinTiles,
			dark: l.darkness,
			reach: LevelGen.lastReach,
			pockets: LevelGen.lastPockets
		});
	}

	static function main() {
		var argv:Array<String> = untyped process.argv;
		// env GEN_WHY=<reason>: the maps of the levels failing for this reason (LevelGen.fail), GEN_AT=<depth>: at this depth
		var env:Dynamic = untyped process.env;
		if (env.GEN_WHY != null)
			LevelGen.failWhy = env.GEN_WHY;
		var out = [];
		if (argv[2] == "--wells") {
			var seeds = [for (s in argv[3].split(",")) Std.parseInt(s)];
			var n = Std.parseInt(argv[4]);
			for (seed in seeds) {
				kado.Seed.init(seed);
				Levels.reset();
				for (d in 0...n)
					out.push(level(seed, d));
			}
		} else {
			var seed = Std.parseInt(argv[2]);
			var n = Std.parseInt(argv[3]);
			var d0 = argv.length > 4 ? Std.parseInt(argv[4]) : 0;
			kado.Seed.init(seed);
			Levels.reset();
			for (d in d0...d0 + n)
				out.push(level(seed, d));
		}
		untyped console.log(out.join("\n"));
	}
}
