package spiroule;

// Chain.hx of the original: a row of balls rolling on the spiral. list[0] is the back of the chain (the highest
// position, `pos`), the next balls are Cs.ec closer to the hole each. Game.chains: the first chain is the back one.
class Chain {
	public var list:Array<Ball>;
	public var pos:Float;
	public var vit:Float;
	public var combo:Null<Int>;
	public var comboTimer:Null<Float>;
	public var cci:Null<Int>;

	public function new(?index:Null<Int>) {
		if (index == null)
			index = Game.me.chains.length;
		Game.me.chains.insert(index, this);
		list = [];
		pos = 1;
		vit = 0;
	}

	public function update() {
		var index = getIndex();
		// (a chain joined by the one behind it earlier in this frame is still updated, from the copy of
		// Game.updateChains: its index is null, null + 1 is NaN in Flash: no next chain. It moves the balls it gave away)
		var next = index == null ? null : Game.me.chains[index + 1];
		var top = pos - list.length * Cs.ec;
		if (top < 0.2)
			Game.me.danger();

		if (comboTimer != null) {
			comboTimer -= Timer.tmod;
			if (comboTimer < 0) {
				combo = null;
				comboTimer = null;
			}
		}

		// COMBO SPEEDER
		var flCombo = false;
		var couple:Array<Ball> = null;
		if (next != null) {
			var spd = 0.00055;
			var b1 = next.list[0];
			var b2 = list[list.length - 1];
			if (b1 != null && b2 != null && b1.col == b2.col && b1.col != 4) {
				flCombo = true;
				comboTimer = 20;
				next.vit += spd * Timer.tmod;
				vit -= spd * 0.5 * Timer.tmod;
				couple = [b1, b2];
				b1.incFlash(0.1);
				b2.incFlash(0.1);
			}
		}

		// FIRST
		if (index == 0) {
			// SPEED START
			if (Game.me.flStart) {
				if (top > 0.6)
					vit -= 0.004;
				else
					Game.me.flStart = false;
			}

			// BLOCKAGE
			if (top > 1.1) {
				comboTimer = null;
				combo = null;
				if (vit > 0)
					vit = 0;
			}

			// AVANCE
			if (comboTimer == null) {
				var mult = 1.0;
				// (Game.FL_TEST is false in the released game: no SPACE key to speed up)
				var lim = 0.9;
				if (Game.me.lastPos > lim)
					mult += (Game.me.lastPos - lim) * 10;
				vit += (-Game.me.speed * mult - vit) * 0.25 * Timer.tmod;
			}

			// SPAWN
			var to = 0;
			while (pos < Cs.COEF_START) {
				pos += Cs.ec;
				var b = new Ball(true);
				b.chain = this;
				list.unshift(b);
				if (to++ > 10)
					break;
			}
		}

		// HACK CORRECTION
		if (list.length == 0) {
			kill();
			return;
		}

		// JOIN
		// (Cs.getPos(top) of the original: unused)
		// (no next chain: next.pos is undefined in Flash, the test is false)
		if (next != null && top < next.pos) {
			var dif = next.pos - top;
			pos += dif;
			var v = Math.max(vit, next.vit);
			var index = list.length - 1;

			join(next);
			vit = v;
			if (flCombo)
				cci = index;
			#if debug
			Game.me.stats.joins++;
			#end
		}

		// MOVE
		vit *= Cs.q(Math.pow(0.97, Timer.tmod));
		pos += vit * Timer.tmod;
		updatePos();

		// ECLAIR
		if (couple != null)
			couple[0].fxLink(couple[1]);

		// GAMEOVER
		if (top + Cs.ec < Cs.COEF_END) {
			Game.me.initGameOver();
		}
	}

	public function updatePos() {
		var p = pos;
		var i = 0;
		var l = list;
		while (i < l.length) {
			var b = l[i];
			i++;
			b.setPos(p);
			p -= Cs.ec;
			b.maj();
		}
	}

	public function addBall(?b:Ball) {
		if (b == null)
			b = new Ball(true);
		b.chain = this;
		list.push(b);
	}

