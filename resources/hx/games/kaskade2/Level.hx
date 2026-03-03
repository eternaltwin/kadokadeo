package kaskade2;

import mt.Timer;

class Level {
	var game:Game;

	public var billes:Array<Array<Bille>>;
	public var groups:Array<Array<Bille>>;
	public var gravityList:Array<Bille>;

	public function new(g) {
		game = g;
		initLevel();
	}

	public function initLevel() {
		var x = 0;
		billes = new Array();
		while (x < Const.LVL_WIDTH) {
			var y = 0;
			billes[x] = new Array();
			while (y < Const.LVL_HEIGHT) {
				billes[x][y] = new Bille(game, x, y);
				y++;
			}
			x++;
		}
		makeGroups();
	}

	public function gravity() {
		var y = 0;
		var x = 0;
		gravityList = new Array();
		while (y < Const.LVL_HEIGHT) {
			x = Const.LVL_WIDTH - 1;
			var space = false;
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
			y++;
		}

		if (gravityList.length > 0)
			return;

		x = 0;
		while (x < Const.LVL_WIDTH) {
			var space = false;
			y = Const.LVL_HEIGHT - 1;
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
			x++;
		}

		if (gravityList.length == 0) {
			x = 0;
			while (x < Const.LVL_WIDTH) {
				y = 0;
				while (y < Const.LVL_HEIGHT) {
					if (billes[x][y] == null) {
						billes[x][y] = new Bille(game, x, y);
					}
					y++;
				}
				x++;
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
		b = billes[x - 1][y];
		if (b.id == id && b.group == null) {
			makeGroupsRec(b, x - 1, y, g);
		}
		b = billes[x + 1][y];
		if (b.id == id && b.group == null) {
			makeGroupsRec(b, x + 1, y, g);
		}
		b = billes[x][y - 1];
		if (b.id == id && b.group == null) {
			makeGroupsRec(b, x, y - 1, g);
		}
		b = billes[x][y + 1];
		if (b.id == id && b.group == null) {
			makeGroupsRec(b, x, y + 1, g);
		}
	}

	public function makeGroups() {
		var i, x, y;
		x = 0;
		while (x < Const.LVL_WIDTH) {
			y = 0;
			while (y < Const.LVL_HEIGHT) {
				billes[x][y].group = null;
				y++;
			}
			x++;
		}
		groups = new Array();
		x = 0;
		while (x < Const.LVL_WIDTH) {
			y = 0;
			while (y < Const.LVL_HEIGHT) {
				var b = billes[x][y];
				if (b != null && b.group == null) {
					var g = new Array();
					makeGroupsRec(b, x, y, g);
					if (g.length < 2 || g[0].id == Const.MAXCOLORS - 1) { // COUPS
						for (b in g) {
							b.group = null;
							b.star.gotoAndPlay("off");
						}
					} else {
						groups.push(g);
						for (b in g) {
							b.star.gotoAndPlay("on");
						}
					}
				}
				y++;
			}
			x++;
		}
		if (groups.length == 0) {
			game.gameOver();
		}
	}

	public function animate() {
		var ds:Float = 10 * Timer.tmod;
		var x, y;
		x = Const.LVL_WIDTH - 1;
		while (x >= 0) {
			y = Const.LVL_HEIGHT - 1;
			while (y >= 0) {
				var mc = billes[x][y].mc;
				if (mc._xscale < 100) {
					var s = mc._xscale + ds * (y + 1) / 3;
					if (s > 100)
						s = 100;
					mc._xscale = s;
					mc._yscale = s;
					ds *= 0.95;
				}
				y--;
			}
			ds *= 1.2;
			x--;
		}
	}

	public function main() {
		animate();

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
