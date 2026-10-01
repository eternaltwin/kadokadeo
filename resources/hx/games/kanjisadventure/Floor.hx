package kanjisadventure;

import kanjisadventure.ent.Bad;

typedef Room = {rx:Int, ry:Int, dif:Int, stair:{x:Int, y:Int}};

class Floor {
	public static var DP_FX = 2;
	public static var DP_SQUARE = 1;
	public static var DP_GROUND = 0;

	var flTrader:Bool;

	public var id:Int;

	public var sx:Int;
	public var sy:Int;
	public var rsx:Int;
	public var rsy:Int;

	public var grid:Array<Array<Square>>;
	public var rooms:Array<Array<Room>>;

	public var ents:Array<Ent>;
	public var bads:Array<Bad>;

	public var root:ASprite;
	public var ground:ASprite;
	public var dm:DepthManager;

	// the layout of a floor only depends on the dungeon id
	public var seed:mt.Rand;

	public function new(id:Int) {
		this.id = id;
		root = Game.me.dm.empty(Game.DP_MAP);
		dm = new DepthManager(root);

		flTrader = false;
		ents = [];
		bads = [];

		sx = Std.int(Cs.XMAX * 0.5);
		sy = Std.int(Cs.YMAX * 0.5);

		genGrid();
		draw();

		for (e in ents) {
			e.display();
		}

		hide();
	}

	// GENERATION
	public function genGrid() {
		seed = new mt.Rand(Game.me.did + id);

		// GRID
		grid = [];
		for (x in 0...Cs.XMAX) {
			grid[x] = [];
			for (y in 0...Cs.YMAX) {
				grid[x][y] = new Square(x, y);
			}
		}

		var dfl = Game.me.floors[id - 1];

		// STAIR
		while (true) {
			rsx = seed.random(Cs.RX);
			rsy = seed.random(Cs.RY);
			if (id == 0 && rsx != 1 && rsy != 1)
				break;
			if (id != 0 && Math.abs(rsx - dfl.rsx) + Math.abs(rsy - dfl.rsy) >= 2)
				break;
		}

		// ROOMS
		rooms = [];
		for (rx in 0...Cs.RX) {
			rooms[rx] = [];
			for (ry in 0...Cs.RY) {
				genRoom(rx, ry);
			}
		}

		// CORRIDORS
		for (rx in 0...Cs.RX) {
			var x = Cs.WALL + rx * (Cs.RM * 2 + 1) + Cs.RM;
			var sy = Cs.WALL + Cs.RM;
			var ey = Cs.YMAX - sy;
			for (y in sy...ey) {
				var sq = grid[x][y];
				if (sq.type == WALL)
					sq.setType(GROUND);
			}
		}
		for (ry in 0...Cs.RY) {
			var y = Cs.WALL + ry * (Cs.RM * 2 + 1) + Cs.RM;
			var sx = Cs.WALL + Cs.RM;
			var ex = Cs.XMAX - sx;
			for (x in sx...ex) {
				var sq = grid[x][y];
				if (sq.type == WALL)
					sq.setType(GROUND);
			}
		}
	}

