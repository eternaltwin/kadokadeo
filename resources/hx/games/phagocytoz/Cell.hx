package phagocytoz;

typedef Alien = {cell:Cell, dist:Float};

class Cell {
	public static var IMPULSE = 0.3;

	public var dead:Bool;

	var consume:Bool;

	// (always 0: the "type == 1 / 2" code of the original is commented out or never reached)
	var type:Int;

	public var x:Float;
	public var y:Float;
	public var vx:Float;
	public var vy:Float;

	var val:Float;

	public var baseRay:Float;
	public var ray:Float;
	public var color:Int;
	public var last:Bool;
	public var blob:Float;
	public var dec:Float;
	public var accel:Float;

	public var sprite:McCell;

	public function new(r:Float) {
		Game.me.cells.push(this);

		sprite = new McCell();
		sprite.env.stop();
		sprite.noyau.stop();
		Game.me.lvl.dm.add(sprite, Level.DP_CELLS);

		dead = false;
		ray = r;
		baseRay = r;
		color = Seed.random(3);

		consume = false;
		type = 0;
		near = [];
		nearTimer = 0;
		accel = 0.1 + Game.me.dif * 0.05;

		x = 0;
		y = 0;
		vx = 0;
		vy = 0;

		dec = 0;
		blob = 0;
		flh = 0;

		setRandomPos();
		randomImpulse();
		draw();
	}

	public function draw() {
		sprite.scaleX = ray * 2 * 0.01;
		sprite.scaleY = ray * 2 * 0.01;

		var sc = Math.max(2 - ray / 200, 1);

		sprite.noyau.scaleX = sc;
		sprite.noyau.scaleY = sc;
	}

	// (drawCircle: debug drawing of the original, never called)

	public function setRandomPos() {
		for (i in 0...400) {
			var ma = ray;
			x = ma + Seed.rand() * (Level.WIDTH - 2 * ma);
			y = ma + Seed.rand() * (Level.HEIGHT - 2 * ma);
			var ok = true;
			for (c in Game.me.cells) {
				if (c != this && collide(c)) {
					ok = false;
					break;
				}
			}
			if (ok)
				return;
		}
	}

	public function randomImpulse() {
		var a = Seed.rand() * 6.28;
		var pow = IMPULSE;
		vx = Num.q(Math.cos(a)) * pow;
		vy = Num.q(Math.sin(a)) * pow;
	}

	public function collide(c:Cell):Bool {
		var dx = ddx(c.x - x);
		var dy = ddy(c.y - y);
		var lim = ray + c.ray;
		if (Math.abs(dx) > lim || Math.abs(dy) > lim)
			return false;
		return Math.sqrt(dx * dx + dy * dy) < lim;
	}

	// UPDATE

	public function update() {
		x += vx;
		y += vy;

		sprite.noyau.x = vx * 0.5;
		sprite.noyau.y = vy * 0.5;

		if (blob > 0) {
			var ec = blob * 0.001;
			dec = (dec + 32 + blob) % 628;
			sprite.env.scaleX = 1 + Math.cos(dec * 0.01) * ec;
			sprite.env.scaleY = 1 + Math.sin(dec * 0.01) * ec;
			blob *= 0.8;
		}

		updateFlash();
		checkBorderCol();
	}

	public function updatePos() {
		var fc = Game.me.lvl.focus;
		var dx = ddx(x - fc.x);
		var dy = ddy(y - fc.y);

		// (the focus across a border of the level, or the cell across the side opposite to it: a jump of a level)
		sprite.moveWrapped(fc.x + dx, fc.y + dy, Level.WIDTH, Level.HEIGHT);
		sprite.visible = true;

		var ww = (Game.mcw * 0.5) / Game.me.lvl.scale;
		var hh = (Game.mch * 0.5) / Game.me.lvl.scale;
		sprite.visible = Math.abs(dx) - ray < ww && Math.abs(dy) - ray < hh;
	}

