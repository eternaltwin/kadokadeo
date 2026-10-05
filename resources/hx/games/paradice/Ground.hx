package paradice;

// a penguin (mcPinguin) with the fields Ground.blastPinguin puts on it
class Pinguin extends MC {
	public var step:Int;
	public var t:Float;

	// _parent.piou, set by the script of its body when it is the chick
	public var piou(get, never):Bool;

	function get_piou():Bool {
		return clip.piou;
	}
}

// a grenade (Part with the square it was in at the previous frame)
class Grenade extends Part {
	public var px:Null<Int>;
	public var py:Null<Int>;
}

// Ground.mt of the original: the row of penguins under the line, the balls they carry and push into the grid, the
// specials (flame thrower, bomb, grenades) and the end of the game
class Ground {
	static var SPEED = 8;
	static var SPECIAL_PROBA = [0, 0, 0, 0, 0, 1, 2, 2];

	var ty:Float;
	var cMove:Float;
	var sens:Int;

	public var step:Int;

	var dx:Int;

	var y:Float;
	var timer:Float;

	var pList:Array<Pinguin>;
	var bList:Array<{x:Int, b:Ball}>;
	var gList:Array<Grenade>;

	var special:Null<Int>;

	var portrait:MC;
	var bomb:Phys;

	#if debug
	// test mode (modes/paradice.js): the special of every fill (null: the game's random)
	public var testSpecial:Null<Int>;
	#end

	public function new() {
		y = Cs.MD;
		dx = 0;
		cMove = 0;
		sens = 0;
		initPinguins();
		y = Cs.mch;
		ty = y;
	}

	function initPinguins() {
		pList = new Array();
		for (x in 0...Cs.XMAX) {
			var mc = Cs.game.dm.add(new Pinguin("pinguin"), Game.DP_GROUND);
			mc._x = Cs.ML + (x + 0.5) * Cs.SQ;
			mc._y = Cs.mcw;
			pList.push(mc);
		}
	}

	public function initLoad() {
		fill();
		launchAnim("take");
		step = 1;
		timer = 4;
		ty = Cs.FILL_LEVEL;
		y = Cs.FILL_LEVEL;
	}

	public function loading() {
		move();

		switch (step) {
			case 0:
				if (Math.abs(ty - y) < 0.5) {
					fill();
					launchAnim("take");
					step++;
					timer = 4;
				}
			case 1:
				timer -= Timer.tmod;
				if (timer < 0) {
					ty = Cs.PLAY_LEVEL;
					step++;
				}
			case 2:
				if (Math.abs(ty - y) < 0.5) {
					Cs.game.initStep(3);
				}
		}
	}

	function move() {
		var dy = ty - y;
		dy = Cs.mm(-SPEED, dy, SPEED);
		y += Math.min(dy, dy * 0.9 * Timer.tmod);
		updateBallPos();
	}

