package eltortuganemesis;

typedef Pt = {x:Float, y:Float};

// geom.PVector, geom.Vector2D, Direction and geom.Mover of the original (the parts used by the game)
class PVector {
	static var ORIGIN = new PVector();

	public var x:Float;
	public var y:Float;

	public function new(x_:Float = 0.0, y_:Float = 0.0) {
		x = x_;
		y = y_;
	}

	public inline function equals(v:Pt):Bool {
		return x == v.x && y == v.y;
	}

	public inline function set(v:Pt):PVector {
		x = v.x;
		y = v.y;
		return this;
	}

	public inline function add(v:Pt):PVector {
		x += v.x;
		y += v.y;
		return this;
	}

	public inline function sub(v:Pt):PVector {
		x -= v.x;
		y -= v.y;
		return this;
	}

	public inline function div(v:Float):PVector {
		x /= v;
		y /= v;
		return this;
	}

	public inline function mult(v:Float):PVector {
		x *= v;
		y *= v;
		return this;
	}

	public inline function limit(l:Float):PVector {
		normalize();
		mult(l);
		return this;
	}

	public inline function normalize():Float {
		var l = length();
		if (l != 0)
			div(l);
		return l;
	}

	public inline function lengthSquared():Float {
		return x * x + y * y;
	}

	public inline function length():Float {
		return Math.sqrt(x * x + y * y);
	}

	public inline function negate():PVector {
		x *= -1;
		y *= -1;
		return this;
	}

	public inline function distanceSquared(v:Pt):Float {
		return (v.x - x) * (v.x - x) + (v.y - y) * (v.y - y);
	}

	public inline function clone():PVector {
		return new PVector(x, y);
	}

	public inline function rotate(a:Float):PVector {
		var cos = Cs.cos(a);
		var sin = Cs.sin(a);
		var rx = x * cos - y * sin;
		var ry = x * sin + y * cos;
		x = rx;
		y = ry;
		return this;
	}

	public inline function angle():Float {
		return Cs.atan2(y, x);
	}
}

class Vector2D {
	var rx:Float;
	var ry:Float;
	var rw:Float;
	var rh:Float;

	public function new(start:Pt, end:Pt) {
		rx = Math.min(start.x, end.x);
		ry = Math.min(start.y, end.y);
		rw = Math.abs(end.x - start.x);
		rh = Math.abs(end.y - start.y);
	}

	public function rectangleContains(p:Pt) {
		return (rx <= p.x && rx + rw >= p.x) && (ry <= p.y && ry + rh >= p.y);
	}
}

class Direction extends PVector {
	public static var NORTH = new Direction(0, -1);
	public static var SOUTH = new Direction(0, 1);
	public static var WEST = new Direction(-1, 0);
	public static var EAST = new Direction(1, 0);
	public static var DIRECTIONS = [NORTH, WEST, SOUTH, EAST];

	function new(x:Float, y:Float) {
		super(x, y);
	}

	public function left():Direction {
		if (this == NORTH)
			return WEST;
		else if (this == WEST)
			return SOUTH;
		else if (this == SOUTH)
			return EAST;
		else if (this == EAST)
			return NORTH;
		return null;
	}

	public function right():Direction {
		if (this == NORTH)
			return EAST;
		else if (this == EAST)
			return SOUTH;
		else if (this == SOUTH)
			return WEST;
		else if (this == WEST)
			return NORTH;
		return null;
	}

	public static function leftOf(p:Pt):Direction {
		for (d in DIRECTIONS)
			if (d.equals(p))
				return d.left();
		return null;
	}

	public static function rightOf(p:Pt):Direction {
		for (d in DIRECTIONS)
			if (d.equals(p))
				return d.right();
		return null;
	}

	public static function d2i(d:Pt):Int {
		return (Math.round(d.x) + 1) + (3 * (Math.round(d.y) + 1));
	}
}

class Mover {
	public var pos:PVector;
	public var oldPos:PVector;
	public var acceleration:PVector;
	public var velocity:PVector;
	public var maxSpeed(default, set):Float;

	var maxSpeedSquared:Float;

	public var steering:PVector;
	public var maxForce(default, set):Float;

	var maxForceSquared:Float;

	public var x(get, set):Float;
	public var y(get, set):Float;

	function get_x():Float
		return pos.x;

	function set_x(v:Float):Float
		return pos.x = v;

	function get_y():Float
		return pos.y;

	function set_y(v:Float):Float
		return pos.y = v;

	public function new(maxForce = 1.0, maxSpeed = 10.0) {
		pos = new PVector();
		oldPos = new PVector();
		velocity = new PVector();
		acceleration = new PVector();
		steering = new PVector();
		this.maxForce = maxForce;
		this.maxSpeed = maxSpeed;
	}

	function set_maxSpeed(s:Float):Float {
		maxSpeed = s;
		maxSpeedSquared = s * s;
		return maxSpeed;
	}

	function set_maxForce(s:Float):Float {
		maxForce = s;
		maxForceSquared = s * s;
		return maxForce;
	}

	public function update():Bool {
		oldPos.set(pos);
		velocity.add(acceleration);
		if (velocity.lengthSquared() > maxSpeedSquared) {
			velocity.normalize();
			velocity.mult(maxSpeed);
		}
		pos.add(velocity);
		acceleration.x = 0;
		acceleration.y = 0;
		return true;
	}

	public function seek(target:Pt, ?multiplier:Float = 1.0) {
		steering = steer(target);
		if (multiplier != 1.0)
			steering.mult(multiplier);
		acceleration.add(steering);
	}

	function steer(target:Pt):PVector {
		steering.set(target);
		steering.sub(pos);
		var distance = steering.normalize();
		if (distance > 0.00001) {
			steering.mult(maxSpeed);
			steering.sub(velocity);
			if (steering.lengthSquared() > maxForceSquared) {
				steering.normalize();
				steering.mult(maxForce);
			}
		}
		return steering;
	}
}
