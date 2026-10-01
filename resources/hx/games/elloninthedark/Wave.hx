package elloninthedark;

class Wave {
	public static var PATH:Array<Array<Array<Int>>> = [
		[[330, 270], [205, 270], [205, 193], [281, 192], [280, 114], [-20, 115]],
		[
			[330, 27], [35, 25], [19, 32], [11, 46], [23, 60], [268, 131], [288, 145], [287, 161], [276, 172], [-24, 172]
		],
		[
			[330, 17], [291, 134], [249, 205], [204, 251], [135, 275], [64, 249], [23, 187], [22, 109], [68, 43], [142, 26], [206, 49], [248, 95],
			[289, 172], [326, 292]
		],
		[[333, 149], [197, 148], [95, 70], [96, 41], [116, 21], [141, 22], [157, 41], [156, 330]],
		[
			[306, 9], [229, 73], [171, 91], [132, 84], [107, 51], [118, 22], [151, 7], [191, 20], [202, 55], [202, 102], [187, 140], [149, 173],
			[79, 181], [42, 157], [36, 122], [60, 95], [95, 95], [121, 118], [120, 154], [117, 202], [120, 245], [145, 277], [178, 291], [221, 277],
			[277, 202], [322, 163]
		],
		[
			[351, 188], [215, 187], [142, 171], [113, 134], [114, 90], [142, 71], [175, 79], [196, 112], [227, 133], [260, 119], [268, 84], [258, 52],
			[227, 33], [172, 26], [114, 39], [72, 74], [54, 132], [64, 183], [94, 231], [143, 261], [208, 273], [355, 274]
		],
		[
			[-23, 17], [21, 17], [62, 25], [97, 50], [119, 88], [152, 109], [194, 109], [243, 108], [277, 121], [284, 143], [275, 168], [243, 184],
			[-16, 185]
		]
	];

	public var bList:Array<Bads>;

	public var speed:Float;
	public var ecart:Float;

	public var score:Int;

	public var path:Array<Array<Float>>;
	public var pl:Array<Float>;

	public function new(?id:Int) {
		var c = (0.3 + 0.7 * Cs.game.dif / 10000);
		if (id == null)
			id = Seed.random(Std.int(PATH.length * c));
		// INIT PATH (past dif 10000 the id can exceed the paths: like in Flash, the wave gets an empty path
		// and its drones vanish as soon as they move)
		var mp = id < PATH.length ? PATH[id] : [];
		path = new Array();
		for (i in 0...mp.length) {
			path[i] = [KadoKadeoManager.I(mp[i][0]), KadoKadeoManager.I(mp[i][1])];
		}
		if (Seed.random(2) == 0)
			flipPath();
		pl = [0];
		var dist = 0.0;
		var x = path.length > 0 ? path[0][0] : Math.NaN;
		var y = path.length > 0 ? path[0][1] : Math.NaN;
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
		speed = KadoKadeoManager.S(2);
		ecart = KadoKadeoManager.S(30);
		//
		score = Cs.C500;
	}

	public function flipPath() {
		for (i in 0...path.length) {
			var a = path[i];
			var h = (Cs.mch + Cs.MY) * 0.5;
			a[1] = h - (a[1] - h);
		}
	}

	public function addBads(b:Bads) {
		b.way = -bList.length * ecart;
		b.waveIndex = bList.length;
		b.pathIndex = 0;
		bList.push(b);
		b.wave = this;
		b.bList.push(0);
		b.frict = 1;
		if (path.length > 0) {
			b.x = path[0][0];
			b.y = path[0][1];
		} else {
			b.x = Math.NaN;
			b.y = Math.NaN;
			b.root._visible = false;
		}
	}
}