	public function control() {
		switch (step) {
			case 0:
				if (KeyboardManager.isDown(KeyboardManager.UP) || KeyboardManager.isDown(KeyboardManager.SPACE)
					|| Cs.game.playTimer < 0) {
					validate();

					return;
				}

				sens = checkInput();
				if (sens != 0) {
					cMove = 0;
					step = 1;
					launchAnim("pass");
				}

			case 1:
				cMove += Cs.GROUND_CONTROL_SPEED * Timer.tmod;
				if (cMove > 1) {
					dx += sens;
					cMove--;
					while (dx > Cs.XMAX)
						dx -= Cs.XMAX;
					while (dx < 0)
						dx += Cs.XMAX;
					sens = checkInput();
					if (sens == 0 || Cs.game.playTimer < 0) {
						step = 0;
						cMove = 0;
						launchAnim("catch");
					} else {
						launchAnim("pass");
					}
				}
				updateBallPos();

			case 2:
				move();
				var dy = Math.abs(ty - y);
				if (dy < Cs.SQ) {
					for (i in 0...bList.length) {
						var o = bList[i];
						var x = Std.int(Cs.sMod(o.x + dx, Cs.XMAX));

						for (y in 0...Cs.YMAX) {
							// (every square of the column: on an empty one, Flash sets nothing)
							var b = Cs.game.cell(x, y);
							if (b != null) {
								b.dy = -(Cs.SQ - dy);
								b.updatePos();
							}
						}
					}
				}

				if (dy < 0.5) {
					updateGrid();
					Cs.game.initStep(0);
				}

			case 3: // BURN
				var x = getX(bList[0].x);
				// (the flames only change the picture: the visual random)
				for (i in 0...4) {
					var p = new Part(Cs.game.dm.attach("partFlame", Game.DP_PART));
					p.x = Cs.ML + (x + 0.7) * Cs.SQ + (Seed.randVfx() * 2 - 1) * 2;
					p.y = Cs.PLAY_LEVEL - (24 + Seed.randVfx() * 10);
					p.vx = (Seed.randVfx() * 2 - 1);
					p.vy = -(8 + Seed.randVfx() * 16);
					p.frict = null;
					p.timer = 10 + Seed.randVfx() * 20;
					p.scale = 100 + Seed.randVfx() * 50;
					p.root._xscale = p.scale;
					p.root._yscale = p.scale;
				}
				timer -= Timer.tmod;
				var lim = 20;
				if (timer < lim) {
					var c = timer / lim;
					for (y in 0...Cs.YMAX) {
						var b = Cs.game.cell(x, y);
						if (b != null) {
							b.root._xscale = c * 100;
							b.root._yscale = b.root._xscale;
							if (timer < 0) {
								b.kill();
							}
						}
					}
					if (timer < 0) {
						portrait.play();
						launchAnim("peace");
						Cs.game.initStep(0);
					}
				}

			case 4: // BOMB
				if (bomb.vy > 0) {
					var x = getX(bList[0].x);
					var y = Std.int((Cs.MD - bomb.y) / Cs.SQ);
					var b = Cs.game.cell(x, y);
					if (b != null || y < 1) {
						nuke(x, y);

						bomb.kill();
						portrait.play();
						Cs.game.initStep(1);
					}
				}

			case 5: // GRENADES
				updateGrenades();
		}

		for (i in 0...pList.length) {
			var p = pList[i];
			p._rotation *= Math.pow(0.8, Timer.tmod);
		}
	}

	function launchAnim(label:String) {
		for (i in 0...bList.length) {
			var o = bList[i];
			var x = getX(o.x);
			var p = pList[x];
			p.gotoAndPlay(label);
			if (label == "pass") {
				p._rotation = sens * 30;
			}
			if (label == "catch") {
				// (sens is 0 here unless the time ran out during a move: the penguin is not tilted)
				p._rotation = -sens * 30;
			}
		}
	}

	function validate() {
		if (special != null) {
			spawnPortrait(special);
			step = 3 + special;
			Cs.game.countSpecial(special);
		}
		var ball = bList[0].b;
		switch (special) {
			case 0: // FLAME
				//
				launchAnim("burn");
				ball.kill();
				timer = 40;

			case 1: // BOMB
				launchAnim("launch");
				bomb = new Phys(Cs.game.dm.attach("bomb", Game.DP_PART));
				bomb.weight = 0.5;
				bomb.x = ball.root._x;
				bomb.y = ball.root._y;
				bomb.vy = -28;
				ball.kill();

			case 2: // GRENADE
				launchAnim("launch");
				gList = new Array();
				for (i in 0...3) {
					var g = new Grenade(Cs.game.dm.attach("grenade", Game.DP_PART));
					// (where they fall decides what blows up: the gameplay random; their spin is the visual one)
					g.weight = 0.5 + Seed.rand() * 0.2;
					g.x = ball.root._x;
					g.y = ball.root._y;
					g.vx = (Seed.rand() * 2 - 1) * 8;
					g.vy = -(14 + Seed.rand() * 6);
					g.vr = (Seed.randVfx() * 2 - 1) * 12;
					g.frict = 1;
					gList.push(g);
				}
				ball.kill();
			default:
				launchAnim("launch");
				step = 2;
				ty = Cs.MD;
		}
	}

	function spawnPortrait(n:Int) {
		var frame = n * 10 + 1;
		var mc = Cs.game.dm.attach("pyro", Game.DP_CACHE);
		var x = getX(bList[0].x);
		var sens = (x < Cs.XMAX * 0.5) ? 1 : 0;
		mc._x = sens * Cs.mch;
		mc._y = Cs.mch;
		mc._xscale = (sens * 2 - 1) * 100;
		portrait = mc;
		if (pList[x].piou)
			frame++;
		mc.sub("sub").gotoAndStop(frame);
	}

