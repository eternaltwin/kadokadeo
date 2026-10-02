package manda;

import manda.SnakeGfx.Body;

typedef Pt = {x:Float, y:Float};

class Snake {
	// gfx logic
	public var gfx:SnakeGfx;
	public var tete:Pic;
	public var collide_point:Pt;
	public var queue:Array<Pt>;

	var game:Game;
	var dmanager:Plans;

	// intern
	var eat:Float;
	var old_ang:Float;
	var dist:Float;
	var dx:Float;
	var dy:Float;
	var redraw:Bool;

	// available
	public var base_speed:Float;
	public var eat_speed:Float;
	public var x:Float;
	public var y:Float;
	public var ang:Float;
	public var speed:Float;
	public var len:Int;
	public var delta_ang:Float;

	// objects
	public var blue:Bool;
	public var blue_flag:Bool;

	// the head as the last draw left it (frame 1 with the eyes / 2 blue, playhead of the eyes o1 o2, transform)
	var teteFrame:Int;
	var eyeFrame:Int;
	var eyePlaying:Bool;
	var teteRot:Float;
	var teteScale:Float;

	public function new(game:Game, dman:Plans, pos:Pt) {
		this.game = game;
		dmanager = dman;
		gfx = dman.add(new SnakeGfx(), Cs.PLAN_SNAKE);
		tete = dman.add(new Pic("tete"), Cs.PLAN_SNAKE);
		teteFrame = 1;
		eyeFrame = 1;
		eyePlaying = false;
		teteRot = 0;
		teteScale = 100;
		base_speed = 1;
		eat_speed = 1;
		queue = new Array();
		x = pos.x;
		y = pos.y;
		dx = 0;
		dy = 0;
		ang = 0;
		eat = 0;
		old_ang = -100;
		delta_ang = Cs.SNAKE_DEFAULT_TURN;
		speed = Cs.SNAKE_DEFAULT_SPEED;
		len = Cs.SNAKE_DEFAULT_LENGTH;
		dist = 0;
		redraw = true;
		blue = false;
		blue_flag = false;

		for (i in 0...50)
			queue.push(pos);
	}

	// timelines of the head (start of a step): the eyes blink (frames 2 to 12, back to 1 where they stop)
	public function advanceTimeline() {
		if (teteFrame == 1 && eyePlaying) {
			eyeFrame++;
			if (eyeFrame > 12) {
				eyeFrame = 1;
				eyePlaying = false;
			}
			tete.show(eyeFrame);
		}
	}

	public function endQueuePos(delta:Int):Pt {
		return queue[Std.int(Math.max(0, queue.length - len * Cs.SNAKE_QUEUE_ELT_SIZE + delta))];
	}

	public function move(bounds:{left:Float, top:Float, right:Float, bottom:Float}):Bool {
		var tmod = Timer.tmod;
		var hit = false;

		// (visual random: VFX seed)
		if (Seed.randomVfx(Math.round(100 / tmod)) == 0) {
			// o1.play(); o2.play() (no eyes on the blue head)
			if (teteFrame == 1)
				eyePlaying = true;
		}

		if (eat > 0) {
			eat -= eat_speed * tmod / 2;
			redraw = true;
		}

		if (old_ang != ang) {
			ang -= Std.int(ang / (Math.PI * 2)) * Math.PI * 2;
			old_ang = ang;
			dx = Cs.qt(Math.cos(ang));
			dy = Cs.qt(Math.sin(ang));
		}

		var speed = this.speed * tmod * base_speed;

		var esize = Cs.SNAKE_QUEUE_ELT_SIZE;
		var ds = Math.min(esize * 1.5 + len, 3 * esize);
		var col_pt = {x: x + dx * ds, y: y + dy * ds};
		var ncols = Std.int(speed / esize) + 1;

		while (ncols > 0) {
			ncols--;
			var delta_speed = ((ncols > 0) ? esize : (speed % esize));
			col_pt.x += dx * delta_speed;
			col_pt.y += dy * delta_speed;
			if (!blue && gfx.hit(col_pt.x, col_pt.y)) {
				eat = 0;
				hit = true;
				break;
			}
		}

		x += dx * speed;
		y += dy * speed;

		dist += speed / esize;
		var curp = {x: x, y: y};
		while (dist >= 1) {
			dist--;
			queue.push(curp);
			redraw = true;
		}

		var px = col_pt.x;
		var py = col_pt.y;
		if (px < bounds.left || py < bounds.top || px > bounds.right || py > bounds.bottom) {
			eat = 0;
			hit = true;
		}
		collide_point = col_pt;
		return hit;
	}

