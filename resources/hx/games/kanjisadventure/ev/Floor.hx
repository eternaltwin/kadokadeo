package kanjisadventure.ev;

typedef Pos = {x:Int, y:Int, t:Float};

// stairs: the screen is covered by growing black discs, the next floor is loaded, then growing holes reveal it
// (the original drew the discs in a bitmap, then erased them from a black layer with the "erase" blend mode)
class Floor extends Event {
	static var EC = 40;

	var bstep:Int;
	var endAnimCounter:Null<Int>;

	var lvl:Int;
	var mcFader:ASprite;
	var list:Array<Pos>;
	var cells:Array<Array<ASprite>>;

	public function new(inc:Int) {
		super();

		this.lvl = Game.me.cfl.id + inc;

		var etage = lvl + "ème étage";
		if (lvl == 0)
			etage = "rez-de-chaussée";
		if (lvl == 1)
			etage = "1er sous-sol";
		if (lvl == 2)
			etage = "2d sous-sol";
		Game.me.log("Vous " + ["grimpez", "descendez"][inc < 0 ? 0 : 1] + " les escaliers vers le " + etage);

		bstep = 0;
		spc = 0.035;

		mcFader = Game.me.dm.empty(Game.DP_FADER);
		buildList();
	}

	public function buildList() {
		var xmax = Math.ceil(300 / EC);
		var ymax = Math.ceil(300 / EC);

		list = [];
		cells = [];
		for (x in 0...xmax) {
			cells[x] = [];
			for (y in 0...ymax) {
				list.push({x: x, y: y, t: (x + y) * 1.0});
			}
		}
	}

	override function update() {
		super.update();

		switch (step) {
			case 0:
				var a = list.copy();
				for (p in a) {
					p.t -= 1;
					if (p.t < 0) {
						var mc:ASprite;
						if (bstep == 0) {
							// "mcFadeRound": a black disc grows, then stays
							mc = mcFader.attachMovie("fadeRound", "d", 1);
						} else {
							// the black square of the cell gets a growing hole
							cells[p.x][p.y].removeMovieClip();
							mc = mcFader.attachMovie("fadeHole", "d", 1);
						}
						mc.stopOnFrame = [mc._totalframes];
						mc._x = KadoKadeoManager.S((p.x + 0.5) * EC);
						mc._y = KadoKadeoManager.S((p.y + 0.5) * EC);
						mc.play();
						list.remove(p);
					}
				}
				if (a.length == 0) {
					if (endAnimCounter == null)
						endAnimCounter = 12;
					if (endAnimCounter-- == 0) {
						endAnimCounter = null;
						switch (bstep) {
							case 0:
								bstep++;
								coef = 0;
								// black layer made of one black square per cell
								mcFader.removeMovieClip();
								mcFader = Game.me.dm.empty(Game.DP_FADER);
								buildList();
								var size = KadoKadeoManager.S(EC);
								for (x in 0...cells.length) {
									for (y in 0...Math.ceil(300 / EC)) {
										var c = mcFader.createEmptyMovieClip("c", 0);
										var g = c.getGraphics();
										g.beginFill(0x000000);
										g.drawRect(-1, -1, size + 2, size + 2);
										g.endFill();
										c._x = x * size;
										c._y = y * size;
										cells[x][y] = c;
									}
								}

								Game.me.allies = [];
								for (ent in Game.me.cfl.ents) {
									if (ent.flGood && Game.me.hero != ent)
										Game.me.allies.push(ent);
								}
								Game.me.loadFloor(lvl);

							case 1:
								kill();
						}
					}
				}
		}
	}

	override function kill() {
		mcFader.removeMovieClip();
		super.kill();
	}
}