	function updateBallPos() {
		for (i in 0...bList.length) {
			var o = bList[i];
			var b = o.b;

			var px = Cs.sMod((dx + o.x + cMove * sens), Cs.XMAX) + 0.5;
			var ox = b.root._x;
			var oy = b.root._y;
			b.root._x = Cs.ML + px * Cs.SQ;
			// (the cosine is rounded: a bomb or grenades start from this height, see Cs.q)
			b.root._y = y - (Cs.SQ * 0.5 + Cs.q(Math.cos((1 - cMove) * 3.14)) * 4);
			if (pList[getX(o.x)].piou) {
				b.root._y += 7;
			}
			// the ball went round the row, or is placed for the first time (fill attaches it at 0, 0): not drawn sliding
			// across the screen (Flash shows it at once)
			if (Math.abs(b.root._x - ox) > Cs.SQ * Cs.XMAX * 0.5 || Math.abs(b.root._y - oy) > Cs.SQ * 2)
				b.root.teleport();
			// CLONES
			if (px >= Cs.XMAX - 0.5) {
				if (b.cl == null) {
					b.genClone();
				}
				b.cl._x = b.root._x - Cs.XMAX * Cs.SQ;
				b.cl._y = b.root._y;
			} else {
				if (b.cl != null) {
					b.removeClone();
				}
			}
		}
	}

