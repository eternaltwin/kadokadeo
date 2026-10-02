package manda;

// Movable of the original: jumps (coffre) and falls (canne) of the fruits, with their shadow
class Movable {
	public var mc:ItemMc;
	public var shade:ItemMc;

	var moving:Bool;
	var x_start:Float;
	var y_start:Float;
	var z_start:Float;
	var x_dest:Float;
	var y_dest:Float;
	var coef_a:Float;
	var coef_b:Float;
	var speed:Float;
	var t:Float;

	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var scale:Float;

	public function new(mc:ItemMc) {
		this.mc = mc;
		x = mc._x;
		y = mc._y;
		z = 0;
		moving = false;
	}

	function createShade():ItemMc {
		return null;
	}

	function inBounds(x:Float, y:Float):Bool {
		return true;
	}

	public function setPos(px:Float, py:Float) {
		x = px;
		y = py;
		z = 0;
		moving = false;
		mc._x = x;
		mc._y = y;
		removeShade();
	}

	inline function removeShade() {
		if (shade != null)
			shade.remove();
		shade = null;
	}

	public function isMoving() {
		return moving;
	}

	public function move() {
		if (moving) {
			t += Timer.tmod * speed;
			if (t >= 1) {
				x = x_dest;
				y = y_dest;
				z = 0;
				removeShade();
				moving = false;
			} else {
				x = x_start + (x_dest - x_start) * t;
				y = y_start + (y_dest - y_start) * t;
				z = coef_a * t * t + coef_b * t + z_start;
			}
			if (z != 0 && shade != null) {
				shade._x = x + z / 4;
				shade._y = y + z / 3;
				shade._xscale = (100 - z / 2) * scale;
				shade._yscale = (100 - z / 2) * scale;
			}
			mc._xscale = (100 + z) * scale;
			mc._yscale = (100 + z) * scale;
			mc._x = x;
			mc._y = y - z;
		}
	}

	function addShade() {
		if (shade == null)
			shade = createShade();
		shade._visible = true;
		shade._y = y;
		shade._x = x;
	}

	public function jumpNear(ray:Float, zmax:Float, speed:Float) {
		this.speed = speed;
		x_start = x;
		y_start = y;
		z_start = z;

		t = 0;
		coef_b = zmax * 4 - z;
		coef_a = -coef_b - z;

		var ntrys = 100;
		do {
			var ang = Seed.random(360) / (Math.PI * 2);
			x_dest = x + Cs.qt(Math.cos(ang)) * ray;
			y_dest = y + Cs.qt(Math.sin(ang)) * ray;
		} while (!inBounds(x_dest, y_dest) && --ntrys > 0);

		addShade();
		moving = true;
	}

	public function fall(speed:Float) {
		this.speed = speed;
		x = mc._x;
		y = mc._y;
		x_start = x;
		y_start = y;
		z_start = z;
		x_dest = x;
		y_dest = y;
		t = 0;
		coef_a = 5;
		coef_b = -z - coef_a;
		addShade();
		moving = true;
	}
}
