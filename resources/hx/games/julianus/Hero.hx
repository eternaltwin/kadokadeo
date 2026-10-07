package julianus;

// the symbol "hero": its "body" (5 frames, turned by the code)
class HeroMC extends MC {
	public var body:MC;

	public function new() {
		super();
		body = attach(new MC("body"));
		var m = Data.BODY;
		body._x = m[0];
		body._y = m[1];
	}
}

// the symbol "blow": one frame per direction (60), each moving the 3 puffs, which play their 10 frames from the
// attach and stop (they stay the same clips when the code changes the frame of blow)
class BlowMC extends MC {
	public var puffs:Array<MC>;

	public function new() {
		super();
		_totalframes = 60;
		puffs = [];
		for (a in ["puff", "puff", "puffEnd"]) {
			var p = attach(new MC(a));
			p.playing = true;
			p.stopAt = 10;
			puffs.push(p);
		}
		place();
	}

	override public function gotoAndStop(f:Int):Void {
		super.gotoAndStop(f);
		place();
	}

	function place():Void {
		var m = Data.BLOW;
		for (i in 0...3) {
			var o = ((_currentframe - 1) * 3 + i) * 5;
			var p = puffs[i];
			p._x = m[o];
			p._y = m[o + 1];
			p._xscale = m[o + 2];
			p._yscale = m[o + 3];
			p._rotation = m[o + 4];
		}
	}
}

// a particle: {> MovieClip, x, y, vx, vy, s} of the original
class Part {
	public var mc:MC;
	public var x:Float;
	public var y:Float;
	public var vx:Float;
	public var vy:Float;
	public var s:Float;

	public function new(mc:MC) {
		this.mc = mc;
	}
}

class Hero {
	static var pow = 0.15;

	var game:Game;
	var blow:BlowMC;
	var eyes:MC;
	var mc:HeroMC;

	public var px:Float;
	public var py:Float;
	public var tx:Float;
	public var ty:Float;
	public var ang:Float;

	var frame:Float;
	var speed:Float;

	public var action:Bool;

	var partpow:Float;

	var parts:Array<Part>;

	function moyAng(a:Float, b:Float):Float {
		if (Math.abs(a - b) > Math.PI) {
			if (b < a)
				b += Math.PI * 2;
			else
				b -= Math.PI * 2;
		}
		a = (a + b) / 2;
		while (a <= Math.PI)
			a += Math.PI * 2;
		while (a > Math.PI)
			a -= Math.PI * 2;
		return a;
	}

	public function new(g:Game) {
		action = false;
		game = g;
		frame = 0;
		speed = 0;
		ang = 0;
		partpow = 0;
		parts = new Array();
		mc = game.dmanager.add(new HeroMC(), Const.PLAN_HERO);
		eyes = game.dmanager.attach("eyes", Const.PLAN_HERO);
		// tx = game.mc._xmouse; ty = game.mc._ymouse; px = tx + 1; py = ty: the mouse is known at the first frame
		// (the replay records it there), see initMouse
	}

	public function initMouse(x:Float, y:Float):Void {
		tx = x;
		ty = y;
		px = tx + 1;
		py = ty;
	}

	// (the particles are only pictures: visual random)
	function updateParts():Void {
		var action = this.action || KeyboardManager.isDown(KeyboardManager.SPACE);
		partpow = (partpow + (action ? (pow * 30) : 0)) / 2;
		if (action && Seed.randomVfx(2) == 0) {
			var p = new Part(game.dmanager.attach("part", Const.PLAN_PART, Game.K * 4));
			var a = ang + (Seed.randomVfx(100) - 50) / 200;
			p.mc.gotoAndStop(1 + Seed.randomVfx(p.mc._totalframes));
			p.x = px + Math.cos(a) * 20;
			p.y = py + Math.sin(a) * 20;
			p.vx = Math.cos(a) * partpow;
			p.vy = Math.sin(a) * partpow;
			p.s = 200;
			parts.push(p);
		}

		var i = 0;
		var acc = Const.POW_097;
		while (i < parts.length) {
			var p = parts[i];
			p.s += 20 * Game.TMOD;
			p.mc._rotation += 20 * Game.TMOD;
			p.mc._alpha -= 5 * Game.TMOD;
			if (p.mc._alpha < 0) {
				p.mc.removeMovieClip();
				parts.splice(i--, 1);
			} else {
				p.x += p.vx * Game.TMOD;
				p.y += p.vy * Game.TMOD;
				p.vx *= acc;
				p.vy *= acc;
				p.mc._x = p.x;
				p.mc._y = p.y;
				p.mc._xscale = p.s;
				p.mc._yscale = p.s;
			}
			i++;
		}
	}

