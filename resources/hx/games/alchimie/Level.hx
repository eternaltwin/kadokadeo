package alchimie;

class Level {
	var game:Game;
	var step:Int;

	public var coins:Array<Array<Coin>>;

	var groups:Array<Array<Coin>>;
	var oldgravity:Array<Coin>;
	var gravityList:Array<Coin>;
	var explodeList:Array<Coin>;
	var transmuteList:Array<Coin>;

	public function new(g:Game) {
		game = g;
		step = 0;
	}

	public function initLevel():Void {
		coins = [];
		for (x in 0...Cs.WIDTH) {
			coins[x] = [];
		}
		oldgravity = [];
		gravityList = [];
		explodeList = [];
		transmuteList = [];
	}

	function makeGroupsRec(c:Coin, x:Int, y:Int, g:Array<Coin>):Void {
		var id = c.id;
		c.group = g;
		g.push(c);
		if (x > 0) {
			c = coins[x - 1][y];
			if (c != null && c.id == id && c.group == null) {
				makeGroupsRec(c, x - 1, y, g);
			}
		}
		if (x + 1 < Cs.WIDTH) {
			c = coins[x + 1][y];
			if (c != null && c.id == id && c.group == null) {
				makeGroupsRec(c, x + 1, y, g);
			}
		}
		if (y > 0) {
			c = coins[x][y - 1];
			if (c != null && c.id == id && c.group == null) {
				makeGroupsRec(c, x, y - 1, g);
			}
		}
		if (y + 1 < Cs.HEIGHT) {
			c = coins[x][y + 1];
			if (c != null && c.id == id && c.group == null) {
				makeGroupsRec(c, x, y + 1, g);
			}
		}
	}

	function makeGroups():Void {
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				var c = coins[x][y];
				if (c != null) {
					c.group = null;
					c.x = x;
					c.y = y;
				}
			}
		}
		groups = [];
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				var c = coins[x][y];
				if (c != null && c.group == null) {
					var g = [];
					makeGroupsRec(c, x, y, g);
					groups.push(g);
				}
			}
		}
	}

	public function gravity():Bool {
		gravityList = [];
		for (x in 0...Cs.WIDTH) {
			var space = false;
			var y = Cs.HEIGHT - 1;
			while (y >= 0) {
				var c = coins[x][y];
				if (c == null) {
					space = true;
				} else if (space) {
					coins[x][y + 1] = c;
					coins[x][y] = null;
					c.x = x;
					c.y = y + 1;
					c.gravityInit();
					gravityList.push(c);
				}
				y--;
			}
		}

		for (y in 0...Cs.HEIGHT) {
			for (x in 0...Cs.WIDTH) {
				var c = coins[x][y];
				if (c != null) {
					game.dmanager.over(c.mc);
				}
			}
		}

		for (c in oldgravity) {
			var found = false;
			for (gravityCoin in gravityList) {
				if (gravityCoin == c) {
					found = true;
					break;
				}
			}
			if (!found) {
				c.recall();
			}
		}
		oldgravity = gravityList.copy();
		return gravityList.length > 0;
	}

	public function explode():Bool {
		makeGroups();
		explodeList = [];
		for (g in groups) {
			if (g.length >= Cs.EXPLODE_COUNT && g[0].id != Cs.POINTS.length - 1) {
				var minx = g[0].x;
				var miny = g[0].y;
				var nextId = g[0].id + 1;

				if (nextId >= Cs.ID_COUNT) {
					Cs.ID_COUNT = nextId + 1;
				}

				for (coin in g) {
					if (coin.y >= miny) {
						if (coin.y > miny || coin.x < minx) {
							minx = coin.x;
						}
						miny = coin.y;
					}
				}

				var target:Coin = null;
				for (coin in g) {
					if (minx == coin.x && miny == coin.y) {
						target = coin;
					}
				}

				for (coin in g) {
					coin.explodeInit(target);
					explodeList.push(coin);
					if (coin != target) {
						coins[coin.x][coin.y] = null;
					} else {
						coin.nextId = nextId;
					}
				}
			}
		}
		return explodeList.length > 0;
	}

	public function update():Bool {
		var i = 0;
		while (i < explodeList.length) {
			var c = explodeList[i];
			if (!c.explodeUpdate()) {
				explodeList.splice(i, 1);
			} else {
				i++;
			}
		}
		i = 0;
		while (i < gravityList.length) {
			var c = gravityList[i];
			if (!c.gravityUpdate()) {
				gravityList.splice(i, 1);
			} else {
				i++;
			}
		}
		i = 0;
		while (i < transmuteList.length) {
			var c = transmuteList[i];
			if (!c.transmuteUpdate()) {
				transmuteList.splice(i, 1);
			} else {
				i++;
			}
		}
		return gravityList.length > 0 || explodeList.length > 0 || transmuteList.length > 0;
	}
}
