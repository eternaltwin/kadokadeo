package bactery;

import kado.KadoKadeoManager;
import mt.Timer;
import mt.deepnight.Lib;

class PanelSprite extends ASprite {
	public var p:ASprite;
	public var flGo:Bool;
}

typedef ReproductionInfo = {
	var b:Bille;
	var b2:Bille;
	var r:Int;
	var p:Part;
}

class Level {
	var fupdate:Void->Void;
	var game:Game;

	public var tbl:Array<Array<Bille>>;

	var groups:Array<Array<Bille>>;
	var rList:Array<ReproductionInfo>;

	var index:Int;
	var step:Int;
	var timer:Float;

	var panel:PanelSprite;

	public function new(g:Game) {
		game = g;
	}

	public function init():Void {
		tbl = new Array();
		for (x in 0...Const.WIDTH) {
			tbl[x] = new Array();
			for (y in 0...Const.HEIGHT) {
				var t:Int;
				do {
					t = Seed.random(4);
				} while ((x > 0 && t == tbl[x - 1][y].t) || (y > 0 && t == tbl[x][y - 1].t));
				var b = new Bille(game, t);
				b.setPos(x, y);
			}
		}

		var i = 0;
		while (i < 4) {
			var t = tbl[Seed.random(Const.WIDTH)][Seed.random(Const.HEIGHT)];
			if (t.t < Const.ID_BONUS) {
				t.setSkin(Const.ID_MONSTER);
				t.mc.gotoAndStop(Const.ID_MONSTER + 1 + Seed.randomVfx(4));
			} else
				i--;
			i++;
		}

		var nbonus = 1 + Seed.random(5);
		i = 0;
		while (i < nbonus) {
			var t = tbl[Seed.random(Const.WIDTH)][Seed.random(Const.HEIGHT)];
			if (t.t < Const.ID_BONUS)
				t.setSkin(Const.ID_BONUS);
			else
				i--;
			i++;
		}
	}

	public function swap(b1:Bille, b2:Bille):Void {
		game.dmanager.over(b1.mc);
		game.dmanager.over(b2.mc);
		fupdate = function() {
			var r1 = b1.moveTo(b2.x, b2.y);
			var r2 = b2.moveTo(b1.x, b1.y);
			if (!r1 && !r2) {
				var p1 = {x: b1.x, y: b1.y};
				b1.setPos(b2.x, b2.y);
				b2.setPos(p1.x, p1.y);
				swapDone();
			}
		};
	}

	function makeGroupsRec(b:Bille, x:Int, y:Int, g:Array<Bille>):Void {
		var t = b.t;
		b.group = g;
		g.push(b);
		if (x > 0) {
			b = tbl[x - 1][y];
			if (b.t == t && b.group == null)
				makeGroupsRec(b, x - 1, y, g);
		}
		if (x + 1 < Const.WIDTH) {
			b = tbl[x + 1][y];
			if (b.t == t && b.group == null)
				makeGroupsRec(b, x + 1, y, g);
		}
		if (y > 0) {
			b = tbl[x][y - 1];
			if (b.t == t && b.group == null)
				makeGroupsRec(b, x, y - 1, g);
		}
		if (y + 1 < Const.HEIGHT) {
			b = tbl[x][y + 1];
			if (b.t == t && b.group == null)
				makeGroupsRec(b, x, y + 1, g);
		}
	}

	function makeGroups():Bool {
		for (x in 0...Const.WIDTH)
			for (y in 0...Const.HEIGHT)
				tbl[x][y].group = null;
		groups = new Array();
		var exists = false;
		for (x in 0...Const.WIDTH) {
			for (y in 0...Const.HEIGHT) {
				var g = tbl[x][y];
				if (g != null && g.group == null) {
					var grp = new Array();
					makeGroupsRec(g, x, y, grp);
					if (grp.length > 1)
						groups.push(grp);
					exists = true;
				}
			}
		}
		return exists;
	}

	function walls():Void {
		for (g in groups) {
			if (g.length > 2 && g[0].t < Const.ID_BONUS) {
				for (b in g) {
					game.flash(b.mc);
					b.setSkin(Const.ID_WALL);
					for (_ in 0...10) {
						var p = game.newPart("partFlushee");
						p.skin.loop = true;
						var a = Seed.randVfx() * 6.28;
						var ca = Math.cos(a);
						var sa = Math.sin(a);
						var r = KadoKadeoManager.S(14 + Seed.randVfx() * 2);
						p.x = b.px + ca * r;
						p.y = b.py + sa * r;
						p.vitx = ca * r * 0.05;
						p.vity = sa * r * 0.05;
						p.timer = 6 + Seed.randVfx() * 12;
						p.scale = 50 + Seed.randVfx() * 80;
						p.init();
					}
				}
			}
		}
	}