	public function draw() {
		var scale = Math.min(10, len + 3) / 20;

		tete._x = x;
		tete._y = y;
		teteRot = ang;
		tete._rotation = ang * 180 / Math.PI;
		teteScale = 30 + 70 * scale;
		tete._xscale = teteScale;
		tete._yscale = teteScale;

		if (!redraw)
			return;

		redraw = false;

		var b = new Body(drawQueue(scale, 8, 4), drawQueue(scale, 8, 0), drawQueue(scale, 5, 0), getBorderColor(), getColor());
		gfx.current = b;
		var f = (blue && blue_flag) ? 2 : 1;
		if (f != teteFrame) {
			teteFrame = f;
			// back to frame 1: new eyes, stopped at their frame 1
			eyeFrame = 1;
			eyePlaying = false;
			tete.show(f == 2 ? 13 : 1);
		}
	}

	public function getColor() {
		if (blue && blue_flag)
			return Cs.COLOR_SNAKE_INVINCIBLE;
		return Cs.COLOR_SNAKE_DEFAULT;
	}

	public function getBorderColor() {
		if (blue && blue_flag)
			return Cs.COLOR_SNAKE_BORDER_INVINCIBLE;
		return Cs.COLOR_SNAKE_BORDER_DEFAULT;
	}

	// curveTo from the newest point to the end of the tail, a piece of tail (4 points of the queue) per curve, thicker
	// near the head, thicker again where a fruit being swallowed is (eat)
	function drawQueue(scale:Float, lsize:Float, dy:Float):Array<Float> {
		var out = [];
		var n = queue.length - 1;
		var p = queue[n], p2;
		var s = scale * 15 / len, q;
		var eat_flag = (eat > 0);
		var esize = Cs.SNAKE_QUEUE_ELT_SIZE;
		var demi_esize = Std.int(esize / 2);
		var px = p.x, py = p.y + dy;
		// (Timer.tmod < 1.7: always the curves)
		var i = len;
		while (i > 0 && n - esize >= 0) {
			p = queue[n - esize];
			p2 = queue[n - demi_esize];
			if (eat_flag)
				q = Math.max(1, 2 - (i - eat) * (i - eat) / 2);
			else
				q = 1;
			out.push(px);
			out.push(py);
			out.push(p2.x);
			out.push(p2.y + dy);
			out.push(p.x);
			out.push(p.y + dy);
			out.push(i * s * q + lsize);
			px = p.x;
			py = p.y + dy;
			n -= esize;
			i--;
		}
		return out;
	}

	public function addQueue() {
		queue.splice(0, Std.int(Math.max(0, queue.length - len * Cs.SNAKE_QUEUE_ELT_SIZE - 1)));
		var p = queue[0];
		for (i in 0...10)
			queue.unshift(p);
		len++;
		redraw = true;
		eat = Std.int(len - 1);
	}

	public function explode(rgb:Int) {
		var pos = queue[queue.length - (len * Cs.SNAKE_QUEUE_ELT_SIZE)];
		len--;
		var particules:Array<{mc:Pic, ang:Float, speed:Float}> = [];
		for (i in 0...10) {
			var p = dmanager.add(new Pic("part"), Cs.PLAN_PARTICULES);
			var ang = Seed.randomVfx(180) / Math.PI;
			var speed = 1 + Seed.randomVfx(100) / 100;
			p.tint = rgb;
			p._xscale = teteScale;
			p._yscale = teteScale;
			// (no point past the end of the tail: _x = undefined is ignored by Flash, the particles stay at 0, 0)
			if (pos != null) {
				p._x = pos.x;
				p._y = pos.y;
			}
			particules.push({mc: p, ang: ang, speed: speed});
		}
		var fupdate:Void->Void = null;
		fupdate = function() {
			var i = 0;
			while (i < particules.length) {
				var p = particules[i];
				var s = p.speed * Timer.tmod;
				p.mc._x += Math.cos(p.ang) * s;
				p.mc._y += Math.sin(p.ang) * s;
				p.mc._rotation += s * 10;
				p.mc._alpha -= s * 10;
				if (p.mc._alpha <= 0) {
					p.mc.removeMovieClip();
					particules.remove(p);
					i--;
				}
				i++;
			}
			if (particules.length == 0)
				game.updates.remove(fupdate);
		};
		game.updates.push(fupdate);
		redraw = true;
	}

	public function cut(qpos:Int) {
		len -= qpos;
		redraw = true;
	}

	// Std.hitTest(collide_mc, mc): bounding box of col (in the head as the last draw left it) in the game layer
	public function colBox(out:Array<Float>) {
		var c = Data.COL;
		var k = teteScale / 100;
		var cs = Math.cos(teteRot) * k, sn = Math.sin(teteRot) * k;
		var tx = tete._x, ty = tete._y;
		out[0] = out[1] = Math.POSITIVE_INFINITY;
		out[2] = out[3] = Math.NEGATIVE_INFINITY;
		for (j in 0...4) {
			var px = c[(j & 1) == 0 ? 0 : 2];
			var py = c[(j & 2) == 0 ? 1 : 3];
			var gx = tx + px * cs - py * sn;
			var gy = ty + px * sn + py * cs;
			if (gx < out[0])
				out[0] = gx;
			if (gx > out[2])
				out[2] = gx;
			if (gy < out[1])
				out[1] = gy;
			if (gy > out[3])
				out[3] = gy;
		}
	}
}