	function checkBorderCol() {
		x = Num.sMod(x, Level.WIDTH);
		y = Num.sMod(y, Level.HEIGHT);
	}

	public static inline function ddx(n:Float):Float {
		return Num.hMod(n, Level.WIDTH * 0.5);
	}

	public static inline function ddy(n:Float):Float {
		return Num.hMod(n, Level.HEIGHT * 0.5);
	}

	public function checkCols(c:Cell) {
		var dx = ddx(c.x - x);
		var dy = ddy(c.y - y);
		var lim = ray + c.ray;
		if (Math.abs(dx) < lim && Math.abs(dy) < lim) {
			var dif = lim - Math.sqrt(dx * dx + dy * dy);
			if (dif > ray)
				dif = ray;
			if (dif > c.ray)
				dif = c.ray;
			if (dif > 0) {
				var cns = consume || c.consume;

				// BOUNCE
				if (!cns || Math.abs(1 - ray / c.ray) < 0.1) {
					bounce(c, dif, dx, dy);
				} else {
					if (ray >= c.ray)
						eat(c, dif);
					else
						c.eat(this, dif);

					// DEBUG (type is never 2)
					if (c.type == 2)
						c.checkNear(this);
					if (type == 2)
						checkNear(c);
				}
			}
		}
	}

	function eat(c:Cell, dif:Float) {
		var area = getDiscArea(c.ray) - getDiscArea(c.ray - dif);
		grow(area);
		c.grow(-area);
	}

	function bounce(c:Cell, dif:Float, dx:Float, dy:Float) {
		var an = Num.q(Math.atan2(dy, dx));
		var ca = Num.q(Math.cos(an));
		var sa = Num.q(Math.sin(an));

		var ec = dif * 0.5;
		c.x += ca * ec;
		c.y += sa * ec;
		x -= ca * ec;
		y -= sa * ec;

		// BOUNCE
		var speed = Math.sqrt(vx * vx + vy * vy);
		var cspeed = Math.sqrt(c.vx * c.vx + c.vy * c.vy);
		var sp = (ray / (ray + c.ray)) * speed;
		c.vx += ca * sp;
		c.vy += sa * sp;
		var sp = (c.ray / (ray + c.ray)) * speed;
		vx -= ca * sp;
		vy -= sa * sp;
	}

	function grow(inc:Float) {
		var area = getDiscArea(ray);
		var c = inc / area;
		area += inc;
		ray = getDiscRay(area);
		draw();

		if (inc < 0)
			blob *= 0.5;
		else
			blob += c * 200;

		if (ray < 1) {
			// (the FxStar of the original is commented out)
			kill();
		}
	}

	function getDiscArea(ray:Float):Float {
		if (ray < 0)
			return 0;
		// (Math.pow(x, 2): x * x, exact on every browser)
		var p = 2 * Math.PI * ray;
		return p * p;
	}

	function getDiscRay(area:Float):Float {
		if (area < 0)
			return 0;
		return Math.sqrt(area) / (Math.PI * 2);
	}

	// IA
	public var near:Array<Alien>;
	public var nearTimer:Float;

	function ia() {
		// (compiled: the test reads nearTimer before the decrement)
		var t = nearTimer;
		nearTimer = t - 1;
		if (t <= 0)
			majNear();

		majNearDist();
		sortNears(near);

		var acc = accel;
		var ref = 0.0;
		var a:Array<{an:Float, w:Float}> = [];
		var speed = Math.sqrt(vx * vx + vy * vy);

		// (Haxe 2's for-in over the array itself: a removed entry makes the loop skip the next one)
		var i = 0;
		while (i < near.length) {
			var o = near[i];
			i++;
			if (o.cell.dead) {
				near.remove(o);
				continue;
			}
			if (ref == 0)
				ref = o.dist;
			var coef = ref / o.dist;
			if (coef < 0.5 && Math.abs(o.dist) > speed * 5)
				break;
			var dx = ddx(o.cell.x - x);
			var dy = ddy(o.cell.y - y);
			var an = Num.q(Math.atan2(dy, dx));
			if (o.cell.ray >= ray)
				an += 3.14;
			a.push({an: an, w: coef});
		}
		var sum = 0.0;
		for (o in a)
			sum += o.w;
		var dx = 0.0;
		var dy = 0.0;
		for (o in a) {
			var c = o.w / sum;
			dx += Num.q(Math.cos(o.an));
			dy += Num.q(Math.sin(o.an));
		}
		var an = Num.q(Math.atan2(dy, dx));

		if (a.length == 0)
			acc = 0;
		vx += Num.q(Math.cos(an)) * acc;
		vy += Num.q(Math.sin(an)) * acc;

		var frict = 0.96;
		vx *= frict;
		vy *= frict;
	}

