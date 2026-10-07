package julianus;

// the symbol "pic": the frame chosen by the code (id + 1) and the "sub" child the code drives
class PicMC extends MC {
	public var sub:MC;

	public function new() {
		super();
		_totalframes = 6;
	}

	override public function gotoAndStop(f:Int):Void {
		super.gotoAndStop(f);
		for (c in children.copy())
			c.removeMovieClip();
		sub = null;
		switch (_currentframe) {
			case 1:
				// spike ball (its own sub, never driven)
				attach(new MC("pic0"));
			case 2:
				// spinning spikes: the sub under the hub
				sub = attach(new SpikesMC());
				attach(new MC("pic1Hub"));
			case 3:
				// the orbit and its ball
				attach(new MC("pic2Orbit"));
				sub = attach(new MC("pic2Ball"));
				var m = Data.PIC2_SUB;
				sub._x = m[0];
				sub._y = m[1];
			default:
				// the bonuses: nested timelines looping on 40 frames
				var b = attach(new MC("bonus" + (_currentframe - 4)));
				b.playing = true;
		}
	}
}

// pic frame 2's "sub" (sprite 35): frame 1 the spikes (stop()), frame 2 sprite 34, whose frame 1 turns its "blur" at
// random and whose frame 2 goes back to frame 1 (a new turn every Flash frame), "blur" playing its 2 pictures in turn
class SpikesMC extends MC {
	var spikes:MC;

	public var blur:BlurMC;

	public function new() {
		super();
		_totalframes = 2;
		spikes = attach(new MC("pic1Spikes"));
	}

	override public function gotoAndStop(f:Int):Void {
		var was = _currentframe;
		super.gotoAndStop(f);
		if (_currentframe == was)
			return;
		if (_currentframe == 2) {
			spikes._visible = false;
			blur = attach(new BlurMC());
		} else {
			spikes._visible = true;
			blur.removeMovieClip();
			blur = null;
		}
	}
}

// sprite 34: its frame scripts (blur._rotation = random(360) - 180, then gotoAndPlay(_currentframe - 1)) give the
// blur a new random turn on every Flash frame, the one it is placed on included (visual random)
class BlurMC extends MC {
	public var blur:MC;

	public function new() {
		super();
		_totalframes = 2;
		playing = true;
		blur = attach(new MC("pic1Blur"));
		blur.playing = true;
		turn();
	}

	override function onFrame():Void {
		// (frame 2: gotoAndPlay(1), whose script turns the blur again)
		gotoAndPlay(1);
		turn();
	}

	function turn():Void {
		blur._rotation = Seed.randomVfx(360) - 180;
	}
}

class Pic {
	var id:Int;
	var game:Game;
	var mc:PicMC;

	public var px:Float;
	public var py:Float;

	var a:Float;
	var rspeed:Float;

	public function new(g:Game, i:Int, x:Float, y:Float) {
		id = i;
		a = Seed.random(360) / Math.PI;
		game = g;
		rspeed = 0;
		mc = game.dmanager.add(new PicMC(), Const.PLAN_PIC);
		mc.gotoAndStop(id + 1);
		px = x;
		py = y;
		mc._x = x;
		mc._y = y;
	}

	function getBonus(k:Int):Void {
		var p = game.dmanager.attach("fxBonus", Const.PLAN_PART);
		p.playing = true;
		p.removeAt = 15;
		p._x = px;
		p._y = py;
		mc.removeMovieClip();
		game.stats.bo[k]++;
		game.addScore(KKApi.val(Const.SCORES[k]));
		game.bcount--;
	}

	public function update(deltax:Float):Bool {
		px += deltax;
		mc._x = px;

		var sizex = 10;
		if (id == 2)
			sizex += 50;
		else if (id == 1)
			sizex += 10;

		if (px < -sizex) {
			mc.removeMovieClip();
			return false;
		}
		var i;
		var bl = game.bulles;
		var len = bl.length;
		var ray = (id == 1) ? 50 : ((id >= 3) ? 34 : 30);
		var sr = (id >= 2) ? 13 : 7;

		var dpx = 0.0, dpy = 0.0;
		if (id == 2) {
			a += Game.TMOD / 50;
			dpx = Const.q(Math.cos(a)) * 50;
			dpy = Const.q(Math.sin(a)) * 50;
			px += dpx;
			py += dpy;
			mc.sub._x = dpx;
			mc.sub._y = dpy;
		}

		// (len read once: a collision returns at once)
		i = 0;
		while (i < len) {
			var b = bl[i];
			var dx = b.px - px;
			var s = b.size / 2;
			if (dx < ray + s && dx > -ray - s) {
				var dy = b.py - py;
				var d = Math.sqrt(dx * dx + dy * dy);
				if (d < s + sr) {
					switch (id) {
						case 3, 4, 5:
							getBonus(id - 3);
						default:
							b.separate();
							game.kills.push(this);
					}
					return false;
				} else if (d < s + ray) {
					if (id == 1) {
						var p = Game.TMOD * 10 / (d * d);
						b.vx += dx * p;
						b.vy += dy * p;
					}
					rspeed += 2 * Game.TMOD;
					if (rspeed > 25)
						rspeed = 25;
				}
			}
			i++;
		}
		px -= dpx;
		py -= dpy;
		if (rspeed > 1 && id == 1) {
			mc.sub.gotoAndStop((rspeed == 25) ? 2 : 1);
			if (rspeed != 25)
				mc.sub._rotation += rspeed * Game.TMOD;
			rspeed *= Const.POW_095;
		}
		return true;
	}

	public function updateKill(deltax:Float):Bool {
		px += deltax;
		var p = Const.POW_070;
		mc._xscale *= p;
		mc._yscale *= p;
		if (mc._xscale <= 10) {
			mc.removeMovieClip();
			return false;
		}
		mc._x = px;
		return true;
	}
}
