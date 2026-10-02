package linea;

class Scrollable extends MC {
	public var created:Bool = false;
	public var ydiff:Float;

	public function new(linkage:String) {
		// mcBack is a bitmap: drawn at its native resolution
		super(linkage, 1);
		setSize(Data.BACK_W, Data.BACK_H);
	}
}

typedef Layer = {idx:Int, scroller:Array<Scrollable>, linkage:String, xSpeed:Float, verticalScrollEnabled:Bool, maxVScroll:Bool}

class Scroller {
	var dm:MC.Plans;
	var scroller:Array<Scrollable>;
	var width:Float;
	var height:Float;
	var depth:Int;
	var margin:Float;
	var gotInfo:Bool = false;
	var vscroll:Bool;
	var verticalScrollBlocked:Bool;
	var maxVScroll:Bool;
	var layers:Map<Int, Layer>;
	var cl:Int;

	// (its own DepthManager on the root in the original: its plane 1 is the game's DP_BG, which the game never uses)
	public function new(dm:MC.Plans, width:Int, height:Int) {
		cl = 0;
		layers = new Map();
		this.width = width;
		this.height = height;
		this.dm = dm;
	}

	public function addLayer(linkage:String, xSpeed:Float = 0.0, verticalScrollEnabled:Bool = false, maxVScroll:Bool = true) {
		layers.set(++cl, {idx: cl, scroller: new Array(), linkage: linkage, xSpeed: xSpeed, verticalScrollEnabled: verticalScrollEnabled, maxVScroll: maxVScroll});
		add(layers.get(cl), 0);
	}

	function add(layer:Layer, x:Float) {
		var m = dm.add(new Scrollable(layer.linkage), layer.idx);
		m._x = x;

		if (!gotInfo) {
			if (m._height >= height) {
				margin = ((m._height - height) / 2);
			} else {
				margin = ((height - m._height) / 2);
			}
			gotInfo = true;
		}

		m._y = -margin;
		m.ydiff = 0;
		layer.scroller.push(m);
	}

	public function update(xSpeed:Float, xMod:Float, ySpeed:Float) {
		if (xSpeed == 0 && ySpeed == 0)
			return;

		for (l in layers) {
			var scroller = l.scroller;
			// index loop on the length of the moment, like the original's for-in: after a removal the next
			// piece waits until the next frame
			var i = 0;
			while (i < scroller.length) {
				var s = scroller[i++];

				if (xSpeed != 0) {
					if (s._x <= 0 && !s.created) {
						add(l, s._x + s._width);
						s.created = true;
					}

					if (s._x + s._width <= 0) {
						scroller.remove(s);
						s.removeMovieClip();
					}
					s._x -= xSpeed + if (xMod < 0 && Math.abs(xMod) > xSpeed) 0 else xMod;
				}

				if (ySpeed == 0)
					continue;

				if (Math.abs(s.ydiff) < margin) {
					s._y -= ySpeed;
					s.ydiff += ySpeed;
					continue;
				}

				if (s.ydiff <= 0 && s.ydiff <= margin && ySpeed > 0) {
					if (s._y >= margin)
						continue;

					s._y -= ySpeed;
					s.ydiff += ySpeed;
					continue;
				}

				if (s.ydiff >= 0 && s.ydiff >= margin && ySpeed < 0 && s._y <= 0) {
					s._y -= ySpeed;
					s.ydiff += ySpeed;
					continue;
				}
			}
		}
	}

	public function clean() {
		for (l in layers)
			for (s in l.scroller)
				s.removeMovieClip();
		layers = new Map();
	}
}