	function majNear() {
		near = [];
		nearTimer = 30 + Seed.random(10);

		for (c in Game.me.cells) {
			if (c != this) {
				var dx = ddx(x - c.x);
				var dy = ddy(y - c.y);
				var dist = Math.sqrt(dx * dx + dy * dy) - (c.ray + ray);
				near.push({cell: c, dist: dist});
			}
		}
		sortNears(near);
		near = near.slice(0, 20);
	}

	function majNearDist() {
		for (o in near) {
			var dx = ddx(x - o.cell.x);
			var dy = ddy(y - o.cell.y);
			var dist = Math.sqrt(dx * dx + dy * dy) - (o.cell.ray + ray);
			o.dist = dist;
		}
	}

	public function sortNear(a:Alien, b:Alien):Int {
		if (a.dist < b.dist)
			return -1;
		else
			return 1;
	}

	// port: near.sort(sortNear). sortNear never returns 0, so the order it gives to equal distances depends on the
	// sorting algorithm (Array.sort of the browser): a merge sort of our own, the same everywhere
	function sortNears(list:Array<Alien>) {
		var n = list.length;
		if (n < 2)
			return;
		var tmp:Array<Alien> = list.copy();
		var width = 1;
		var src = list;
		var dst = tmp;
		while (width < n) {
			var lo = 0;
			while (lo < n) {
				var mid = Std.int(Math.min(lo + width, n));
				var hi = Std.int(Math.min(lo + 2 * width, n));
				var i = lo;
				var j = mid;
				var k = lo;
				while (i < mid && j < hi) {
					if (sortNear(src[j], src[i]) < 0)
						dst[k++] = src[j++];
					else
						dst[k++] = src[i++];
				}
				while (i < mid)
					dst[k++] = src[i++];
				while (j < hi)
					dst[k++] = src[j++];
				lo += 2 * width;
			}
			var t = src;
			src = dst;
			dst = t;
			width *= 2;
		}
		if (src != list)
			for (k in 0...n)
				list[k] = src[k];
	}

	function checkNear(c:Cell) {
		for (o in near)
			if (o.cell == c)
				return;
		// (trace("alien unknown" + Std.random(10)): debug)
		fxFlash();
	}

	// FX
	public var flh:Float;

	public function fxFlash() {
		flh = 1;
		sprite.alpha = 0.5;
		updateFlash();
	}

	public function updateFlash() {
		if (flh == 0)
			return;
		if (flh < 0.1)
			flh = 0;
		// Col.setPercentColor(sprite, flh, 0xFFFFFF)
		var cp = 1 - flh;
		sprite.setColorTransform(cp, cp, cp, 1, Std.int(flh * 255), Std.int(flh * 255), Std.int(flh * 255), 0);
		flh *= 0.75;
	}

	public function kill() {
		dead = true;
		// (Flash: a cell eaten again after its death in the same frame has no parent any more: TypeError, the rest of
		// the frame's code is skipped)
		if (sprite.parent == null)
			throw new FlashError("TypeError: Error #1009: Cannot access a property or method of a null object reference.");
		sprite.parent.removeChild(sprite);
		Game.me.cells.remove(this);
	}

	// (lineTo: debug drawing of the original, never called)
}
