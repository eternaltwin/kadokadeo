package hypercube;

import hypercube.Gfx.Cube;

// a cube of a piece: position in the piece, colour (+ 3: a special cube), sub frame (its neighbours), clip
typedef Cub = {
	var x:Int;
	var y:Int;
	var n:Int;
	var s:Null<Int>;
	var mc:Cube;
}

class Piece {
	public var dx:Float;
	public var dy:Float;

	public var list:Array<Cub>;

	public var root:MC;
	public var game:Game;

	public function new(mc:MC, lst:Array<Cub>) {
		root = mc;
		list = lst;
	}

	public function build(flExt:Bool) {
		var mg = new Array<Array<Bool>>();

		for (x in 0...Cs.SHAPE_VOLUME) {
			mg[x] = new Array();
			for (y in 0...Cs.SHAPE_VOLUME) {
				mg[x][y] = false;
			}
		}
		var xmax = 0.0;
		var ymax = 0.0;
		for (i in 0...list.length) {
			var o = list[i];
			mg[o.x][o.y] = true;
			xmax = Math.max(xmax, o.x);
			ymax = Math.max(ymax, o.y);
		}

		dx = (xmax * 0.5);
		dy = (ymax * 0.5);

		for (i in 0...list.length) {
			var o = list[i];
			// dm.attach("cube", 1): in the order of the list
			var mc:Cube = cast root.attach(new Cube());
			mc._x = (o.x - dx) * Game.SIZE;
			mc._y = (o.y - dy) * Game.SIZE;
			mc.gotoAndStop(o.n + 1);
			o.mc = mc;
			var frame = 1;
			for (n in 0...4) {
				var d = Game.DIR[n];
				var nx = o.x + d.x;
				var ny = o.y + d.y;
				// (mg[-1] / mg[4]: undefined in Flash, false)
				if (nx >= 0 && nx < Cs.SHAPE_VOLUME && ny >= 0 && ny < Cs.SHAPE_VOLUME && mg[nx][ny])
					frame += Std.int(Math.pow(2, n));
			}
			o.s = frame;
			mc.setSub(frame);

			if (flExt) {
				// var be = Std.attachMC(mc, "butExt", 1); be._alpha = 0
				mc.addExt();
			}
		}
	}

	public function destroy() {
		for (i in 0...list.length) {
			var cub = list[i];
			cub.s = null;
			cub.mc.removeMovieClip();
		}
	}

	public function sortList() {
		while (true) {
			var swap = false;
			for (i in 0...list.length - 1) {
				var a = list[i];
				var b = list[i + 1];
				if ((a.x + a.y) > (b.x + b.y)) {
					list[i + 1] = a;
					list[i] = b;
					swap = true;
				}
			}
			if (!swap)
				break;
		}
	}

	public function kill() {
		root.removeMovieClip();
	}

	// (particles: visual random)
	public function burst() {
		for (i in 0...list.length) {
			var o = list[i];
			for (n in 0...10) {
				var p = game.newPart("partLight");
				// (- dx outside of the product: as in the original)
				p._x = (root._x + (o.x - 0.5) * Game.SIZE) - dx;
				p._y = (root._y + (o.y - 0.5) * Game.SIZE) - dy;
				var a = Seed.randVfx() * 6.28;
				var sp = 0.1 + Seed.randVfx() * 1;
				p.vx = Math.cos(a) * sp;
				p.vy = Math.sin(a) * sp;
				p.t = 10 + Seed.randVfx() * 10;
				p.scale = 50 + Seed.randVfx() * 100;
				p._xscale = p.scale;
				p._yscale = p.scale;
				p.ft = 0;
			}
		}
	}
}
