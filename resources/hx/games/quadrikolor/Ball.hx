package quadrikolor;

// Ball.mt: a ball (or the ship, i == 0) of the table and its clip
class Ball extends PhysicObj {
	public var state:Int;
	// (never initialized in the original: undefined, NaN once used; the roll is then gotoAndStop("NaN"), which does
	// nothing: the roll animation plays on)
	var frame:Float = Math.NaN;
	var vitRot:Float;

	public var mc:MC;

	var game:Game;

	public var ship:Bool;
	public var id:Int;

	var ox:Float;
	var oy:Float;

	public var inhole:Bool = false;
	public var colflag:Bool = false;
	// (undefined before the first shot in the original; reset at each ignition, before any collision)
	public var bande:Int = 0;
	public var bandeLast:Bool = false;

	public function new(g:Game, i:Int, px:Float, py:Float) {
		super();
		dx = 0;
		dy = 0;
		game = g;
		ship = (i == 0);
		id = i - 1;
		x = px;
		y = py;
		ox = x;
		oy = y;
		r = Const.BALL_RAY;
		mass = ship ? Const.SHIP_MASS : Const.BALL_MASS;
		// (attach("ball") + initColor: the clip of the ball baked in its colour, see quadrikolor_assets.py)
		mc = game.dmanager.attach(ship ? "ship" : "ball" + id, Const.PLAN_BALL);
		mc._x = x;
		mc._y = y;

		state = 0;
		vitRot = 0;
	}

	function dist(tx:Float, ty:Float):Float {
		var dx = tx - x;
		var dy = ty - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function hole():Bool {
		if (!colflag)
			return false;
		var l = ship ? Const.SHIP_LIMIT : Const.LIMIT;
		if (dist(0, Const.MIN_Y) <= l) {
			inhole = true;
			ox = 0;
			oy = Const.MIN_Y;
		} else if (dist(0, 300) <= l) {
			inhole = true;
			ox = 0;
			oy = 300;
		} else if (dist(300, Const.MIN_Y) <= l) {
			inhole = true;
			ox = 300;
			oy = Const.MIN_Y;
		} else if (dist(300, 300) <= l) {
			inhole = true;
			ox = 300;
			oy = 300;
		}
		return inhole;
	}

	public function update(t:Float):Bool {
		if (inhole) {
			var s:Float;
			if (dist(ox, oy) > 10) {
				s = mc._xscale * Const.q(Math.pow(0.97, t));
				x = x * 0.95 + 0.05 * ox;
				y = y * 0.95 + 0.05 * oy;
			} else {
				s = mc._xscale * Const.q(Math.pow(0.95, t));
				x += Seed.random(3) - 1;
				y += Seed.random(3) - 1;
				if (s < 5)
					return false;
			}
			mc._rotation += t * Math.sqrt(100 - s);
			mc._xscale = s;
			mc._yscale = s;
			mc._x = x;
			mc._y = y;

			// GFX
			if (state != 3) {
				state = 3;
				mc.gotoAndPlay("death");
			}
			return true;
		} else {
			var dx = x - ox; // ox - x;
			var dy = y - oy; // oy - y;
			ox = x;
			oy = y;
			mc._x = x;
			mc._y = y;

			// GFX
			var dist = Math.sqrt(dx * dx + dy * dy);

			if (ship) {
				if (game.state != Game.CHOOSE_WAY) {
					vitRot *= Math.pow(0.95, Timer.tmod);
					mc._rotation += vitRot;
				} else {
					vitRot = 0;
				}

				// if( dist > 8 ){
				var frame = 1 + Std.int(Math.max(0, (10 - dist)));
				// (frame 11 of the trail is transparent and its frame 12 removes it: the clip of a ship that does not
				// move is not attached, nothing changes on screen)
				if (frame < 11) {
					var q = game.dmanager.attach("queue", Const.PLAN_LINE);
					q._x = x;
					q._y = y;
					q._rotation = mc._rotation;
					q.gotoAndPlay(Std.string(frame));
				}
				// }
			} else {
				if (dist < 1) {
					initState(0);
				} else if (dist < 3) {
					initState(1);
				} else {
					initState(2);
				}

				switch (state) {
					case 1:
						mc._rotation *= 0.9;
					case 2: // ROLL
						mc._rotation = Math.atan2(dy, dx) / 0.0174;

						frame = (frame + dist * 0.2) % 10;
						mc.gotoAndStop(Std.string(50 + frame));
					case _:
				}
			}
			return (dist / t >= Const.EPSILON);
		}
	}

	override public function onCollide(trg:PhysicObj) {
		colflag = true;
		if (ship) {
			// (Math.random(): only turns the picture of the ship and its aiming line, visual random)
			vitRot += Seed.randVfx() * 20;
			if (trg == null) {
				if (!bandeLast)
					bande++;
			} else
				bandeLast = true;
		}
	}

	function initState(n:Int) {
		if (n == state)
			return;
		switch (state) {
			case 2:
				mc._rotation -= 90;
			case _:
		}
		var old = state;
		state = n;
		switch (state) {
			case 0:
				mc.gotoAndPlay("base");
			case 1:
				if (old == 2) {
					mc.gotoAndPlay("animMove");
				} else {
					mc.gotoAndPlay("move");
				}
			case 2:
				mc.gotoAndPlay("roll");
				// (this.dx / this.dy: the speed of the last collision, not the move of this frame)
				mc._rotation = Math.atan2(this.dy, this.dx) / 0.0174;
			case _:
		}
	}

	public function destroy() {
		mc.removeMovieClip();
	}
}
