package cosmocrash;

// Shot.hx of the original: a shell of a vehicle, kept in the cells of Game.sgrid around it (Hero.checkShots)
class Shot extends Element {
	var flDeath:Bool;
	var timer:Int;

	var px:Null<Int>;
	var py:Null<Int>;

	public function new() {
		super(Game.me.dm.attach("mcShot", Game.DP_FX));
		timer = 200;
	}

	override function update() {
		if (timer-- < 0 || y < -10)
			kill();

		super.update();
		updateGridPos();
	}

	// GRID
	function updateGridPos() {
		if (flDeath)
			return;
		var npx = Cs.getPX(x);
		var npy = Cs.getPY(y);
		if (npx != px || npy != py) {
			removeFromGrid();
			px = npx;
			py = npy;
			insertInGrid();
		}
	}

	// (a cell out of the grid is undefined in Flash: push / remove on it do nothing)
	static inline function cell(gx:Null<Int>, gy:Null<Int>):Array<Shot> {
		var col = gx == null ? null : Game.me.sgrid[gx];
		return col == null || gy == null ? null : col[gy];
	}

	function insertInGrid() {
		for (x in 0...3) {
			for (y in 0...3) {
				var gx = px + x - 1;
				var gy = py + y - 1;
				if (gx < 0)
					gx += Cs.XMAX;
				if (gx >= Cs.XMAX)
					gx -= Cs.XMAX;

				var a = cell(gx, gy);
				if (a != null)
					a.push(this);
			}
		}
	}

	// (the column is not wrapped here, unlike insertInGrid: next to the end of the map, the shot stays in the cells of
	// the other end after its death, and can still hit the hero there)
	function removeFromGrid() {
		if (px == null || py == null)
			return;
		for (x in 0...3) {
			for (y in 0...3) {
				var gx = px + x - 1;
				var gy = py + y - 1;
				var a = gx < 0 ? null : cell(gx, gy);
				if (a != null)
					a.remove(this);
			}
		}
	}

	//
	override function kill() {
		super.kill();
		flDeath = true;
		removeFromGrid();
	}
}
