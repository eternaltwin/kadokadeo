package cerealpunk;

// Animator.mt: the moves of the cereals (rise of a new row, taken by the cook, thrown, falling), the bounce of the
// column a throw lands in, the explosions and the particles
class Animator {
	var game:Game;

	var ups:Array<{l:Legume, dy:Float}>;

	public var gets:Array<Legume>;

	var puts:Array<{l:Legume, dy:Float, delta:Float}>;
	var pList:Array<Part>;
	// (null entries: Game.explode gives the off-screen combo two nulls, explodeLegume(null) pushes them)
	var explodes:Array<Legume>;
	var amort:Array<{l:Legume, y:Float}>;
	// (undefined until the first bounce: NaN, the bounce computations then do nothing)
	var amort_max:Float = Math.NaN;
	var amort_y:Float = Math.NaN;
	// (undefined until the first throw, -1 after a bounce: legumes[amort_x] is undefined, nothing bounces)
	var amort_x:Int = -1;

	public function new(g:Game) {
		game = g;
		ups = [];
		gets = [];
		puts = [];
		pList = [];
		amort = [];
		explodes = [];
	}

	public function moveUp(l:Legume) {
		if (l == null)
			return;
		for (i in 0...ups.length)
			if (ups[i].l == l) {
				ups[i].dy += 30;
				return;
			}
		ups.push({
			l: l,
			dy: 30
		});
	}

	public function getLegume(l:Legume) {
		gets.push(l);
	}

	public function putLegume(l:Legume, x:Int, y:Int, i:Int) {
		l.mc._x = x * 30 + Const.DX;
		l.mc._y = Const.YLIMIT - i * 30;
		l.mc._visible = true;
		var ty = y * 30 + Const.DY;
		amort_x = x;
		puts.push({l: l, dy: ty - l.mc._y, delta: 30});
	}

	public function gravity(l:Legume) {
		puts.push({l: l, dy: 30, delta: 15});
	}

	public function explodeLegume(l:Legume) {
		if (l != null)
			l.initExplode();
		explodes.push(l);
	}

	public function destroyLegume(l:Legume) {
		if (l == null)
			return;
		l.initDestroy();
		explodes.push(l);
	}

	public function locked(expl:Bool):Bool {
		return ups.length != 0 || gets.length != 0 || puts.length != 0 || amort.length != 0 || (expl && explodes.length != 0);
	}

	public function newPart(link:String):Part {
		var mc = game.dmanager.add(new Part(link), Const.PLAN_POP);
		mc.vx = 0;
		mc.vy = 0;
		pList.push(mc);
		return mc;
	}

	public function main() {
		var i = 0;
		var flag = puts.length != 0 || amort.length != 0 || explodes.length != 0;

		while (i < explodes.length) {
			var l = explodes[i];
			// (null: undefined.explodeMain() is undefined in Flash, taken out)
			if (l == null || !l.explodeMain())
				explodes.splice(i--, 1);
			i++;
		}

		var udelta = 10 * Timer.tmod;
		i = 0;
		while (i < ups.length) {
			var m = ups[i];
			m.dy -= udelta;
			m.l.mc._y -= udelta;
			if (m.dy < 0) {
				m.l.mc._y -= m.dy;
				ups.splice(i--, 1);
			}
			i++;
		}

		var doput = puts.length != 0;
		i = 0;
		while (i < puts.length) {
			var m = puts[i];
			var pdelta = m.delta * Timer.tmod;
			var k = (m.dy > 0) ? 1 : -1;
			m.dy -= pdelta * k;
			m.l.mc._y += pdelta * k;
			if (m.dy * k < 0) {
				m.l.mc._y += m.dy;
				puts.splice(i--, 1);
			}
			i++;
		}
		if (puts.length == 0) {
			if (doput) {
				for (i in 0...Const.HEIGHT) {
					var l = amort_x >= 0 && amort_x < Const.WIDTH ? game.level.legumes[amort_x][i] : null;
					if (l != null)
						amort.push({l: l, y: l.mc._y});
				}
				amort_max = 5;
				amort_y = 0;
				amort_x = -1;
			}

			var amort_end = false;
			amort_y += Timer.tmod * amort_max;
			if (amort_y * amort_max > 0 && Math.abs(amort_y) >= Math.abs(amort_max)) {
				amort_y = amort_max;
				amort_max *= -0.5;
				if (Math.abs(amort_max) < 1) {
					amort_y = 0;
					amort_end = true;
				}
			}
			for (i in 0...amort.length) {
				var m = amort[i];
				m.l.mc._y = m.y + amort_y;
			}
			if (amort_end)
				amort = [];
		}

		if (flag && amort.length == 0 && puts.length == 0 && explodes.length == 0)
			game.explode();

		var gdelta = 30 * Timer.tmod;
		i = 0;
		while (i < gets.length) {
			var l = gets[i];
			l.mc._y -= gdelta;
			if (l.mc._y < Const.YLIMIT - 30) {
				switch (l.id) {
					case Const.BULLE:
						explodeLegume(l);
					case Const.BONUS1:
						game.stats.b1++;
						game.addScore(KKApi.val(Const.C1000));
						explodeLegume(l);
					case Const.BONUS2:
						game.stats.b2++;
						game.addScore(KKApi.val(Const.C5000));
						explodeLegume(l);
					default:
						game.hero.getLegume(l);
				}
				gets.splice(i--, 1);
			}
			i++;
		}

		i = 0;
		while (i < pList.length) {
			var mc = pList[i];
			if (mc.weight != null) {
				mc.vy += mc.weight;
			}
			if (mc.frict != null) {
				mc.vx *= mc.frict;
				mc.vy *= mc.frict;
			}
			mc._x += mc.vx * Timer.tmod;
			mc._y += mc.vy * Timer.tmod;

			if (mc.vr != null) {
				if (mc.fvr != null)
					mc.vr *= mc.fvr;
				// (twice, like the original)
				mc._rotation += mc.vr * Timer.tmod;
				mc._rotation += mc.vr * Timer.tmod;
			}

			if (mc.timer != null) {
				mc.timer -= Timer.tmod;
				if (mc.timer <= 0) {
					mc.removeMovieClip();
					pList.splice(i--, 1);
				} else if (mc.timer <= 10) {
					var sc:Null<Float> = mc.scale;
					if (sc == null)
						sc = 100;

					switch (mc.ft) {
						case 0:
							mc._yscale = sc * mc.timer / 10;
						case 1:
							mc._alpha = mc.timer * 10;
						default:
							mc._xscale = sc * mc.timer / 10;
							mc._yscale = mc._xscale;
					}
				}
			}
			i++;
		}
	}
}
