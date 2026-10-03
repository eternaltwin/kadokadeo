package twinspirit;

class BadShot extends Phys {
	public var owner:Int;
	public var bsid:Int;

	var flDeath:Bool;
	var px:Null<Int>;
	var py:Null<Int>;

	public function new(mc:ASprite, owner:Int, bsid:Int) {
		this.owner = owner;
		this.bsid = bsid;
		super(mc);
		Game.me.shots.push(this);
		ray = 4;
		flDeath = false;
		if (owner == Game.me.robertId && bsid == Game.me.shotId) {
			setLabel(0xFF0000);
		}
	}

	override public function update() {
		super.update();
		updateGridPos();

		if (x < -ray || x > Cs.mcw + ray || y < -ray || y > Cs.mch + ray) {
			kill();
		}
	}

	public function setType(type:ShotType) {
		root.gotoAndStop(Type.enumIndex(type) + 1);
		switch (type) {
			case STVolt:
				root._rotation = Seed.randVfx() * 360;
				vr = (Seed.randVfx() * 2 - 1) * 15;
			default:
		}
	}

	override public function kill() {
		flDeath = true;
		removeFromGrid();
		Game.me.shots.remove(this);
		super.kill();
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

	function insertInGrid() {
		for (x in 0...3)
			for (y in 0...3)
				Game.me.shotCell(px + x - 1, py + y - 1).push(this);
	}

	function removeFromGrid() {
		if (px == null)
			return;
		for (x in 0...3)
			for (y in 0...3)
				Game.me.shotCell(px + x - 1, py + y - 1).remove(this);
	}
}
