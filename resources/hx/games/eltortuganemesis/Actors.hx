package eltortuganemesis;

import eltortuganemesis.Bmp;
import eltortuganemesis.Cs;
import eltortuganemesis.PVector;
import pixi.core.Pixi.BlendModes;

// a symbol of sprites.swf: one frame per direction / state, its `sub` animation (one Mc per frame of the symbol)
class Sym extends ASprite {
	public var frame(default, null):Int;
	public var sub(default, null):Mc;

	var subs:Array<Mc>;

	public function new(name:String, counts:Array<Int>) {
		super();
		subs = [];
		for (i in 0...counts.length) {
			var m = new Mc(name + (i + 1), false);
			m.visible = false;
			addChild(m);
			subs.push(m);
		}
		frame = 0;
		gotoAndStop(1);
	}

	// gotoAndStop(frame): a new `sub`, on its frame 1, playing
	override public function gotoAndStop(f:Dynamic) {
		var n:Int = Std.int(f);
		frame = n;
		for (i in 0...subs.length)
			subs[i].visible = i == n - 1;
		sub = subs[n - 1];
		sub.gotoAndPlay(1);
	}
}

// the symbol of the dog (Ovni): its `sub` holds two nested clips whose timelines keep playing on their own, drawn
// apart from the frames of the sub (a new sub, from gotoAndStop, starts them again on their frame 1)
// - the beam under the flying saucer (sub 1): yellow, green, white, one per frame;
// - the lit lamp going round the rim: 8 lamps of 2 frames, a patch over the frame of the sub (what covers the lamp
//   in the sub is in the patch)
class Ovni extends Sym {
	static inline var LAMPS = 8;

	var beam:Mc;
	var lamp:OvniLamp;
	// first frame of each sub in the lamp patches
	var lampBase:Array<Int>;

	public function new() {
		super("ovni", Data.SUB_OVNI);
		beam = new Mc("ovnibeam");
		addChildAt(beam, 0);
		lamp = new OvniLamp();
		addChild(lamp);
		lampBase = [];
		var n = 0;
		for (c in Data.SUB_OVNI) {
			lampBase.push(n);
			n += c;
		}
		gotoAndStop(1);
	}

	override public function gotoAndStop(f:Dynamic) {
		super.gotoAndStop(f);
		if (beam == null)
			return;
		beam.visible = frame == 1;
		beam.gotoAndPlay(1);
		lamp.age = 0;
	}

	// the lamp over the frame shown by the sub
	public function sync() {
		lamp.show((lampBase[frame - 1] + sub.cur - 1) * LAMPS + ((lamp.age % (LAMPS * 2)) >> 1) + 1);
	}
}

// the timeline of the lit lamp: one frame of the Flash player per advance
class OvniLamp extends Mc {
	public var age:Int;

	public function new() {
		super("ovnilamp", false);
		age = 0;
	}

	override public function advance() {
		if (!dead)
			age++;
	}
}

class Cursor {
	public var oldPos:PVector;
	public var pos:PVector;
	public var gfx:Sym;
	public var speed:Float;
	public var moveVector:Pt;

	var frame:Float;
	var subFrame:Int;

	public function new() {
		moveVector = {x: 0.0, y: 0.0};
		speed = Game.SLOW_SPEED;
		pos = new PVector();
		oldPos = new PVector();
		gfx = new Sym("tortue", Data.SUB_TORTUE);
		gfx.gotoAndStop(3);
		gfx.sub.stop();
		frame = 0;
		subFrame = 1;
	}

	// getCollisionBitmap: the turtle drawn at the origin of a 40 x 40 bitmap (pixels of alpha 255)
	public function collides(b:ABmp):Bool {
		var m = Data.MASKS[(gfx.frame - 1) * 9 + (gfx.sub.cur - 1)];
		var px = Math.floor(pos.x), py = Math.floor(pos.y);
		for (y in 0...40) {
			var lo = m[y * 2], hi = m[y * 2 + 1];
			if (lo == 0 && hi == 0)
				continue;
			for (x in 0...40) {
				var bit = x < 20 ? (lo >> x) & 1 : (hi >> (x - 20)) & 1;
				if (bit == 1 && b.alpha(px + x, py + y) == 255)
					return true;
			}
		}
		return false;
	}

