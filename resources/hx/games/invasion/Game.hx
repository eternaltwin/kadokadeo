package invasion;

import mt.bumdum.Lib;
import common_haxe_avm1.KKApi;

class CursorSprite extends ASprite {
	public var main:ASprite;
	public var arrow:ASprite;
	public var attack:Array<ASprite>;
}

class Point {
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}
}

@:expose('GameInvasion')
class Game implements kado.GameInterface {
	public static inline var PLACE = 0;
	public static inline var ATTACK = 1;
	public static inline var END = 2;
	public static inline var EXIT = 3;
	public static inline var ANIM = 4;

	public var dmanager:mt.DepthManager;

	public var level:Array<Array<Perso>>;
	public var cases:Array<Array<ASprite>>;

	public var state:Int;

	public var cursor:CursorSprite;
	public var root_mc:ASprite;
	public var anims:Array<Perso>;
	public var monster_turn:Bool;
	public var wait:Array<Perso>;

	public var playerTargetX:Int;
	public var playerTargetY:Int;

	public var stats:{
		l:Int,
		s:Int,
		k:Array<Int>,
		m:Array<Int>,
		g:Array<Int>,
	};

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayMouseButtons = new UInt16Array(1);
		replayMouseButtons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: replayMouseButtons,
		});

		root_mc = root;
		dmanager = new mt.DepthManager(root);
		var bg = dmanager.attach("background", Cs.PLAN_BG);
		level = new Array();
		cases = new Array();
		anims = new Array();
		wait = new Array();
		state = Game.PLACE;
		cursor = cast dmanager.empty(Cs.PLAN_CURSOR);
		cursor.main = cursor.attachMovie("cursor");
		var arrow = cursor.main.attachMovie('cursor_arrow');
		arrow._x = Cs.S(6.5);
		arrow._y = Cs.S(-0.3);
		arrow.loop = true;
		arrow.play();
		cursor._visible = false;
		cursor.attack = new Array();
		for (i in 0...4) {
			var a = cursor.attachMovie('cursor' + (i + 2));
			a.loop = true;
			a.play();
			a._visible = false;
			cursor.attack.push(a);
		}

		for (x in 0...Cs.WIDTH) {
			level[x] = new Array();
			cases[x] = new Array();
			for (y in 0...Cs.HEIGHT) {
				var mc = dmanager.attach("case", Cs.PLAN_CASES);
				if (Seed.random(4) == 0)
					mc.gotoAndStop(1 + Seed.random(mc._totalframes));
				else
					mc.stop();
				Cs.pos(mc, x, y);
				mc.useHandCursor = false;
				cases[x][y] = mc;
			}
		}
		var bg2 = dmanager.attach("background_dirt-element", Cs.PLAN_CASES);
		bg2._x = Cs.mcw;
		bg2._y = Cs.mch;
		stats = {
			l: 0,
			s: 0,
			k: [0, 0, 0],
			m: [0, 0, 0],
			g: [],
		};
		// autoFillInitialGrid();
		root.useHandCursor = false;
	}

	public function autoFillInitialGrid() {
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				if (level[x][y] == null) {
					place(x, y);
				}
			}
		}
	}

	public function monsterPlace() {
		var x, y, x2, y2;
		var l = new Array();
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				if (level[x][y] == null) {
					var k1 = 0.0, k2 = 0.0;
					for (x2 in 0...Cs.WIDTH) {
						for (y2 in 0...Cs.HEIGHT) {
							var p = level[x2][y2];
							if (p != null) {
								var d = Num.q(Math.pow(Math.abs(x - x2) * Math.abs(y - y2), 0.7));
								if (p.hero)
									k1 = Num.q(k1 - d * 0.3);
								else
									k2 = Num.q(k2 + d);
							}
						}
						l.push({
							x: x,
							y: y,
							k1: k1,
							k2: k2
						});
					}
				}
			}
		}

		l.sort(function(p1, p2) {
			var s1 = Num.q(p1.k1 + p1.k2);
			var s2 = Num.q(p2.k1 + p2.k2);
			if (s2 > s1)
				return 1;
			if (s2 < s1)
				return -1;
			if (p1.x != p2.x)
				return p1.x - p2.x;
			return p1.y - p2.y;
		});
		if (l.length == 0)
			return false;
		var choice = l[Seed.random(Std.int(l.length / 4))];
		var p = new Perso(this, false, choice.x, choice.y);
		level[p.x][p.y] = p;
		return true;
	}

	public function monsterCheckAttack(x, y, dx, dy, l) {
		var att = sameCount(false, x + dx, y + dy, dx, dy);
		if (att == 0)
			return;
		var def = sameCount(true, x, y, -dx, -dy);
		if (att > def)
			l.push({
				x: x,
				y: y,
				dx: dx,
				dy: dy,
				att: att,
				def: def,
				can: true
			});
	}

	public function playerCheckAttack(x, y, dx, dy) {
		var att = sameCount(true, x + dx, y + dy, dx, dy);
		if (att == 0)
			return false;
		var def = sameCount(false, x, y, -dx, -dy);

		return att > def;
	}

	public function attackRec(f:Bool, x:Int, y:Int, l:Array<Perso>):Bool {
		if (x < 0 || y < 0 || x == Cs.WIDTH || y == Cs.HEIGHT)
			return false;
		var p = level[x][y];
		if (p != null) {
			if (p.hero == f) {
				var i;
				for (i in 0...l.length) {
					if (l[i].x == x && l[i].y == y)
						return true;
				}

				l.push(p);
				if (!attackRec(f, x - 1, y, l))
					return false;
				if (!attackRec(f, x + 1, y, l))
					return false;
				if (!attackRec(f, x, y - 1, l))
					return false;
				if (!attackRec(f, x, y + 1, l))
					return false;
			}
		}
		return true;
	}

	public function doAttack(a) {
		var x = a.x;
		var y = a.y;
		var l = new Array();
		var p = level[x][y];
		if (!attackRec(p.hero, x, y, l))
			l = [p];
		var i;
		for (i in 0...l.length) {
			p = l[i];
			if (p.hero) {
				// Stat : Nombre de héros perdus durant la partie
				stats.l++;
				KadoKadeoManager.kkm.addScore(Cs.HERO_DEATH_POINTS);
			} else {
				// Stat : Comptage et répartition des monstres tués
				stats.k[p.kind]++;
				KadoKadeoManager.kkm.addScore(Cs.MONSTER_POINTS[p.kind]);
			}
			p.destroy();
			level[p.x][p.y] = null;
		}
		if (l.length > 1) {
			// Stat : Liste des groupes de monstres tués
			stats.g.push(l.length - 1);
			KadoKadeoManager.kkm.addScore(KKApi.cmult(Cs.GROUP_BONUS, KKApi.const(l.length - 1)));
		}
		x += a.dx;
		y += a.dy;
		var first = true;
		while (a.att > 0) {
			p = level[x][y];
			p.move(-a.dx, -a.dy, first);
			first = false;
			level[x][y] = null;
			level[p.x][p.y] = p;
			x += a.dx;
			y += a.dy;
			a.att--;
			anims.push(p);
		}
		state = Game.ANIM;
		if (a.dy != 0)
			dmanager.ysort(Cs.PLAN_PERSO);
	}

	public function playerCanAttack() {
		var x, y;
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				var p = level[x][y];
				if (p != null) {
					if (p.hero == false
						&& (playerCheckAttack(x, y, 1,
							0) || playerCheckAttack(x, y, -1, 0) || playerCheckAttack(x, y, 0, 1) || playerCheckAttack(x, y, 0, -1))) {
						return true;
					}
				}
			}
		}
		return false;
	}

	public function monsterAttack() {
		var l = new Array();
		var p, x, y;
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				p = level[x][y];
				if (p != null && p.hero) {
					monsterCheckAttack(x, y, 1, 0, l);
					monsterCheckAttack(x, y, -1, 0, l);
					monsterCheckAttack(x, y, 0, 1, l);
					monsterCheckAttack(x, y, 0, -1, l);
				}
			}
		}
		if (l.length == 0)
			return false;
		doAttack(l[Seed.random(l.length)]);
		return true;
	}

	public function sameCount(h, x, y, dx, dy) {
		var n = 0;
		if (level[x] != null && level[x][y] != null) {
			while (level[x] != null && level[x][y] != null && level[x][y].hero == h) {
				x += dx;
				y += dy;
				n++;
			}
		}
		return n;
	}

	public function checkAttack(x, y) {
		var mc = cases[x][y];
		var p = level[x][y];

		var mmouseX = Num.q(MouseManager.getX());
		var mmouseY = Num.q(MouseManager.getY());

		var localX = Num.q(mmouseX - mc._x);
		var localY = Num.q(mmouseY - mc._y);

		var mx = localX > localY;

		var my = (localX + localY) < Cs.SIZE;

		//--> my n'est jamais true
		var dx = 0;
		var dy = 0;
		if (mx && my) // bas
			dy = -1;
		else if (mx)
			dx = 1; // gauche
		else if (my)
			dx = -1; // droite
		else
			dy = 1; // haut

		var att = 0;
		var def = 0;
		if (p != null) {
			att = sameCount(!p.hero, x + dx, y + dy, dx, dy);
			def = sameCount(p.hero, x, y, -dx, -dy);
		}

		return {
			x: x,
			y: y,
			dx: dx,
			dy: dy,
			att: att,
			def: def,
			can: att > def,
		}
	}

	public function action(prev, out) {
		var x = Std.int(Num.q(MouseManager.getX() - Cs.DX) / Cs.SIZE);
		var y = Std.int(Num.q(MouseManager.getY() - Cs.DY) / Cs.SIZE);
		if (x < 0 || y < 0 || x >= Cs.WIDTH || y >= Cs.HEIGHT) {
			if (out != null) {
				out();
			}
			return;
		}
		prev(x, y);
	}

	public function clearPreview() {
		cursor._visible = false;
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				if (level[x] != null && level[x][y] != null) {
					level[x][y].signal(null);
				}
			}
		}
	}

	public function dir(dx, dy) {
		if (dx < 0)
			return 1;
		if (dx > 0)
			return 0;
		if (dy > 0)
			return 2;
		return 3;
	}

	public function preview(x, y) {
		var p = level[x][y];
		clearPreview();
		if (p == null && state == Game.PLACE) {
			cursor._visible = true;
			cursor.main._visible = true;
			for (a in cursor.attack) {
				a._visible = false;
			}
			Cs.pos(cursor, x, y);
			return;
		}
		if (state != Game.ATTACK || (p != null && p.hero != false))
			return;

		var a = checkAttack(x, y);
		if (a.att == 0 || !a.can)
			return;

		var n = a.def;
		var first = true;
		while (n-- > 0) {
			p = level[x][y];
			p.dir = dir(a.dx, a.dy);
			p.update();
			// Affiche ou non la goutte sur le monstre
			p.signal(a.can ? (first ? Cs.SDEF_FIRST : Cs.SDEF) : Cs.SNODEF);
			first = false;
			x -= a.dx;
			y -= a.dy;
		}
		x = a.x + a.dx;
		y = a.y + a.dy;
		n = a.att;
		while (n-- > 0) {
			p = level[x][y];
			p.dir = dir(-a.dx, -a.dy);
			p.update();
			p.signal(a.can ? Cs.SATT : Cs.SNOATT);
			x += a.dx;
			y += a.dy;
		}
		cursor._visible = true;
		var frame;
		if (a.dx < 0)
			frame = 2; // flèche droite
		else if (a.dx > 0)
			frame = 4; // flèche gauche
		else if (a.dy < 0)
			frame = 3; // flèche bas
		else
			frame = 5; // flèche haut

		cursor.main._visible = false;
		for (a in cursor.attack) {
			a._visible = false;
		}
		cursor.attack[frame - 2]._visible = true;
		Cs.pos(cursor, a.x, a.y);
	}

	public function press(x, y) {
		switch (state) {
			case Game.PLACE:
				place(x, y);
			case Game.ATTACK:
				attack(x, y);
		}
	}

	public function place(x, y) {
		var p = level[x][y];
		if (p != null) {
			return;
		}
		clearPreview();
		level[x][y] = new Perso(this, true, x, y);
		if (!monsterPlace()) {
			nextTurn();
		}
	}

	public function attack(x, y) {
		var p = level[x][y];
		if (p == null || p.hero != false) {
			return;
		}
		var a = checkAttack(x, y);
		if (!a.can) {
			return;
		}
		clearPreview();
		doAttack(a);
	}

	public function nextTurn() {
		var p = playerCanAttack();
		if (!p) {
			if (!monsterAttack())
				state = Game.END;
		} else
			state = Game.ATTACK;
	}

	public function anim() {
		var i = 0;
		while (i < anims.length) {
			if (!anims[i].anim()) {
				anims.splice(i--, 1);
			}
			i++;
		}

		if (anims.length == 0) {
			if (monster_turn) {
				monster_turn = false;
				nextTurn();
			} else {
				monster_turn = true;
				if (!monsterAttack()) {
					nextTurn();
				}
			}
		}
	}

	public function end() {
		var x, y;
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				var p = level[x][y];
				if (p != null && p.cursig != Cs.SMARK) {
					p.signal(Cs.SMARK);
					if (p.hero) {
						// Stat : Nombre de soldats restants en fin de partie
						stats.s++;
						KadoKadeoManager.kkm.addScore(Cs.HERO_KEEP_POINTS);
					} else {
						// Stat : Nombre de monstres restants en fin de partie
						stats.m[p.kind]++;
						KadoKadeoManager.kkm.addScore(Cs.MONSTER_KEEP_POINTS[p.kind]);
					}
					return;
				}
			}
		}
		KadoKadeoManager.kkm.gameOver(stats);
		state = Game.EXIT;
	}

	public function update(delta:Float) {
		if (state != Game.EXIT && state != Game.END)
			updateMouseInput();

		var i = 0;
		while (i < wait.length) {
			var p = wait[i];
			if (p.fx.remove) {
				if (p.mc == null)
					p.attach();
				else
					p.mc.removeMovieClip();
				wait.splice(i--, 1);
			}
			i++;
		}
		if (wait.length != 0)
			return;

		switch (state) {
			case Game.ANIM:
				anim();
			case Game.END:
				end();
		}
	}

	public function destroy():Void {}

	function updateMouseInput():Void {
		if (MouseManager.hasMouseMoved()) {
			action(preview, clearPreview);
		}
		if (MouseManager.isButtonJustReleased(MouseManager.BUTTON_LEFT)) {
			resolvePress();
		}
	}

	function resolvePress() {
		action(press, null);
	}
}
