package cookinglili;

import common_haxe_avm1.kac.ProtectedInt;
import common_haxe_avm1.KKApi;

typedef T_Pair = {
	x:Int,
	y:Int,
	dx:Int,
	dy:Int,
	t1:Token,
	t2:Token,
}

typedef T_Combo = {
	v:Int,
	x:Int,
	y:Int,
	score:Int,
	mx:Float,
	my:Float,
}

class Level {
	static public var START_LINES = 5; // was 5
	static public var START_VARIETY = 3;
	static public var WID = 10;
	static public var HEI = 10;
	static public var X_OFF = Cs.GWID * 0.5 - Cs.TWID * WID * 0.5;
	static public var Y_OFF = Cs.GHEI - Cs.THEI * HEI;
	static var SOLVES_BY_FRAME = 7;

	public var map:Array<Array<Token>>;
	public var variety:ProtectedInt;
	public var diff:ProtectedInt;

	var armorRate:Int;
	var comboMul:KKConst;

	/*------------------------------------------------------------------------
		G�N�RATION INITIALE
		------------------------------------------------------------------------ */
	public function new() {
		variety = START_VARIETY;

		diff = 0;
		armorRate = 0;

		map = new Array();
		for (x in 0...WID) {
			map[x] = new Array();
		}

		for (i in 0...START_LINES)
			addLine();

		comboMul = KKApi.const(0);
	}

	public function getPair(x, y, dx, dy):T_Pair {
		if (map[x] == null || map[x + dx] == null) {
			return null;
		}

		var t1 = map[x][y];
		var t2 = map[x + dx][y + dy];

		if (t1 == null || t2 == null) {
			return null;
		}
		return {
			x: x,
			y: y,
			dx: dx,
			dy: dy,
			t1: t1,
			t2: t2,
		}
	}

	public function different(p:T_Pair) {
		return p.t1.id != p.t2.id || p.t1.fl_armor != p.t2.fl_armor;
	}

	/*------------------------------------------------------------------------
		CONVERTISSEUR SYST�ME DE COORDONN�ES R�EL <-> CASE
		------------------------------------------------------------------------ */
	public static function x_rtc(xr:Float) {
		return Math.floor((xr - X_OFF) / Cs.TWID);
	}

	public static function y_rtc(yr:Float) {
		return Math.floor((yr - Y_OFF) / Cs.THEI);
	}

	public static function x_ctr(x:Int) {
		return x * Cs.TWID + X_OFF;
	}

	public static function y_ctr(y:Int) {
		return y * Cs.THEI + Y_OFF;
	}

	public static function x_token(x:Int) {
		return x_ctr(x) + Cs.TWID * 0.5;
	}

	public static function y_token(y:Int) {
		return y_ctr(y) + Cs.THEI * 0.5;
	}

	function updateCoords() {
		for (x in 0...WID) {
			for (y in 0...HEI) {
				if (map[x][y] != null) {
					map[x][y].x = x;
					map[x][y].y = y;
				}
			}
		}
	}

	function hasVisited(visited:Array<String>, x:Int, y:Int) {
		var key = x + ":" + y;
		for (v in visited) {
			if (v == key)
				return true;
		}
		visited.push(key);
		return false;
	}

	function countSameGroup(x:Int, y:Int, id:Int, visited:Array<String>):Int {
		if (map[x] == null || map[x][y] == null || map[x][y].id != id || hasVisited(visited, x, y))
			return 0;

		return 1 + countSameGroup(x - 1, y, id, visited) + countSameGroup(x + 1, y, id, visited) + countSameGroup(x, y - 1, id, visited)
			+ countSameGroup(x, y + 1, id, visited);
	}

	function createsComboAt(x:Int, y:Int) {
		var token = map[x][y];
		return token != null && countSameGroup(x, y, token.id, []) >= KKApi.val(Cs.MIN_COMBO);
	}

	// *** ACTIONS

	/*------------------------------------------------------------------------
		SWAP LOGIQUE
		------------------------------------------------------------------------ */
	public function swap(p:T_Pair) {
		if (p == null)
			return false;

		var t1 = map[p.x][p.y];
		var t2 = map[p.x + p.dx][p.y + p.dy];
		if (t1 == null || t2 == null)
			return false;

		map[p.x][p.y] = t2;
		map[p.x + p.dx][p.y + p.dy] = t1;
		return true;
	}