	function checkInput():Int {
		if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
			return -1;
		}
		if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
			return 1;
		}
		return 0;
	}

	function fill() {
		special = null;
		bList = new Array();

		// SPECIAL
		var isSpecial = Seed.random(25) == 0;
		#if debug
		if (testSpecial != null)
			isSpecial = true;
		#end
		if (isSpecial) {
			special = SPECIAL_PROBA[Seed.random(SPECIAL_PROBA.length)];
			#if debug
			if (testSpecial != null)
				special = testSpecial;
			#end
			var b = new Special();
			b.sid = special;
			b.setSkin(b.root);
			bList.push({x: Seed.random(Cs.XMAX), b: b});
			return;
		}

		// NORMAL
		var max = 3;
		if (Seed.random(20) == 0)
			max = 1;
		if (Seed.random(1000) == 0)
			max = Cs.XMAX;

		for (i in 0...max) {
			var b = new Gem();
			var x = 0;
			while (true) {
				var flBreak = true;
				x = Seed.random(Cs.XMAX);
				for (n in 0...bList.length) {
					if (bList[n].x == x) {
						flBreak = false;
						break;
					}
				}
				if (flBreak)
					break;
			}
			bList.push({x: x, b: b});
		}
	}

	function updateGrid() {
		while (bList.length > 0) {
			var o = bList.pop();
			var x = Std.int(Cs.sMod(o.x + dx, Cs.XMAX));
			var y = Cs.YMAX - 1;
			while (y >= 0) {
				var b = Cs.game.cell(x, y);

				if (b != null) {
					b.setPos(b.x, b.y + 1);
					b.dy = 0;
					b.updatePos();
				}
				y--;
			}
			Cs.game.setCell(x, 0, o.b);
			o.b.setPos(x, 0);
			o.b.updatePos();
		}
	}

	function getX(x:Int):Int {
		return Std.int(Cs.sMod(x + dx, Cs.XMAX));
	}

	public function initBlastPinguin() {
		for (x in 0...pList.length) {
			var p = pList[x];
			p.t = 10 + x * 7;
			p.step = 0;
		}
	}

	public function blastPinguin() {
		var x = 0;
		while (x < pList.length) {
			var pg = pList[x];
			pg.t -= Timer.tmod;
			if (pg.t < 0) {
				switch (pg.step) {
					case 0:
						pg.gotoAndPlay("hoNo");
						pg.t = 30;
						pg.step++;
					case 1:
						var mc = Cs.game.dm.attach("onde", Game.DP_PART);
						mc._x = pg._x;
						mc._y = pg._y;
						// (the pixels only change the picture: the visual random)
						for (i in 0...32) {
							var p = new Part(Cs.game.dm.attach("partPixel", Game.DP_PART));
							var a = -Seed.randVfx() * 3.14;
							var ca = Math.cos(a);
							var sa = Math.sin(a);
							var sp = 0.5 + Seed.randVfx() * 5;
							var ray = 8;
							p.x = pg._x + ca * ray;
							p.y = pg._y + sa * ray;
							p.vx = ca * sp;
							p.vy = sa * sp * 2;
							p.weight = 0.1 + Seed.randVfx() * 0.2;

							p.timer = 10 + Seed.randVfx() * 30;
							p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
							p.fadeType = 0;
						}

						//
						pg.removeMovieClip();
						pList.splice(x--, 1);
						if (pList.length == 0)
							Cs.game.initStep(11);
				}
			}
			x++;
		}
	}

	function updateGrenades() {
		var i = 0;
		while (i < gList.length) {
			var g = gList[i];
			var r = 5;

			var nx = Std.int((g.x - Cs.ML) / Cs.SQ);
			var ny = Std.int((Cs.MD - g.y) / Cs.SQ);

			if (g.x < Cs.ML + r || g.x > Cs.mcw - (r + Cs.ML)) {
				g.x = Cs.mm(Cs.ML + r, g.x, Cs.mcw - (r + Cs.ML));
				g.vx *= -1;
				g.vr = (Seed.randVfx() * 2 - 1) * 12;
			}

			if (g.vy > 0) {
				if (g.px != nx && Cs.game.cell(nx, ny) != null) {
					g.vx *= -1;
					g.vr = (Seed.randVfx() * 2 - 1) * 12;
				}

				if (g.py != ny && Cs.game.cell(nx, ny) != null) {
					// (Std.random(1) is always 0: a grenade never bounces off a ball; the draw is kept)
					if (Seed.random(1) == 0) {
						blast(g.px, g.py);
						g.kill();
						gList.splice(i--, 1);
					} else {
						g.vy *= -0.8;
						g.vr = (Seed.randVfx() * 2 - 1) * 12;
					}
				}
			}

			g.px = nx;
			g.py = ny;

			if (g.y > Cs.mch + r) {
				g.kill();
				gList.splice(i--, 1);
			}
			i++;
		}
		if (gList.length == 0) {
			portrait.play();
			Cs.game.initStep(1);
		}
	}

	function blast(x:Null<Int>, y:Null<Int>) {
		for (dx in -1...2) {
			for (dy in -1...2) {
				var b = Cs.game.cell(x + dx, y + dy);
				if (b != null) {
					b.kill();
				}
			}
		}

		// BLAST
		var mc = Cs.game.dm.attach("explode", Game.DP_PART);
		mc._x = (Cs.ML + x * Cs.SQ);
		mc._y = (Cs.MD - y * Cs.SQ);
		mc._xscale = 50;
		mc._yscale = 50;
	}

	function nuke(x:Int, y:Int) {
		var i = 0;
		while (i < Cs.game.bList.length) {
			var b = Cs.game.bList[i];
			var dx = b.x - x;
			var dy = b.y - y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist < 2.8) {
				// (the shards only change the picture: the visual random)
				for (n in 0...3) {
					var p = new Part(Cs.game.dm.attach("partIce", Game.DP_PART));
					var sp = 2;
					p.x = b.root._x + (Seed.randVfx() * 2 - 1) * 10;
					p.y = b.root._y + (Seed.randVfx() * 2 - 1) * 10;
					//
					var ddx = p.x - (Cs.ML + x * Cs.SQ);
					var ddy = p.y - (Cs.MD - y * Cs.SQ);
					var a = Math.atan2(ddy, ddx);
					var ca = Math.cos(a);
					var sa = Math.sin(a);
					//
					p.vx = ca * dist * sp;
					p.vy = sa * dist * sp;
					p.root.gotoAndPlay(Seed.randomVfx(19) + 1);
					p.timer = 10 + Seed.randVfx() * 50;
					p.root._xscale = dist * 40;
					p.root._rotation = 90 + a / 0.0157;
				}

				//
				b.kill();
				i--;
			}
			i++;
		}
		//
		var mc = Cs.game.dm.attach("explode", Game.DP_PART);
		mc._x = (Cs.ML + x * Cs.SQ);
		mc._y = (Cs.MD - y * Cs.SQ);
	}
}
