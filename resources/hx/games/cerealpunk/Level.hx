package cerealpunk;

// a cell next to an exploded group: Level.explodes damages it (stone) or destroys it (bonus)
typedef Blast = {x:Int, y:Int, l:Legume};

// Level.mt: the grid, column x, row y (0 at the top, under the cook; new rows come in at the bottom)
class Level {
	var game:Game;

	public var legumes:Array<Array<Legume>>;

	var width:Int;
	var height:Int;

	public function new(g:Game) {
		width = Const.WIDTH;
		height = Const.HEIGHT;
		game = g;
		legumes = [];
		for (i in 0...width)
			legumes[i] = [];
	}

	// legumes[x][y]: undefined out of the grid in Flash (every test on it is false)
	public inline function at(x:Int, y:Int):Legume {
		return x >= 0 && x < width && y >= 0 && y < height ? legumes[x][y] : null;
	}

	public function genLine() {
		for (i in 0...width)
			genPushLegume(i, null);
	}

	function genPushLegume(x:Int, l:Legume):Bool {
		if (legumes[x][0] != null)
			return false;
		for (y in 1...height) {
			var ltmp = legumes[x][y];
			legumes[x][y - 1] = ltmp;
			game.animator.moveUp(ltmp);
		}
		if (l == null) {
			l = new Legume(game, game.randId(), x, height);
			game.animator.moveUp(l);
		}
		legumes[x][height - 1] = l;
		return true;
	}

	// the top cereal of the column when it is `id` (id null: any), not a bubble; nothing after a stone
	public function popLegume(x:Int, id:Null<Int>):Legume {
		for (y in 0...height) {
			var l = legumes[x][y];
			if (l != null) {
				if ((l.id == id || id == null) && id != Const.PIERRE && l.id != Const.BULLE) {
					legumes[x][y] = null;
					return l;
				}
				return null;
			}
		}
		return null;
	}

	function freeHeight(x:Int):Int {
		var y = 0;
		while (y < height) {
			if (legumes[x][y] != null)
				break;
			y++;
		}
		return y;
	}

	public function maxHeight():Int {
		var max = 0;
		for (x in 0...width) {
			var y = 0;
			while (y < height) {
				if (legumes[x][y] != null)
					break;
				y++;
			}
			if (height - y > max)
				max = height - y;
		}
		return max;
	}

	// the cell above the top of the column (-1: the column is full)
	public function pushLegume(x:Int, l:Legume):Int {
		var y = 0;
		while (y < height) {
			if (legumes[x][y] != null)
				break;
			y++;
		}
		y--;
		if (y >= 0)
			legumes[x][y] = l;
		return y;
	}

	// the group of `id` from (x, y) (taken out of the grid) into c, the cells around it into b
	function explode_rec(c:Array<Legume>, b:Array<Blast>, x:Int, y:Int, id:Int) {
		var f = at(x, y);
		legumes[x][y] = null;
		f.moved = false;
		c.push(f);

		f = at(x, y - 1);
		if (f != null && f.id == id)
			explode_rec(c, b, x, y - 1, id);
		else {
			if (f != null)
				f.blast = false;
			b.push({x: x, y: y - 1, l: f});
		}

		f = at(x, y + 1);
		if (f != null && f.id == id)
			explode_rec(c, b, x, y + 1, id);
		else {
			if (f != null)
				f.blast = false;
			b.push({x: x, y: y + 1, l: f});
		}

		f = at(x - 1, y);
		if (f != null && f.id == id)
			explode_rec(c, b, x - 1, y, id);
		else {
			if (f != null)
				f.blast = false;
			b.push({x: x - 1, y: y, l: f});
		}

		f = at(x + 1, y);
		if (f != null && f.id == id)
			explode_rec(c, b, x + 1, y, id);
		else {
			if (f != null)
				f.blast = false;
			b.push({x: x + 1, y: y, l: f});
		}
	}