	public function setNewMoveVector(x:Float, y:Float) {
		if (x == moveVector.x && y == moveVector.y)
			return;
		moveVector.x = x;
		moveVector.y = y;
		if (y > 0) {
			gfx.gotoAndStop(3);
			frame = 0;
		} else if (y < 0) {
			gfx.gotoAndStop(2);
			frame = 0;
		} else if (x > 0) {
			gfx.gotoAndStop(1);
			frame = 0;
		} else if (x < 0) {
			gfx.gotoAndStop(4);
			frame = 0;
		}
	}

	public function update() {
		gfx._x = pos.x;
		gfx._y = pos.y;
		var fspeed = (speed / Game.SLOW_SPEED);
		frame += fspeed * Timer.tmod;
		if (moveVector.x == 0 && moveVector.y == 0) {
			gfx.sub.stop();
			return;
		}
		var f = Math.round(frame);
		var total = gfx.sub.frames.length;
		if (f > total) {
			f -= total;
			frame -= total;
		}
		gfx.sub.gotoAndStop(f < 1 ? 1 : f);
	}
}

enum QixState {
	FLY;
	LAND;
	SHOOT;
	LAUNCH;
}

// the dog in its flying saucer (Ovni)
class Qix {
	public static var W = 80;
	public static var H = 42;

	public var x:Float;
	public var y:Float;
	public var gfx:Ovni;

	var mover:Mover;
	var state:QixState;
	var target:PVector;

	public var lazers:Array<QixLazer>;
	public var lazersFront:ABmp;
	public var lazersBack:ABmp;
	public var lazersChanged:Bool;

	public function new() {
		x = 0;
		y = 0;
		gfx = new Ovni();
		mover = new Mover();
		mover.x = W / 2;
		mover.y = H / 2;
		mover.maxSpeed = 7;
		lazersFront = new ABmp(Game.W, Game.H);
		lazersBack = new ABmp(Game.W, Game.H);
		lazersChanged = false;
		reset();
	}

	public function reset() {
		state = FLY;
		if (Game.level != null)
			mover.maxSpeed = Game.level.dogSpeed;
		gfx.gotoAndStop(1);
		gfx.sub.stops = [];
		if (lazers != null)
			endLazers();
	}

	// the shadow (an ellipse of W x H) at the top left of the dog
	public function collidesDrawing(d:Bmp):Bool {
		var cx = x - W / 2, cy = y - H / 2;
		var x0 = Math.floor(cx), y0 = Math.floor(cy);
		var rx = W / 2, ry = H / 2;
		for (j in 0...H + 1) {
			for (i in 0...W + 1) {
				// pixel fully inside the ellipse (alpha 255)
				var px = i + 0.5 - rx, py = j + 0.5 - ry;
				var ex = (Math.abs(px) + 0.5) / rx, ey = (Math.abs(py) + 0.5) / ry;
				if (ex * ex + ey * ey > 1)
					continue;
				var c = d.get(x0 + i, y0 + j);
				if ((c >>> 24) == 255)
					return true;
			}
		}
		return false;
	}

	public function getPos():PVector {
		return new PVector(mover.x, mover.y);
	}

	public function setPos(nx:Float, ny:Float) {
		x = nx;
		y = ny;
		mover.x = nx;
		mover.y = ny;
	}

	// the timeline of the sub (before the code of the frame)
	public function advance() {
		gfx.sub.advance();
	}