	public function insert(b:Ball, trg:Ball) {
		var index = trg.getIndex();

		//
		if (trg.col == 4) {
			// a black ball is kicked out of the chain with the speed of the shot; the shot takes its place
			trg.from = trg.pos;
			trg.unchain();
			Game.me.shots.push(trg);
			trg.vx = b.vx;
			trg.vy = b.vy;
			trg = null;
			#if debug
			Game.me.stats.blackKick++;
			#end
		} else {
			if (Cs.hMod(trg.getLauncherAngle() - b.getLauncherAngle(), 3.14) > 0)
				index++;
		}

		b.chain = this;
		// (index is never null here: trg is in this chain)
		list.insert(index, b);
		Game.me.shots.remove(b);
		if (trg != null)
			pos += Cs.ec * 0.5;
		b.pos = pos + index * Cs.ec;

		#if debug
		Game.me.stats.inserts++;
		#end
		// GET LINE
		checkCombo(index);

		//
		for (b in list)
			b.flInsert = true;
	}

	// list[n].col (out of the list: undefined in Flash, never equal)
	inline function colAt(n:Int):Null<Int> {
		return n >= 0 && n < list.length ? list[n].col : null;
	}

	public function checkCombo(index:Int) {
		// (index is a ball of the list: the one inserted, or the last one before a join)
		if (list[index] == null)
			return;
		var color = list[index].col;
		var lim = [index, index];
		var to = 0;
		for (i in 0...2) {
			var sens = i * 2 - 1;
			while (true) {
				var n = lim[i] + sens;
				if (colAt(n) == color && color != 4)
					lim[i] += sens;
				else
					break;
				if (to++ > 100) {
					break;
				}
			}
		}

		var id = lim[0];
		var length = 1 + lim[1] - lim[0];

		if (length >= Cs.COMBO_LIMIT) {
			// DESTRUCTION
			var mx = 0.0;
			var my = 0.0;
			for (i in 0...length) {
				var ball = list[id];
				mx += ball.x;
				my += ball.y;
				ball.explode();
			}
			mx /= length;
			my /= length;

			// SEPARATION
			if (list.length > id) {
				splice(id);
				#if debug
				Game.me.stats.splits++;
				#end
			}

			// SCORE
			var sc = KKApi.cmult(Cs.SCORE_BALL, KKApi.const(length));
			if (combo != null) {
				sc = KKApi.cmult(sc, KKApi.const(combo));

				var mc = Game.me.dm.attach("mcMulti", Game.DP_FX);
				mc._x = mx;
				mc._y = my;
				// mc._val = "x" + combo: the text field of smc
				mc.clip.get("smc").addChild(new MultiText("x" + combo));
				mc._xscale = mc._yscale = 100 + combo * 20;
				Game.me.glowMulti(mc, Cs.COLORS_DARK[color]);
			} else {
				combo = 1;
			}

			// COMBO
			comboTimer = 20;
			combo++;
			#if debug
			if (combo > Game.me.stats.maxCombo)
				Game.me.stats.maxCombo = combo;
			#end

			Game.me.addScore(KKApi.val(sc));
		}
	}

	public function splice(id:Int) {
		var a = list.splice(id, list.length - id);
		// (getIndex() null, a chain no longer in Game.chains: NaN + 1, Array.insert(NaN) inserts at 0 in Flash)
		var gi = getIndex();
		var chain = new Chain(gi == null ? 0 : gi + 1);
		chain.pos = a[0].pos;
		while (a.length > 0)
			chain.addBall(a.shift());

		// AUTODESTRUCTION
		if (list.length == 0)
			kill();
	}

	public function join(c:Chain) {
		for (b in c.list)
			b.chain = this;
		list = list.concat(c.list);
		c.kill();
	}

	public function getIndex():Null<Int> {
		var id = 0;
		for (ch in Game.me.chains) {
			if (ch == this)
				return id;
			id++;
		}
		return null;
	}

	public function kill() {
		Game.me.chains.remove(this);
	}
}