	/*------------------------------------------------------------------------
		ADDS A LINE AT BOTTOM
		------------------------------------------------------------------------ */
	public function addLine() {
		for (x in 0...WID) {
			for (y in 0...HEI) {
				if (map[x][y] != null && y == 0)
					return false;
				map[x][y - 1] = map[x][y];
				map[x][y] = null;
			}
		}
		var x = 0;
		while (x < WID) {
			var t = map[x][HEI - 1] = new Token(Game.me, 0);
			var choices = new Array();
			for (i in 0...variety)
				choices.push(i);

			while (choices.length > 0) {
				var choice = Seed.random(choices.length);
				t.setId(choices[choice]);
				choices.splice(choice, 1);
				if (!createsComboAt(x, HEI - 1))
					break;
			}

			if (armorRate > 0 && Seed.random(armorRate) == 0)
				t.fl_armor = true;
			x++;
		}
		for (col in map) {
			for (t in col) {
				if (t != null) {
					t.combo = null;
				}
			}
		}
		updateCoords();

		return true;
	}

	/*------------------------------------------------------------------------
		ENDS ROUND AND UPDATES DIFFICULTY
		------------------------------------------------------------------------ */
	public function endRound() {
		comboMul = KKApi.const(0);
		diff = diff + 1;
		if (diff == 5)
			armorRate = 10;
		if (diff % 15 == 0 && armorRate > 4)
			armorRate -= 2;

		if (diff == 15) {
			variety = variety + 1;
		}

		if (diff == 35) {
			variety = variety + 1;
		}
	}

	/*------------------------------------------------------------------------
		GET THE LIST OF DANGEROUS TOKENS
		------------------------------------------------------------------------ */
	public function getWarnings() {
		updateCoords();
		var w = new Array();
		for (col in map) {
			if (col[0] != null) {
				w.push(col[0]);
			}
		}
		return w;
	}

	// *** GAME RESOLUTION

	/*------------------------------------------------------------------------
		GENERAL COMBO CHECK
		------------------------------------------------------------------------ */
	public function checkRec(token:Token, x:Int, y:Int, c:T_Combo) {
		if (token.fl_armor || token.mc == null) {
			return;
		}
		c.v++;
		c.score += token.mul * c.v * c.v * KKApi.val(Cs.PTS_TOKEN);
		c.mx = 0.5 * (token.mc._x + c.mx);
		c.my = 0.5 * (token.mc._y + c.my);
		token.combo = c;
		var nei;
		// gauche
		if (map[x - 1] != null && map[x - 1][y] != null) {
			nei = map[x - 1][y];
			if (token.id == nei.id && nei.combo == null)
				checkRec(nei, x - 1, y, c);
		}
		// droite
		if (map[x + 1] != null && map[x + 1][y] != null) {
			nei = map[x + 1][y];
			if (token.id == nei.id && nei.combo == null)
				checkRec(nei, x + 1, y, c);
		}
		// haut
		if (map[x] != null && map[x][y - 1] != null) {
			nei = map[x][y - 1];
			if (token.id == nei.id && nei.combo == null)
				checkRec(nei, x, y - 1, c);
		}
		// bas
		if (map[x] != null && map[x][y + 1] != null) {
			nei = map[x][y + 1];
			if (token.id == nei.id && nei.combo == null)
				checkRec(nei, x, y + 1, c);
		}
	}

	public function check(fl_score) {
		comboMul = KKApi.cadd(comboMul, KKApi.const(1));
		var combos = new Array();
		for (col in map)
			for (token in col) {
				if (token != null) {
					token.combo = null;
				}
			}

		for (x in 0...WID)
			for (y in 0...HEI) {
				var token = map[x][y];
				if (token != null && token.mc != null && token.combo == null) {
					var c:T_Combo = {
						v: 0,
						x: x,
						y: y,
						mx: token.mc._x,
						my: token.mc._y,
						score: 0
					};
					checkRec(token, x, y, c);
					if (c.v >= KKApi.val(Cs.MIN_COMBO))
						combos.push(c);
				}
			}

		if (combos.length == 0)
			return null;
		if (fl_score) {
			for (c in combos) {
				var val = KKApi.val(comboMul) * c.score;
				Game.me.addScore(KKApi.const(val), c.mx, c.my);
			}
		}
		return combos;
	}