	public function update() {
		switch (state) {
			case FLY:
				updateFly();
				var c = Game.getCursorPos();
				if (mover.pos.distanceSquared({x: c.x, y: c.y}) < 120 * 120 && Std.int(Seed.rand() * 50) == 0) {
					gfx.gotoAndStop(2);
					gfx.sub.stops = [Data.SUB_OVNI[1]];
					state = LAND;
				}

			case LAND:
				if (gfx.sub.cur == gfx.sub.frames.length) {
					gfx.sub.stop();
					state = SHOOT;
				}

			case LAUNCH:
				if (gfx.sub.cur == gfx.sub.frames.length) {
					gfx.sub.stop();
					gfx.gotoAndStop(1);
					gfx.sub.stops = [];
					state = FLY;
				}

			case SHOOT:
				if (lazers == null)
					initLazers();
				if (updateLazers()) {
					endLazers();
					gfx.gotoAndStop(3);
					gfx.sub.stops = [Data.SUB_OVNI[2]];
					state = LAUNCH;
				}
		}
		gfx._x = x;
		gfx._y = y;
	}

	// test harness: the dog lands now
	public function forceLand() {
		gfx.gotoAndStop(2);
		gfx.sub.stops = [Data.SUB_OVNI[1]];
		state = LAND;
	}

	public function updateAnim() {
		switch (state) {
			case LAND, LAUNCH:
				if (gfx.sub.cur == gfx.sub.frames.length)
					gfx.sub.stop();
			default:
		}
	}

	public function updateFly() {
		if (target != null && Game.getPixel(Math.round(target.x), Math.round(target.y)) != Colors.TO_CONQUER)
			target = null;
		if (target == null) {
			var targets = [];
			var me = this;
			var getTarget = function(vx:Float, vy:Float) {
				var pos = me.mover.pos.clone();
				pos.add({x: vx, y: vy});
				if (Game.getPixel(Math.round(pos.x), Math.round(pos.y)) == Colors.TO_CONQUER)
					targets.push(pos);
			}
			getTarget(0.0, -30 - 70 * Seed.rand());
			getTarget(0.0, 30 + 70 * Seed.rand());
			getTarget(-30 - 70 * Seed.rand(), 0.0);
			getTarget(30 + 70 * Seed.rand(), 0.0);
			var ax = -30 - 70 * Seed.rand();
			getTarget(ax, -30 - 70 * Seed.rand());
			var bx = -30 - 70 * Seed.rand();
			getTarget(bx, 30 + 70 * Seed.rand());
			var cy = -30 - 70 * Seed.rand();
			getTarget(30 + 70 * Seed.rand(), cy);
			var dy = 30 + 70 * Seed.rand();
			getTarget(30 + 70 * Seed.rand(), dy);
			target = targets.length > 0 ? targets[Seed.random(targets.length)] : null;
		}
		if (target != null) {
			mover.maxSpeed = Game.level.dogSpeed * Timer.tmod;
			mover.seek(target, 1);
			mover.update();
			var nx = Math.round(mover.x);
			var ny = Math.round(mover.y);
			if (Game.getPixel(nx, ny) != Colors.TO_CONQUER) {
				mover.pos.set(mover.oldPos);
				target = null;
			} else if (mover.pos.distanceSquared(target) <= 100)
				target = null;
			x = Math.round(mover.x);
			y = Math.round(mover.y);
		}
	}

	function initLazers() {
		lazersBack.clear();
		lazersFront.clear();
		var l = Game.level.dogLazerLength;
		var yH = y - l;
		var yL = y + l;
		var xL = x - l;
		var xR = x + l;
		lazers = [
			new QixLazer(x - 20, y - 30, xL, yH),
			new QixLazer(x + 20, y - 30, xR, yH),
			new QixLazer(x - 20, y - 8, xL, yL),
			new QixLazer(x + 20, y - 8, xR, yL),
		];
	}

	function updateLazers():Bool {
		var complete = true;
		// (lazersBack faded from lazersFront: like the original)
		lazersFront.fadeFrom(lazersFront, 20);
		lazersBack.fadeFrom(lazersFront, 20);
		for (l in lazers) {
			if (l.update()) {
				complete = false;
				l.draw(l.ground.y > y ? lazersFront : lazersBack);
			}
		}
		lazersChanged = true;
		return complete;
	}