	function reproduce(max:Int):Bool {
		var dirs = [
			{x: 1, y: 0, id: 0},
			{x: 0, y: 1, id: 1},
			{x: -1, y: 0, id: 2},
			{x: 0, y: -1, id: 3}
		];
		var changed = false;
		var changeable = false;
		for (x in 0...Const.WIDTH) {
			for (y in 0...Const.HEIGHT) {
				var b = tbl[x][y];
				if (b.t >= Const.ID_MONSTER) {
					var d = Lib.shuffle(dirs, Seed.random);
					for (direction in d) {
						var dx = x + direction.x;
						var dy = y + direction.y;
						if (dx < 0 || dx >= Const.WIDTH || dy < 0 || dy >= Const.HEIGHT)
							continue;
						var b2 = tbl[dx][dy];
						if (b2.t < Const.ID_WALL) {
							changeable = true;
							if (b.group == null || max == 0 || Seed.random(Std.int(Math.sqrt(b.group.length))) != 0)
								break;
							max--;
							changed = true;
							b2.setSkin(b.t);
							b2.group = null;
							rList.push({
								b: b,
								b2: b2,
								r: direction.id,
								p: null
							});
							break;
						}
					}
				}
			}
		}
		if (max > 0 && !changed && changeable)
			return reproduce(max);
		return changeable;
	}

	function swapDone():Void {
		fupdate = null;
		makeGroups();
		walls();

		rList = new Array();
		reproduce(5);
		if (!reproduce(0)) {
			initDestroy();
			return;
		}
		initSplash();
	}

	function initDestroy():Void {
		step = 0;
		index = 0;
		timer = 0;
		fupdate = destroyLevel;
		attachPanel();
	}

	function destroyLevel():Void {
		timer -= Timer.tmod;
		if (timer < 0) {
			while (true) {
				var flBreak = false;
				var x = index % Const.WIDTH;
				var y = Std.int(index / Const.HEIGHT);
				var t = tbl[x][y];

				switch (step) {
					case 0:
						if (t.t == Const.ID_MONSTER) {
							t.score();
							flBreak = true;
						}
					case 1:
						if (t.t == Const.ID_WALL) {
							t.score();
							flBreak = true;
						}
					case 2:
						if (t.t < 4) {
							t.score();
							flBreak = true;
						}
					case 3:
						if (t.t == Const.ID_BONUS) {
							t.score();
							flBreak = true;
						}
					case 4:
						flBreak = true;
				}

				index++;
				var max = Const.WIDTH * Const.HEIGHT;
				if (index >= max) {
					index = 0;
					step++;
					flBreak = true;
					timer = 10;
					if (step > 3) {
						panel.flGo = true;
						fupdate = null;
						KadoKadeoManager.kkm.gameOver(game.stats);
					} else {
						if (panel != null)
							panel.flGo = true;
						attachPanel();
					}
				}

				if (flBreak)
					break;
			}
			timer += 1.5;
			if (step == 3)
				timer += 16;
			if (step == 1)
				timer += 4;
		}
	}

	function attachPanel():Void {
		panel = cast game.dmanager.attach("mcPanel", Const.PLAN_PANEL);
		panel.gotoAndStop(step + 1);
		panel._x = KadoKadeoManager.I(300);
		panel._y = KadoKadeoManager.I(300);
	}

	function initSplash():Void {
		index = 0;
		fupdate = splash;
		for (info in rList) {
			info.b2.mc._alpha = 0;
			var p = game.newPart("animBlob");
			p.skin.play();
			p.skin.onFrame.set(21, function() {
				p.timer = 5;
				p.fadeLimit = 5;
			});
			p.skin.removeOnFrame = 29;
			p.x = info.b.px;
			p.y = info.b.py;
			p.fadeTypeList = [1];
			p.init();
			p.skin._rotation = info.r * 90;
			p.skin._alpha = 0;
			info.p = p;
		}
	}

	function splash():Void {
		index++;

		if (index <= 5) {
			for (info in rList) {
				info.p.skin._alpha = index * 20;
				info.b.mc._alpha = 100 - info.p.skin._alpha;
			}
		}

		if (index == 20) {
			for (info in rList) {
				info.b.mc._alpha = 100 - (25 - index) * 20;
				info.b2.mc._alpha = 100 - (25 - index) * 20;
			}
		}

		if (index > 20) {
			for (info in rList) {
				info.b.mc._alpha = 100 - (25 - index) * 20;
				info.b2.mc._alpha = 100 - (25 - index) * 20;
				if (index == 21)
					info.b.mc.gotoAndStop(Const.ID_MONSTER + 1 + Seed.randomVfx(4));
				if (index == 23)
					info.b2.mc.gotoAndStop(Const.ID_MONSTER + 1 + Seed.randomVfx(4));
			}
		}

		if (index == 12) {
			var ray = KadoKadeoManager.I(4);
			for (info in rList) {
				var x = (info.b.px + info.b2.px) * 0.5;
				var y = (info.b.py + info.b2.py) * 0.5;

				for (_ in 0...4) {
					var p = game.newPart("partMonster");
					var a = Seed.randVfx() * 6.28;
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					var sp = KadoKadeoManager.S(0.2 + Seed.randVfx() * 0.8);
					p.x = x + ca * ray;
					p.y = y + sa * ray;
					p.vitx = ca * sp;
					p.vity = sa * sp;
					p.timer = 10 + Seed.randVfx() * 10;
					p.init();
				}
			}
		}

		if (index == 30) {
			game.lock = false;
			fupdate = null;
		}
	}

	public function update():Void {
		if (fupdate != null)
			fupdate();
	}
}
