package pacifik;

interface Anim {
	public var onEnd:Void->Void;
	public function play():Bool;
	public function clean():Void;
}

// a canon slides in (1 pixel per Flash frame, after a random delay)
class CanonIn implements Anim {
	public var onEnd:Void->Void;

	var c:Canon;
	var i:Float;
	var delay:Float;
	var max:Float;

	public function new(c:Canon) {
		this.c = c;
		i = 0.0;
		// (the delay decides when the canon can fire and be touched: the gameplay random)
		delay = Seed.random(20);
		max = Const.CANON_WIDTH;
	}

	public function play() {
		if (delay-- > 0)
			return false;
		c.moveX(1);

		if (i++ >= max) {
			return true;
		}
		return false;
	}

	public function clean() {}
}

// the barrel turns towards the target in 15 Flash frames
class MoveFireAnim implements Anim {
	public var onEnd:Void->Void;

	var c:Canon;
	var i:Int;
	var max:Int;
	var r:Float;
	var a:Float;

	public function new(c:Canon, target:Canon) {
		this.c = c;
		i = 0;
		max = 15;
		r = 0.0;
		a = 0.0;

		// (atan2(dx, dy): the angle from the vertical, as written)
		var at = Const.q(Math.atan2(target.mc.x - c.mc.x, target.mc.y - c.mc.y)) / Math.PI * 180;
		if (c.invert) {
			a = 90 + at + this.c.mc.smc._rotation;
		} else {
			a = 90 - at - this.c.mc.smc._rotation;
		}

		r = if (Math.floor(a) == 0) 0 else a / max;
	}

	public function play() {
		// (the canon removed meanwhile: Flash sets the rotation of nothing)
		if (c.mc != null) {
			if (c.invert)
				this.c.mc.smc._rotation -= r;
			else
				this.c.mc.smc._rotation += r;
		}

		if (++i >= max) {
			return true;
		}
		return false;
	}

	public function clean() {}
}

// the recoil of the barrel along its direction, in 15 Flash frames
class FireAnim implements Anim {
	public var onEnd:Void->Void;

	var c:Canon;
	var i:Int;
	var max:Int;
	var a:Float;
	var inc:Float;
	var maxW:Float;
	var radRot:Float;
	var rot:Float;

	public function new(c:Canon) {
		this.c = c;
		i = 0;
		max = 15;
		a = 90;
		inc = 180 / max;
		// (a canon already removed: undefined values, NaN)
		var m = this.c.mc;
		maxW = m != null ? m.smcWidth() / 2 : Math.NaN;
		radRot = m != null ? m.smc._rotation * Math.PI / 180 : Math.NaN;
		rot = m != null ? m.smc._rotation : Math.NaN;
	}

	public function play() {
		var rad = a * Math.PI / 180;

		var xrad = Const.q(Math.cos(radRot)) * maxW;
		var yrad = Const.q(Math.sin(radRot)) * maxW;

		var xr = xrad * Const.q(Math.cos(rad));
		var yr = yrad * Const.q(Math.cos(rad));

		var m = this.c.mc;
		if (m != null) {
			if (rot == 0)
				m.smc._x = xr;
			else {
				m.smc._x = xr;
				m.smc._y = yr;
			}
		}

		a += inc;
		if (++i >= max) {
			return true;
		}
		return false;
	}

	public function clean() {}
}

// a touched canon slides out (2 pixels per Flash frame), then goes
class CanonOut implements Anim {
	public var onEnd:Void->Void;

	var c:Canon;
	var i:Float;
	var max:Float;

	public function new(c:Canon) {
		this.c = c;
		i = 0.0;
		// (a canon without shield was removed just before (Canon.removeMe): c.mc._width is undefined, max NaN, and this
		// animation never ends: it keeps moving nothing)
		max = c.mc != null ? Math.ceil(c.mc.width() / 2) : Math.NaN;
	}

	public function play() {
		c.moveX(-2);

		if (i++ >= max) {
			return true;
		}
		return false;
	}

	public function clean() {
		c.clean();
	}
}

// "CAUTION !!": comes down and appears, then shrinks away (Phys fadeType 5)
class Beware implements Anim {
	public var onEnd:Void->Void;

	var mc:MC;
	var i:Float;
	var max:Float;

	public function new(game:Game) {
		mc = game.dm.attach("beware", Const.DP_CANON, Game.K);
		mc._x = Const.HEIGHT / 2;
		mc._y = -15;
		mc._alpha = 0;
		i = 0.0;
		max = 20;
		onEnd = ending;
	}

	public function play() {
		mc._y++;
		mc._alpha += 5;

		if (i++ >= max) {
			return true;
		}
		return false;
	}

	function ending() {
		var p = new Phys(mc);
		p.timer = 20;
		p.fadeLimit = 15;
		p.fadeType = 5;
	}

	public function clean() {}
}