	function endLazers() {
		lazers = null;
		lazersChanged = true;
	}
}

// a lazer of the dog: a beam from (x, y) to its point on the ground, which goes towards its target in waves
class QixLazer {
	public var x:Float;
	public var y:Float;
	public var previous:Pt;
	public var ground:Pt;
	public var target:PVector;
	public var speed:Float;

	static inline var COLOR = 0xFF4400;

	var angle:Float;
	var distance:Float;
	var rpos:Float;

	public function new(x:Float, y:Float, tx:Float, ty:Float) {
		this.x = x;
		this.y = y;
		speed = Game.level.dogLazerSpeed;
		ground = {x: x + 0.0, y: y + 50.0};
		previous = {x: x + 0.0, y: y + 50.0};
		setTarget(tx, ty);
	}

	public function setTarget(tx:Float, ty:Float) {
		target = new PVector(tx, ty);
		var vector = target.clone().sub(ground);
		distance = vector.length();
		angle = vector.angle();
		rpos = 0.0;
	}

	public static function frequencePoint(x:Float, max:Float) {
		var frequence = 1 / 8;
		var amplitude = 80;
		var distanceRatio = x / max;
		return new PVector(x, Cs.sin(x * frequence) * amplitude * distanceRatio);
	}

	public function update():Bool {
		rpos += (speed * Timer.tmod);
		rpos = Math.min(rpos, distance);
		var fp = frequencePoint(rpos, distance);
		if (ground.x > x)
			fp.y = -fp.y;
		fp.rotate(angle);
		fp.add({x: x, y: y});

		var dif = new PVector(fp.x - ground.x, fp.y - ground.y);
		dif.limit(speed);
		previous.x = ground.x;
		previous.y = ground.y;
		ground.x += dif.x;
		ground.y += dif.y;
		return rpos < distance;
	}

	// Graphics of the lazer drawn into the bitmap: the beam (triangle from the start to the last two points on the
	// ground, filled and stroked 2 px), a disc of radius 2 at the ground, three white sparks (random)
	public function draw(b:ABmp) {
		var deltaX = ((previous.x - ground.x) > 0) ? 1 : -1;
		var deltaY = ((previous.y - ground.y) > 0) ? 1 : -1;
		var ax = x, ay = y;
		var bx = ground.x, by = ground.y;
		var cx = previous.x, cy = previous.y;
		var dx = ground.x + deltaX * 2, dy = ground.y + deltaY;
		var dots = [];
		for (i in 0...3) {
			var rX = 5 - Seed.random(10);
			var rY = 2 - Seed.random(10);
			dots.push(ground.x + rX);
			dots.push(ground.y + rY);
		}
		var x0 = Math.floor(Math.min(Math.min(ax, bx), Math.min(cx, dx - 3))) - 2;
		var x1 = Math.ceil(Math.max(Math.max(ax, bx), Math.max(cx, dx + 3))) + 2;
		var y0 = Math.floor(Math.min(Math.min(ay, by), Math.min(cy, dy - 3))) - 9;
		var y1 = Math.ceil(Math.max(Math.max(ay, by), Math.max(cy, dy + 3))) + 4;
		for (py in y0...y1 + 1) {
			for (px in x0...x1 + 1) {
				var red = 0, white = 0, black = 0;
				// 4 samples per pixel
				for (s in 0...4) {
					var sx = px + 0.25 + (s & 1) * 0.5;
					var sy = py + 0.25 + (s >> 1) * 0.5;
					if (inTri(sx, sy, ax, ay, bx, by, cx, cy) || segDist2(sx, sy, ax, ay, bx, by) <= 1 || segDist2(sx, sy, bx, by, cx, cy) <= 1
						|| segDist2(sx, sy, cx, cy, ax, ay) <= 1 || (sx - dx) * (sx - dx) + (sy - dy) * (sy - dy) <= 9)
						red++;
					// sparks: white discs of radius 1 with a black hairline (lineStyle(0)): dark dots
					var i = 0;
					while (i < 6) {
						var ex = sx - dots[i], ey = sy - dots[i + 1];
						var d2 = ex * ex + ey * ey;
						if (d2 <= 0.36) {
							white++;
							break;
						} else if (d2 <= 2.25) {
							black++;
							break;
						}
						i += 2;
					}
				}
				if (red > 0)
					b.blend(px, py, COLOR, red / 4);
				if (white > 0)
					b.blend(px, py, 0xFFFFFF, white / 4);
				if (black > 0)
					b.blend(px, py, 0x000000, black / 4);
			}
		}
	}