	function getPossibleSwaps() {
		// listing des possibilit�s
		var swaps:List<T_Pair> = new List();
		for (x in 0...WID)
			for (y in 1...HEI) { // on ignore la ligne 0, pas int�ressante � swapper
				if (map[x] == null || map[x][y] == null)
					continue;
				var s:T_Pair = {
					x: x,
					y: y,
					dx: 0,
					dy: 0,
					t1: null,
					t2: null,
				}
				// droite
				if (map[x + 1] != null && map[x + 1][y] != null && map[x + 1][y].id != map[x][y].id) {
					s.dx = 1;
					swaps.add(s);
				} else
					// bas
					if (map[x][y + 1] != null && map[x][y + 1].id != map[x][y].id) {
						s.dy = 1;
						swaps.add(s);
					}
			}
		return swaps;
	}

	/*------------------------------------------------------------------------
		COMBO EXPLOSIONS
		------------------------------------------------------------------------ */
	public function explodeRec(now, arm, c:T_Combo, x, y) {
		//		var g = new flash.filters.GlowFilter();
		//		if ( c.x==x && c.y==y ) {
		//			g.color = 0xffffff;
		//		}
		//		else {
		//			g.color = 0x990000;
		//		}
		//
		//		g.blurX = 10;
		//		g.blurY = g.blurX;
		//		g.inner = true;
		//		map[x][y].mc.filters = [g];

		var nei = map[x][y];
		nei.combo = null;
		now.push(nei);
		map[x][y] = null;

		// left
		if (map[x - 1] != null && map[x - 1][y] != null) {
			nei = map[x - 1][y];
			if (nei.combo == c)
				explodeRec(now, arm, c, x - 1, y);
			else if (nei.fl_armor) {
				arm.push(nei);
				nei.fl_armor = false;
				nei.mc._alpha = 100;
			}
		}
		// right
		if (map[x + 1] != null && map[x + 1][y] != null) {
			nei = map[x + 1][y];
			if (nei.combo == c)
				explodeRec(now, arm, c, x + 1, y);
			else if (nei.fl_armor) {
				arm.push(nei);
				nei.fl_armor = false;
				nei.mc._alpha = 100;
			}
		}
		// up
		if (map[x] != null && map[x][y - 1] != null) {
			nei = map[x][y - 1];
			if (nei.combo == c)
				explodeRec(now, arm, c, x, y - 1);
			else if (nei.fl_armor) {
				arm.push(nei);
				nei.fl_armor = false;
				nei.mc._alpha = 100;
			}
		}
		// down
		if (map[x] != null && map[x][y + 1] != null) {
			nei = map[x][y + 1];
			if (nei.combo == c)
				explodeRec(now, arm, c, x, y + 1);
			else if (nei.fl_armor) {
				arm.push(nei);
				nei.fl_armor = false;
				nei.mc._alpha = 100;
			}
		}
	}

	public function explode(combos:Array<T_Combo>) {
		updateCoords();
		var arm = new Array();
		var now = new Array();
		for (c in combos)
			explodeRec(now, arm, c, c.x, c.y);
		return {explNow: now, explArm: arm};
	}

	public function gravity() {
		for (col in map)
			for (token in col) {
				if (token == null)
					continue;
				token.fall = 0;
				token.moveDist = 0;
			}
		var falls = 0;
		var y = HEI - 2;
		while (y >= 0) {
			for (x in 0...WID) {
				var token = map[x][y];
				if (token != null && token.fall == 0) {
					var under = map[x][y + 1];
					if (under != null) {
						// check under status
						token.fall = under.fall;
					} else {
						// nothing under
						var h = 1;
						while (y + h < HEI - 1 && map[x][y + h] == null) {
							h++;
						}
						if (map[x][y + h] != null) {
							h += map[x][y + h].fall - 1;
						}
						token.fall = h;
					}
					if (token.fall > 0) {
						falls++;
					}
				}
			}
			y--;
		}

		// application r�elle des mouvements
		y = HEI - 2;
		while (y >= 0) {
			for (x in 0...WID) {
				var token = map[x][y];
				if (token != null && token.fall > 0) {
					map[x][y + token.fall] = map[x][y];
					map[x][y] = null;
				}
			}
			y--;
		}
		return falls;
	}
}