	function adiff(a1:Float, a2:Float):Float {
		while (a1 < 0)
			a1 += Math.PI * 2;
		while (a2 < 0)
			a2 += Math.PI * 2;
		while (a1 >= 2 * Math.PI)
			a1 -= Math.PI * 2;
		while (a2 >= 2 * Math.PI)
			a2 -= Math.PI * 2;
		var a = Math.abs(a1 - a2);
		if (a < Math.PI)
			return a;
		return Math.PI * 2 - a;
	}

	public function update():Void {
		var ray = 10;

		var s = 5;
		if (KeyboardManager.isDown(KeyboardManager.LEFT) && tx > 0)
			tx -= Game.TMOD * s;
		if (KeyboardManager.isDown(KeyboardManager.RIGHT) && tx < 300)
			tx += Game.TMOD * s;
		if (KeyboardManager.isDown(KeyboardManager.UP) && ty > 0)
			ty -= Game.TMOD * s;
		if (KeyboardManager.isDown(KeyboardManager.DOWN) && ty < 300)
			ty += Game.TMOD * s;

		var ttx = tx;
		var tty = ty;

		var action = this.action || KeyboardManager.isDown(KeyboardManager.SPACE);

		if ((blow != null) != action) {
			if (action) {
				blow = game.dmanager.add(new BlowMC(), Const.PLAN_HERO);
				game.dmanager.over(eyes);
			} else {
				blow.removeMovieClip();
				blow = null;
			}
		}

		var mind = 50.0;
		var targb:Bulle = null;
		var pp = Const.q(pow * Math.pow((game.speed - game.speed_delta) / game.speed, 3));
		for (i in 0...game.bulles.length) {
			var b = game.bulles[i];
			var dx = b.px - px;
			var dy = b.py - py;
			var d = Math.sqrt(dx * dx + dy * dy);
			if (action && d < 50 + b.size / 2) {
				var a = Const.q(Math.atan2(dy, dx));
				if (adiff(a, ang) < Math.PI / 4) {
					b.vx += Game.TMOD * Const.q(Math.cos(a)) * pp;
					b.vy += Game.TMOD * Const.q(Math.sin(a)) * pp;
				}
			}
			d -= b.size;
			if (d < mind) {
				mind = d;
				targb = b;
			}
		}
		var tang = Const.q(Math.atan2(tty - py, ttx - px));

		if (targb != null)
			tang = Const.q(Math.atan2(targb.py - py, targb.px - px));

		var x = ttx + Const.q(Math.cos(ang + Math.PI)) * ray;
		var y = tty + Const.q(Math.sin(ang + Math.PI)) * ray;
		var p = Const.POW_090;
		var ox = px;
		var oy = py;
		px = px * p + x * (1 - p);
		py = py * p + y * (1 - p);

		ang = moyAng(ang, tang);

		ox -= px;
		oy -= py;
		speed = Math.sqrt(ox * ox + oy * oy);
		frame += Math.min(Math.max(0.3, Math.sqrt(speed)) * Game.TMOD, 1);
		var body = mc.body;
		body.gotoAndStop(1 + Std.int(frame) % body._totalframes);
		body._rotation = ang * 180 / Math.PI;
		var f;
		if (ang < 0)
			f = 61 + Std.int(ang * 30 / Math.PI);
		else
			f = 1 + Std.int(ang * 30 / Math.PI);

		updateParts();

		eyes.gotoAndStop(f);
		if (blow != null)
			blow.gotoAndStop(f);
		eyes._x = px;
		eyes._y = py;
		if (blow != null) {
			blow._x = px;
			blow._y = py;
		}
		mc._x = px;
		mc._y = py;
	}

	public function destroy():Void {}
}