	static inline function inTri(px:Float, py:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Bool {
		var d1 = (px - bx) * (ay - by) - (ax - bx) * (py - by);
		var d2 = (px - cx) * (by - cy) - (bx - cx) * (py - cy);
		var d3 = (px - ax) * (cy - ay) - (cx - ax) * (py - ay);
		var neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
		var pos = (d1 > 0) || (d2 > 0) || (d3 > 0);
		return !(neg && pos);
	}

	static inline function segDist2(px:Float, py:Float, ax:Float, ay:Float, bx:Float, by:Float):Float {
		var vx = bx - ax, vy = by - ay;
		var l = vx * vx + vy * vy;
		var t = l > 0 ? ((px - ax) * vx + (py - ay) * vy) / l : 0;
		if (t < 0)
			t = 0;
		if (t > 1)
			t = 1;
		var qx = ax + vx * t - px, qy = ay + vy * t - py;
		return qx * qx + qy * qy;
	}
}

// the squirrels: they run along the paths, on the side of the lawn to mow
class Spark {
	public static var sparks:Array<Spark> = [];

	static function spawn() {
		sparks = [new Spark(true), new Spark(false)];
		sparks[0].pos.set({x: Game.field.x, y: Game.H / 2});
		sparks[0].direction.set(Direction.SOUTH);
		sparks[0].side.set(Direction.EAST);
		sparks[1].pos.set({x: Game.field.x + Game.field.width, y: Game.H / 2});
		sparks[1].direction.set(Direction.SOUTH);
		sparks[1].side.set(Direction.WEST);
		for (s in sparks)
			Game.me.addSquirrel(s.movie);
	}

	public static function reset() {
		for (s in sparks)
			s.movie.removeMovieClip();
		sparks = [];
	}

	public static function updateSparks() {
		if (sparks.length == 0)
			spawn();
		for (s in sparks.copy()) {
			s.oldPos.set(s.pos);
			for (t in 0...Math.round(Game.level.sparksSpeed * Timer.tmod))
				s.update();
		}
	}

	public static function pauseSparksAnim() {
		for (s in sparks)
			s.pauseAnim();
	}

	public var movie:Sym;
	public var pos:PVector;
	public var oldPos:PVector;
	public var direction:PVector;
	public var side:PVector;
	public var destroyed:Bool;
	public var left:Bool;
	public var panicked:Bool;

	public function new(l:Bool) {
		movie = new Sym("ecureuil", Data.SUB_ECUREUIL);
		movie.gotoAndStop(1);
		left = l;
		pos = new PVector();
		oldPos = new PVector();
		direction = new PVector();
		side = new PVector();
		destroyed = false;
		panicked = false;
	}

	function canUse(side:Pt, dir:Pt) {
		var d = left ? Direction.rightOf(side) : Direction.leftOf(side);
		return d != null && d.equals(dir);
	}

