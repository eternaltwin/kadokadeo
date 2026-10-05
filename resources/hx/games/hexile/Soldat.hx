package hexile;

import hexile.Socle.SoldierMC;

class Soldat extends Phys {
	public var flSuicide:Bool;
	public var flDec:Bool;
	public var id:Int;
	public var team:Int;
	public var step:Null<Int>;

	var hex:Socle;

	public var jh:Float;

	var coef:Float;

	var dx:Float;
	var dy:Float;

	var sx:Float;
	var sy:Float;
	var ex:Float;
	var ey:Float;

	var wait:Null<Float>;
	var ty:Float;
	var speed:Float;

	var shade:MC;

	var mc:SoldierMC;

	public function new(team:Int) {
		mc = new SoldierMC();
		// (attached by the code: not a clip of a timeline)
		mc.showNow = false;
		Game.me.dm.add(mc, Game.DP_SOLDAT);
		super(mc);

		Game.me.soldats.push(this);
		setTeam(team);

		jh = 80;
	}

	public function setTeam(n:Int) {
		this.team = n;
		// root.gotoAndStop(team + 1); root.smc.stop()
		mc.setTeam(team);
	}

	override public function update() {
		switch (step) {
			case 0:
				updatePlay();
			case 1:
				updateJump();
			case 2:
				updateLand();
			case 3:
				updateBack();
			default:
		}

		super.update();
	}

	// PLAY (unused by the game: Game.initPlay has it commented out)
	public function initStartPos() {
		step = 0;
		var ray = 9.0;
		while (true) {
			ray -= 0.1;
			var flBreak = true;
			var cx = (Seed.randVfx() * 2 - 1);
			x = Cs.mcw * 0.5 + cx * (10 + id * 5);
			ty = Cs.mch - (12 + Seed.randVfx() * (10 + (1 - Math.abs(cx)) * 20));
			for (sol in Game.me.soldats) {
				var dx = sol.x - x;
				var dy = sol.ty - ty;
				if (sol != this && Math.sqrt(dx * dx + dy * dy) < ray) {
					flBreak = false;
					break;
				};
			}
			if (flBreak)
				break;
		}

		y = Cs.mch + 30;
		speed = 2 + Seed.randVfx() * 3;
		wait = 0;
	}

	function updatePlay() {
		if (wait != null) {
			wait += mt.Timer.tmod;
			if (wait > id * 2)
				wait = null;
		} else {
			y -= speed * mt.Timer.tmod;
			if (y <= ty) {
				y = ty;
			}
		}
	}

	// JUMP
	public function initJump(flag:Bool, ?trg:Socle) {
		if (trg == null)
			trg = Game.me.hex;
		hex = trg;

		flSuicide = flag;

		flDec = true;

		coef = -id * 0.1;
		step = 1;

		var h = trg;

		sx = x;
		sy = y;

		var tx:Float = Cs.getX(h.x, h.y);
		var ty:Float = Cs.getY(h.x, h.y) - h.height;
		if (flSuicide) {
			jh = 30;

			// (where the soldier falls into the sea is a picture only: visual random)
			var dirs = [[1, 0], [1, 1], [0, 1], [-1, 0], [0, -1]];
			var d = dirs[Seed.randomVfx(dirs.length)];

			tx = Cs.getX(Game.CX + d[0], Game.CY + d[1]) + (Seed.randVfx() * 2 - 1) * Cs.WW * 0.5;
			ty = Cs.getY(Game.CX + d[0], Game.CY + d[1]) + (Seed.randVfx() * 2 - 1) * Cs.HH * 0.5;
		}

		dx = tx - sx;
		dy = ty - sy;

		shade = Game.me.sdm.attach(new MC("shade"));
		// (shade._x = -100 in the original, under the soldier at its first update: placed there at once so that
		// the display does not slide it from off screen)
		shade.teleport(sx, sy);

		// root.smc.gotoAndStop(4)
		mc.gotoAndStop(5 + team);
	}

	function updateJump() {
		if (coef > 0 && flDec) {
			flDec = false;
			Game.me.castle.base.prevFrame();
		}

		coef = Math.min(coef + 0.05 * mt.Timer.tmod, 1);
		var c = Math.max(0, coef);

		var ox = x;
		var oy = y;

		x = sx + c * dx;
		y = sy + c * dy;

		shade._x = x;
		shade._y = y;

		y -= Math.sin(c * 3.14) * jh;
		if (coef == 1) {
			shade.removeMovieClip();
			if (!flSuicide) {
				land(hex);
			} else {
				#if debug
				Game.me.stats.plouf++;
				#end
				fxPlouf();
				kill();
			}
		}

		// QUEUE
		var dx = x - ox;
		var dy = y - oy;
		var mc = Game.me.rdm.attach(new MC("ray"));
		mc.playing = true;
		// (frame 9: removeMovieClip)
		mc.removeAt = 9;
		mc._x = ox;
		mc._y = oy;
		mc._xscale = Math.sqrt(dx * dx + dy * dy);
		mc._rotation = Math.atan2(dy, dx) / 0.0174;
	}

	// BACK
	public function goBack() {
		step = 3;
	}

	function updateBack() {
		y += speed;
		if (y > Cs.mch + 20)
			kill();
	}

	// LAND
	public function land(hex:Socle) {
		step = 2;
		Game.me.grid[hex.x][hex.y].incSoldat(1);
		kill();
	}

	function updateLand() {}

	function fxPlouf() {
		// (Math.random: the splash is a picture only)
		var max = 18;
		for (i in 0...max) {
			var a = -Seed.randVfx() * 3.14;
			var sp = 0.3 + Seed.randVfx() * 1;
			var cr = 3;
			var p = new Phys(Game.me.dm.attach("drip", Game.DP_PARTS));
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.x = x + p.vx * cr;
			p.y = y + p.vy * cr;
			p.timer = 10 + Seed.randVfx() * 30;
			p.frict = 0.9;
			p.updatePos();
		}

		var mc = Game.me.dm.attach("onde", Game.DP_BG);
		// (frame 22: removeMovieClip)
		mc.removeAt = 22;
		mc._x = x;
		mc._y = y;
	}

	//
	override public function kill() {
		Game.me.soldats.remove(this);
		super.kill();
	}
}
