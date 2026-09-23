package kavern;

class Level {
	public static inline var EMPTY = 0;
	public static inline var BLOCK = 1;
	public static inline var EARTH = 2;
	public static inline var FALLING = 3;
	public static inline var BLOCKSPE = 5;

	var game:Game;
	var dun:Array<Array<{
		t:Array<Array<Int>>,
		b:Array<{x:Int, y:Int, t:Int}>
	}>>;

	public var px:Int;
	public var py:Int;

	public var tbl:Array<Array<Int>>;
	public var bonus:Array<{x:Int, y:Int, t:Int}>;

	public function new(g:Game) {
		dun = new Array();
		bonus = new Array();
		game = g;
		px = 100;
		py = 0;
	}

	function checkPath(p:Array<Array<Bool>>, x:Int, y:Int):Bool {
		if (x < 0 || x >= Cs.WIDTH)
			return false;
		var l = tbl[x][y];
		if ((l == EMPTY || l == EARTH) && !p[x][y]) {
			p[x][y] = true;
			if (y == Cs.HEIGHT - 1)
				return true;
			if (checkPath(p, x, y + 1))
				return true;
			if (checkPath(p, x - 1, y))
				return true;
			if (checkPath(p, x + 1, y))
				return true;
		}
		return false;
	}

	function randomProbas(probas:Array<Int>):Int {
		var total = 0;
		for (value in probas)
			total += value;
		var random = Seed.random(total);
		for (i in 0...probas.length) {
			random -= probas[i];
			if (random < 0)
				return i;
		}
		return 0;
	}

	public function init(sx:Int, sy:Int, diff:Int):Void {
		var row = dun[px];
		var d = row == null ? null : row[py];
		if (d != null) {
			tbl = d.t;
			bonus = d.b;
			tbl[sx][sy] = EMPTY;
			return;
		}

		var nterres = Std.int(Math.max(100 - diff * 2, 10));
		var ntrous = Std.int(Math.max(10 - diff / 2, 3));
		var nlegs = 7 + Std.int(diff / 10);

		tbl = new Array();
		var x:Int;
		var y:Int;
		for (x in 0...Cs.WIDTH) {
			tbl[x] = new Array();
			for (y in 0...Cs.HEIGHT) {
				if ((y & 1) == 0) {
					if (x == 0 || x == Cs.WIDTH - 1) {
						if (y > 0 && y <= 5 && Seed.random(4) == 0)
							tbl[x][y] = EARTH;
						else
							tbl[x][y] = BLOCKSPE;
					} else
						tbl[x][y] = EARTH;
				} else if (x == 0 || x == Cs.WIDTH - 1)
					tbl[x][y] = BLOCKSPE;
				else
					tbl[x][y] = BLOCK;
			}
			tbl[x][Cs.HEIGHT] = EMPTY;
		}
		for (i in 0...nterres) {
			x = Seed.random(Cs.WIDTH - 2) + 1;
			y = Seed.random(Cs.HEIGHT) | 1;
			tbl[x][y] = EARTH;
		}

		for (i in 0...3) {
			x = Seed.random(Cs.WIDTH - 2) + 1;
			y = Seed.random(Cs.HEIGHT) & 0xFE;
			tbl[x][y] = BLOCK;
		}

		for (i in 0...ntrous) {
			x = Seed.random(Cs.WIDTH - 2) + 1;
			y = Seed.random(Cs.HEIGHT);
			if (tbl[x][y - 1] == EARTH)
				tbl[x][y] = EMPTY;
		}

		tbl[sx][sy] = EMPTY;
		if (sy > 0) {
			if (tbl[sx + 1] != null) {
				tbl[sx + 1][sy] = EARTH;
			}
			if (tbl[sx - 1] != null) {
				tbl[sx - 1][sy] = EARTH;
			}
		}

		tbl[sx][sy + 1] = BLOCK;
		var btbl = new Array();
		var probas = Cs.BONUS_PROBAS.copy();
		probas[0] += 20 - diff;
		if (probas[0] < 10)
			probas[0] = 10;
		bonus = new Array();
		for (i in 0...nlegs) {
			x = 1 + Seed.random(Cs.WIDTH - 2);
			y = Seed.random(Cs.HEIGHT - 1);
			if (tbl[x][y] == EARTH && Math.abs(sx - x) >= 2 && sy != y && !btbl[x + y * Cs.WIDTH]) {
				var t = randomProbas(probas);
				if (t == 2) {
					var max = Std.int(diff / 5) + 1;
					if (max > 6)
						max = 6;
					t = Std.int(2 + Math.min(Seed.random(max), Seed.random(max)));
				}
				btbl[x + y * Cs.WIDTH] = true;
				bonus.push({
					x: x,
					y: y,
					t: t
				});
			}
		}

		connect();

		var path = new Array();
		for (x in 0...Cs.WIDTH)
			path[x] = new Array();
		if (checkPath(path, sx, sy)) {
			if (dun[px] == null)
				dun[px] = new Array();
			dun[px][py] = {t: tbl, b: bonus};
		} else
			init(sx, sy, diff);
	}

	function connect():Void {
		var y:Int;
		var row = dun[px - 1];
		var data = row == null ? null : row[py];
		var t = data == null ? null : data.t;
		if (t != null) {
			for (y in 0...Cs.HEIGHT) {
				var l = t[Cs.WIDTH - 1][y];
				if (l != BLOCK && l != BLOCKSPE)
					tbl[0][y] = EARTH;
				else
					tbl[0][y] = BLOCKSPE;
			}
		}
		row = dun[px + 1];
		data = row == null ? null : row[py];
		t = data == null ? null : data.t;
		if (t != null) {
			for (y in 0...Cs.HEIGHT) {
				var l = t[0][y];
				if (l != BLOCK && l != BLOCKSPE)
					tbl[Cs.WIDTH - 1][y] = EARTH;
				else
					tbl[Cs.WIDTH - 1][y] = BLOCKSPE;
			}
		}
	}
}