	public function update() {
		var pixels = Game.getPixels(Math.round(pos.x), Math.round(pos.y));
		var nextPixel = pixels[Direction.d2i(direction)];
		var sidePixel = pixels[Direction.d2i(side)];
		var otherSide = side.clone().negate();
		var otherSidePixel = pixels[Direction.d2i(otherSide)];
		if (Colors.isConqueredPath(nextPixel) && sidePixel == Colors.TO_CONQUER) {
			destroyed = false;
		} else if (otherSidePixel == Colors.TO_CONQUER && canUse(otherSide, direction.clone().negate())) {
			direction.negate();
			side.set(otherSide);
			destroyed = false;
		} else {
			var candidates = [];
			var dirs = [side.clone(), otherSide];
			for (v in dirs)
				if (Colors.isConqueredPath(pixels[Direction.d2i(v)]))
					candidates.push(v);
			destroyed = true;
			for (c in candidates) {
				var pixels = Game.getPixels(Math.round(pos.x + c.x), Math.round(pos.y + c.y));
				for (d in [Direction.NORTH, Direction.WEST, Direction.SOUTH, Direction.EAST]) {
					var p = pixels[Direction.d2i(d)];
					if (p == Colors.TO_CONQUER) {
						if (canUse(d, c)) {
							side.set(d);
							direction.set(c);
							destroyed = false;
							panicked = false;
							break;
						}
					}
				}
			}
			if (destroyed) {
				var pforward = pos.clone().add(direction);
				var pleft = pos.clone().add(Direction.leftOf(direction));
				var pright = pos.clone().add(Direction.rightOf(direction));
				var cands = [pforward, pleft, pright];
				var best:PVector = null;
				var bestDistToQix = 99999999.0;
				var qixPos = Game.qix.getPos();
				for (c in cands)
					if (Colors.isConqueredPath(Game.getPixel(Math.round(c.x), Math.round(c.y)))) {
						var dist = c.distanceSquared(qixPos);
						if (dist < bestDistToQix) {
							best = c;
							bestDistToQix = dist;
						}
					}
				if (best != null) {
					best.sub(pos);
					direction.set(best);
					side.set(left ? Direction.leftOf(direction) : Direction.rightOf(direction));
				}
			}
		}
		pos.add(direction);
		if (direction.equals(Direction.NORTH)) {
			if (movie.frame != 3)
				movie.gotoAndStop(3);
		} else if (direction.equals(Direction.SOUTH)) {
			if (movie.frame != 2)
				movie.gotoAndStop(2);
		} else if (direction.equals(Direction.WEST)) {
			if (movie.frame != 4)
				movie.gotoAndStop(4);
		} else if (direction.equals(Direction.EAST)) {
			if (movie.frame != 1)
				movie.gotoAndStop(1);
		}
		movie.sub.play();
		movie._x = pos.x;
		movie._y = pos.y;
	}

	public function pauseAnim() {
		movie.sub.stop();
	}
}

// the spark which follows the cable from where it started: it kills the turtle when it reaches it
class LazerSpark {
	public var pos:PVector;
	public var oldPos:PVector;
	public var vector:Pt;
	public var movePower:Float;

	public function new() {
		pos = new PVector(Game.drawStart.x, Game.drawStart.y);
		oldPos = pos.clone();
		vector = {x: Game.drawVector.x, y: Game.drawVector.y};
		movePower = 0.0;
	}

	public function update() {
		if (vector == null)
			return;
		var rspeed = movePower + Game.level.lazerSparkSpeed * Timer.tmod;
		var speed = Math.round(rspeed);
		movePower = rspeed - speed;
		for (step in 0...speed) {
			var pixels = Game.getDrawingPixels(Math.round(pos.x), Math.round(pos.y));
			var possibilities:Array<Pt> = [vector, Direction.leftOf(vector), Direction.rightOf(vector)];
			vector = null;
			for (vect in possibilities) {
				if (vect == null)
					continue;
				var color = pixels[Direction.d2i(vect)];
				if (Colors.isDrawingPath(color)) {
					vector = vect;
					break;
				}
			}
			if (vector != null) {
				oldPos.x = pos.x;
				oldPos.y = pos.y;
				pos.x += vector.x;
				pos.y += vector.y;
			} else {
				return;
			}
		}
	}
}
