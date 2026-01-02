package mt.bumdum;

import common_haxe_avm1.display.ASprite;
import mt.bumdum.Lib;

class Sprite {
	static public var spriteList:Array<Sprite> = [];

	public var root:ASprite;

	public var scale(get, set):Float;
	public var x(get, set):Float;
	public var y(get, set):Float;

	public function new(root:ASprite) {
		this.root = root;
		root.obj = this;
		spriteList.push(this);

		if (this.root._x == 0 && this.root._y == 0) {
			this.root._x = -100;
			this.root._y = -100;
		}
		this.scale = 100;
	}

    public function get_x() {
        return this.root._x;
    }

    public function set_x(val:Float) {
        this.root._x = val;
        return val;
    }

    public function get_y() {
        return this.root._y;
    }

    public function set_y(val:Float) {
        this.root._y = val;
        return val;
    }

    public function get_scale() {
        return this.root._xscale;
    }

    public function set_scale(val:Float) {
        this.root._xscale = val;
        this.root._yscale = val;
        return val;
    }

	public function updatePos() {
		this.root._x = this.x;
		this.root._y = this.y;
	}

	public function update() {
		this.updatePos();
	}

	public function setScale(scale:Float) {
		this.scale = scale;
		this.root._xscale = scale;
		this.root._yscale = scale;
	}

	public function kill() {
		this.root.removeMovieClip();
		spriteList.remove(this);
	}

	public function getDist(point:Point) {
		var x = point.x - this.x;
		var y = point.y - this.y;
		return Math.sqrt(x * x + y * y);
	}

	public function toward(arg0:Point, amount:Float, arg2:Int = 1) {
		var v5 = arg0.x - this.x;
		var v6 = arg0.y - this.y;
		this.x += Num.mm(-arg2, v5 * amount, arg2);
		this.y += Num.mm(-arg2, v6 * amount, arg2);
	};

	public function getAng(point:Point) {
		return Math.atan2(point.y - this.y, point.x - this.x);
	}

	// {
}