	// 3 of `id` in the column through (x, y): the whole group touching it explodes
	function explode_scan(x:Int, y:Int, id:Int):{x:Array<Legume>, b:Array<Blast>} {
		var count = 1;
		var tmp_y = y + 1;
		while (at(x, tmp_y) != null && at(x, tmp_y).id == id) {
			tmp_y++;
			count++;
		}
		if (count < 3) {
			tmp_y = y - 1;
			while (at(x, tmp_y) != null && at(x, tmp_y).id == id) {
				tmp_y--;
				count++;
			}
		}
		if (count >= 3) {
			var c = [];
			var blasted = [];
			explode_rec(c, blasted, x, y, id);
			return {x: c, b: blasted};
		}
		return null;
	}

	function blast(a:Array<Blast>, x:Int, y:Int) {
		var l = at(x, y);
		if (l == null)
			return;
		a.push({x: x, y: y, l: l});
	}

	// the groups of the cereals that moved; a gold cereal in a group takes every cereal of its kind; the stones and
	// bonuses next to them are hit. null: nothing explodes
	public function explodes():{combos:Array<Array<Legume>>} {
		var exlist:Array<Array<Legume>> = [];
		var blist:Array<Array<Blast>> = [];
		var golds:Array<Int> = [];

		for (x in 0...width) {
			var legs = legumes[x];
			for (y in 0...height) {
				var l = legs[y];
				if (l != null && l.moved) {
					l.moved = false;
					if (l.id == Const.PIERRE)
						continue;
					var c = explode_scan(x, y, l.id);
					if (c != null) {
						for (i in 0...c.x.length)
							if (c.x[i].gold) {
								golds.push(l.id);
								break;
							}
						exlist.push(c.x);
						blist.push(c.b);
					}
				}
			}
		}
		if (exlist.length == 0)
			return null;

		var gblasts:Array<Blast> = [];
		for (i in 0...golds.length) {
			var e = [];
			game.stats.g[golds[i]]++;
			for (x in 0...width)
				for (y in 0...height) {
					var l = legumes[x][y];
					if (l != null && l.id == golds[i]) {
						legumes[x][y] = null;
						e.push(l);
						blast(gblasts, x, y - 1);
						blast(gblasts, x, y + 1);
						blast(gblasts, x - 1, y);
						blast(gblasts, x + 1, y);
					}
				}
			if (e.length != 0)
				exlist.push(e);
		}
		blist.push(gblasts);

		for (i in 0...blist.length) {
			var b = blist[i];
			for (j in 0...b.length) {
				var m = b[j];
				// (a cell out of the grid or empty: undefined in Flash, nothing happens)
				if (m.l == null || m.l.blast)
					continue;
				m.l.blast = true;
				switch (m.l.id) {
					case Const.PIERRE:
						#if debug
						Game.cov.stones++;
						#end
						if (!m.l.stoneParts())
							legumes[m.x][m.y] = null;
					case Const.BONUS1, Const.BONUS2:
						#if debug
						Game.cov.bonusDie++;
						#end
						game.animator.destroyLegume(m.l);
						legumes[m.x][m.y] = null;
					case _:
				}
			}
		}
		return {combos: exlist};
	}

	// everything above the lowest hole of each column falls by one cell (null: nothing fell)
	public function gravity():Array<Legume> {
		var glist = [];
		for (x in 0...width) {
			var legs = legumes[x];
			var y = height - 1;
			while (y > 0) {
				if (legs[y] == null)
					break;
				y--;
			}
			y--;
			while (y >= 0) {
				var l = legs[y];
				if (l != null) {
					l.moved = true;
					legs[y + 1] = l;
					legs[y] = null;
					glist.push(l);
				}
				y--;
			}
		}
		if (glist.length == 0)
			return null;
		return glist;
	}

	// the bubbles under a cereal that moved burst (null: none)
	public function explodeBulles():Array<Legume> {
		var bulles = [];
		for (x in 0...width) {
			var legs = legumes[x];
			var moved = false;
			for (y in 0...height)
				if (moved && legs[y] != null && legs[y].id == Const.BULLE) {
					bulles.push(legs[y]);
					legs[y] = null;
				} else if (legs[y] != null && legs[y].moved)
					moved = true;
		}
		if (bulles.length == 0)
			return null;
		return bulles;
	}
}
