package ironchouquette;

class Wave {
	public var flLinear:Bool;

	public var bList:Array<Bads>;

	public var speed:Float;
	public var ecart:Float;

	public var score:Int;

	public var path:Array<Array<Int>>;
	public var pl:Array<Float>;

	public function new(id, sp:Float, fl) {
		flLinear = fl;
		// var c = ( 0.3 + 0.7*Cs.game.dif/10000 );
		// if(id==null)id = Std.random( int(Stykades.PATH.length*c) );
		// INIT PATH
		var mp = Stykades.PATH[id];
		path = new Array();
		for (i in 0...mp.length) {
			path[i] = mp[i].copy();
			path[i][0] = Std.int(path[i][0] * Cs.NEW_GEN_SCALE);
			path[i][1] = Std.int(path[i][1] * Cs.NEW_GEN_SCALE);
		}

		// if(Std.random(2)==0)flipPath();

		pl = [0];
		var dist:Float = 0;
		var x = path[0][0];
		var y = path[0][1];
		for (i in 1...path.length) {
			var p = path[i];
			var dx = p[0] - x;
			var dy = p[1] - y;
			dist += Math.sqrt(dx * dx + dy * dy);
			pl.push(dist);
			x = p[0];
			y = p[1];
		}

		//
		bList = new Array();
		speed = sp * Cs.NEW_GEN_SCALE;
		ecart = 30 * Cs.NEW_GEN_SCALE;
		//
		score = Cs.C500;
	}

	public function flipPath(n) {
		for (i in 0...path.length) {
			var a = path[i];
			var w = Cs.mcw * 0.5;
			// TODO: there was no Std.int before
			a[n] = Std.int(w - (a[n] - w));
		}
	}

	public function addBad(b) {
		b.way = -bList.length * ecart;
		b.waveIndex = bList.length;
		b.pathIndex = 0;
		bList.push(b);
		b.wave = this;
		b.bList.push(0);
		b.frict = 1;
		b.x = path[0][0];
		b.y = path[0][1];
		b.vx = 0;
		b.vy = 0;
	}

	public function addBads(f, max) {
		for (i in 0...max) {
			var b = f();
			addBad(b);
		}
	}
}
