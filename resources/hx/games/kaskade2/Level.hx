package kaskade2;

import mt.Timer;

class Level {
	var game:Game;

	public var billes:Array<Array<Bille>>;
	public var groups:Array<Array<Bille>>;
	public var gravityList:Array<Bille> = [];

	public function new(g) {
		game = g;
		initLevel();
	}

	public function initLevel() {
		billes = new Array();
		for (x in 0...Const.LVL_WIDTH) {
			billes[x] = new Array();
			for (y in 0...Const.LVL_HEIGHT) {
				billes[x][y] = new Bille(game, x, y);
			}
		}
		makeGroups();
	}

	public function gravity() {
		gravityList = new Array();
		for (y in 0...Const.LVL_HEIGHT) {
			var space = false;
			var x = Const.LVL_WIDTH - 1;
			while (x >= 0) {
				var b = billes[x][y];
				if (b == null)
					space = true;
				else if (space) {
					billes[x + 1][y] = b;
					billes[x][y] = null;
					b.gravityLeft();
					gravityList.push(b);
				}
				x--;
			}
		}

		if (gravityList.length > 0)
			return;

		for (x in 0...Const.LVL_WIDTH) {
			var space = false;
			var y = Const.LVL_HEIGHT - 1;
			while (y >= 0) {
				var b = billes[x][y];
				if (b == null)
					space = true;
				else if (space) {
					billes[x][y + 1] = b;
					billes[x][y] = null;
					b.gravityDown();
					gravityList.push(b);
				}
				y--;
			}
		}

		if (gravityList.length == 0) {
			for (x in 0...Const.LVL_WIDTH) {
				for (y in 0...Const.LVL_HEIGHT) {
					if (billes[x][y] == null) {
						billes[x][y] = new Bille(game, x, y);
					}
				}
			}
			gravityList = null;
			makeGroups();
			game.nextTurn();
		}
	}

	public function makeGroupsRec(b:Bille, x:Int, y:Int, g:Array<Bille>) {
		var id = b.id;
		b.group = g;
		g.push(b);
		if (x - 1 >= 0) {
			b = billes[x - 1][y];
			if (b.id == id && b.group == null) {
				makeGroupsRec(b, x - 1, y, g);
			}
		}
		if (x + 1 < Const.LVL_WIDTH) {
			b = billes[x + 1][y];
			if (b.id == id && b.group == null) {
				makeGroupsRec(b, x + 1, y, g);
			}
		}
		if (y - 1 >= 0) {
			b = billes[x][y - 1];
			if (b.id == id && b.group == null) {
				makeGroupsRec(b, x, y - 1, g);
			}
		}
		if (y + 1 < Const.LVL_HEIGHT) {
			b = billes[x][y + 1];
			if (b.id == id && b.group == null) {
				makeGroupsRec(b, x, y + 1, g);
			}
		}
	}

	public function makeGroups() {
		for (x in 0...Const.LVL_WIDTH) {
			for (y in 0...Const.LVL_HEIGHT) {
				billes[x][y].group = null;
			}
		}
		groups = new Array();
		for (x in 0...Const.LVL_WIDTH) {
			for (y in 0...Const.LVL_HEIGHT) {
				var b = billes[x][y];
				if (b != null && b.group == null) {
					var g = new Array();
					makeGroupsRec(b, x, y, g);
					if (g.length < 2 || g[0].id == Const.MAXCOLORS - 1) { // COUPS
						for (b in g) {
							b.group = null;
							// b.star.gotoAndPlay("off");
						}
					} else {
						groups.push(g);
						for (b in g) {
							// b.star.gotoAndPlay("on");
						}
					}
				}
			}
		}
		if (groups.length == 0) {
			game.gameOver();
		}
	}

	public function animate() {
		var ds:Float = 10 * Timer.tmod * Const.NEW_GEN_SCALE;
		var x = Const.LVL_WIDTH - 1;
		while (x >= 0) {
			var y = Const.LVL_HEIGHT - 1;
			while (y >= 0) {
				var b = billes[x][y];
				if (b != null && b.scale < 100) {
					var s = b.scale + ds * (y + 1) / 3;
					if (s > 100)
						s = 100;
					b.scale = s;
					ds *= 0.95;
				}
				y--;
			}
			ds *= 1.2;
			x--;
		}
	}

	public function update() {
		animate();

		if (gravityList != null) {
			var i = 0;
			while (i < gravityList.length) {
				var b = gravityList[i];
				if (!b.gravityMain()) {
					gravityList.remove(b);
					i--;
					if (gravityList.length == 0) {
						game.bg.useHandCursor = false;
						gravity();
						break;
					}
				}
				i++;
			}
		}
	}
}