	public function genRoom(px:Int, py:Int) {
		var cx = getc(px);
		var cy = getc(py);

		var rx = 1 + seed.random(Cs.RM);
		var ry = 1 + seed.random(Cs.RM);

		var flStairUp = px == rsx && py == rsy;
		var flFirstRoom = px == 1 && py == 1 && id == 0;

		// COULOIR PROBA
		var flCorridor = seed.random(12) == 0 && !flStairUp && !flFirstRoom;
		if (flCorridor) {
			rx = 0;
			ry = 0;
		}

		if (flFirstRoom) {
			rx = 1;
			ry = 1;
		}

		// CHECK DOWN
		var dfl = Game.me.floors[id - 1];
		var underRoom = dfl != null ? dfl.rooms[px][py] : null;
		var underStair = underRoom != null && underRoom.stair != null;
		if (underStair) {
			rx = underRoom.rx;
			ry = underRoom.ry;
			var sq = grid[underRoom.stair.x][underRoom.stair.y];
			sq.setType(STAIR_DOWN);
		}

		var room:Room = {
			rx: rx,
			ry: ry,
			dif: 0,
			stair: null
		};
		rooms[px][py] = room;

		// DIG ROOM
		var list = [];
		for (x in 0...(rx * 2 + 1)) {
			for (y in 0...(ry * 2 + 1)) {
				var sq = grid[cx + x - rx][cy + y - ry];
				if (sq.type == WALL) {
					sq.setType(GROUND);
					list.push(sq);
				}
			}
		}

		if (flCorridor)
			return;

		// CLEAN CORRIDOR POS
		var list2 = list.copy();
		var i = 0;
		while (i < list2.length) {
			var sq = list2[i];
			if (sq.x == cx || sq.y == cy)
				list2.splice(i--, 1);
			i++;
		}
		if (list2.length == 0)
			return;

		// STAIR_UP
		if (flStairUp) {
			var index = seed.random(list2.length);
			var sq = list2[index];
			list2.splice(index, 1);

			sq.setType(STAIR_UP);
			sx = sq.x;
			sy = sq.y;
			room.stair = {x: sq.x, y: sq.y};
			list.remove(sq);
		}

		// MARCHAND
		if (list2.length > 0 && !flTrader) {
			if ((seed.random(36) == 0 && id > 0) || (Cs.FIRST_TRADER && flFirstRoom)) {
				flTrader = true;
				var trader = new kanjisadventure.ent.Trader();

				var index = seed.random(list2.length);
				var sq = list2[index];
				list2.splice(index, 1);

				trader.setFloor(this);
				trader.setPos(sq.x, sq.y);
				list.remove(sq);
			}
		}

		// MONSTER
		var dif = id + 1;
		var sum = 0;
		if (underStair || flFirstRoom || flCorridor || seed.random(12) == 0)
			dif = 0;
		while (sum < dif) {
			var bid = seed.random(dif - sum);
			if (bid > 7)
				bid = 7;
			sum += (bid + 1);

			var bad = new Bad(bid);
			var index = seed.random(list.length);
			var sq = list[index];
			list.splice(index, 1);

			bad.setFloor(this);
			bad.setPos(sq.x, sq.y);

			if (list.length == 0)
				break;
		}

		// TREASURE
		var max = 0;
		if (Seed.rand() * 2.5 > 1)
			max++;
		while (seed.random(10) == 0)
			max++;
		if (max > list.length)
			max = list.length;
		if (max > id + 1)
			max = id + 1;
		if (flFirstRoom)
			max = 0;
		for (i in 0...max) {
			var index = seed.random(list.length);
			var sq = list[index];
			list.splice(index, 1);
			var id = Cs.getRandomItem();
			sq.itemId = id;
			if (Cs.isUnique(id))
				Cs.PROBA_ITEMS[id] = 0;
		}
	}

	// DRAW
	public function draw() {
		ground = dm.empty(DP_GROUND);
		var g = ground.getGraphics();
		g.beginFill(Cs.COL_BG);
		g.drawRect(0, 0, Cs.XMAX * Cs.CS, Cs.YMAX * Cs.CS);
		g.endFill();
		for (y in 0...Cs.YMAX) {
			for (x in 0...Cs.XMAX) {
				grid[x][y].draw(this);
			}
		}
	}

	// TRACK
	public function buildTracks() {
		for (x in 0...Cs.XMAX) {
			for (y in 0...Cs.YMAX) {
				grid[x][y].heat = null;
			}
		}
		var ssq = Game.me.hero.sq;
		mark(ssq, 0, Game.me.huntMax);
	}

	public function mark(sq:Square, heat:Int, max:Int) {
		sq.heat = heat;
		if (heat == max)
			return;
		for (d in Cs.DIR) {
			var nsq = getSquare(sq.x + d[0], sq.y + d[1]);
			if (nsq != null && nsq.isFree() && (nsq.heat == null || nsq.heat > heat + 1)) {
				mark(nsq, heat + 1, max);
			}
		}
	}

	// a hidden floor leaves the display list: it is not updated with the shown one (faster replay seeking)
	var holder:ASprite;

	public function show() {
		if (root.parent == null && holder != null) {
			holder.addChild(root);
			root.swapDepths(root.getDepth());
		}
		root._visible = true;
	}

	public function hide() {
		root._visible = false;
		if (root.parent != null) {
			holder = cast root.parent;
			holder.removeChild(root);
		}
	}

	public inline function getSquare(x:Int, y:Int):Square {
		var col = grid[x];
		return col == null ? null : col[y];
	}

	public function getBad(x:Int, y:Int):Bad {
		var sq = getSquare(x, y);
		if (sq != null && sq.ent != null && sq.ent.flBad)
			return cast sq.ent;
		return null;
	}

	// SCROLL: the entity at the center of the screen
	public function scroll(ent:Ent, ?snap:Bool) {
		if (ent.root == null || ent.host == null)
			return;
		root._x = Cs.mcw * 0.5 - (ent.root._x + ent.host.root._x);
		root._y = Cs.mch * 0.5 - (ent.root._y + ent.host.root._y);
		if (snap)
			root.updateState();
	}

	public function getc(rx:Int) {
		return Cs.WALL + rx * (Cs.RM * 2 + 1) + Cs.RM;
	}
}
