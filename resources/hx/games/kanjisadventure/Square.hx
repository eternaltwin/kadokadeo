package kanjisadventure;

import pixi.core.textures.Texture;

class Square {
	public static var DP_FX = 4;
	public static var DP_ACTOR = 3;
	public static var DP_ITEM = 2;
	public static var DP_UFX = 1;
	public static var DP_DECOR = 0;

	public var ent:Ent;

	public var heat:Null<Int>;
	public var x:Int;
	public var y:Int;
	public var itemId:Null<Int>;
	public var mcItem:ASprite;

	public var type:SquareType;

	public var root:ASprite;
	public var dm:DepthManager;

	public function new(px:Int, py:Int, ?t:SquareType) {
		x = px;
		y = py;
		setType(t);
	}

	public function setType(t:SquareType) {
		if (t == null)
			t = WALL;
		type = t;
	}

	// the floor is drawn once: the brush of each square goes in the ground layer (clipped to its cell when the square
	// above is open, its upper part then goes in the square, over the actors of the row above)
	public function draw(floor:Floor) {
		var px = x * Cs.CS;
		var py = y * Cs.CS;

		root = floor.dm.empty(Floor.DP_SQUARE);
		root._x = px;
		root._y = py;
		dm = new DepthManager(root);

		var v = Data.TILE_GROUND;
		switch (type) {
			case WALL:
				var fr = 0;
				var n = 1;
				for (d in Cs.DIR) {
					var sq = floor.getSquare(x + d[0], y + d[1]);
					if (sq != null && sq.type != WALL)
						fr += n;
					n *= 2;
				}
				var list = Data.TILE_WALLS[fr];
				v = list[Seed.randomVfx(list.length)];
			case GROUND:
				var up = floor.getSquare(x, y - 1);
				v = up != null && up.type == WALL ? Data.TILE_GROUND_SHADE : Data.TILE_GROUND;
			case STAIR_UP:
				v = Data.TILE_STAIR_UP;
			case STAIR_DOWN:
				v = Data.TILE_STAIR_DOWN;
		}

		var up = floor.getSquare(x, y - 1);
		if (up != null && up.isDynamic()) {
			var cell = floor.ground.attachBitmap(Texture.from("tileCell/" + (v + 1) + ".png"));
			cell.x = px;
			cell.y = py;
			if (Data.TILE_OVER[v]) {
				var top = dm.empty(DP_DECOR);
				top.attachBitmap(Texture.from("tileTop/" + (v + 1) + ".png"));
			}
		} else {
			var full = floor.ground.attachBitmap(Texture.from("tileFull/" + (v + 1) + ".png"));
			full.x = px;
			full.y = py;
		}

		if (itemId != null)
			showItem();
	}

	// ITEM
	public function addItem(id:Int) {
		itemId = id;
	}

	public function showItem() {
		mcItem = dm.attach("mcItem", DP_ITEM);
		mcItem.gotoAndStop(itemId + 1);
	}

	public function removeItem() {
		itemId = null;
		if (mcItem != null)
			mcItem.removeMovieClip();
		mcItem = null;
	}

	// FX
	function part(name:String, dp:Int):mt.bumdum.Part {
		var p = new mt.bumdum.Part(dm.attach(name, dp));
		return p;
	}

	public function fxLight() {
		var max = 20;
		for (i in 0...max) {
			var dp = i / max > 0.5 ? DP_FX : DP_UFX;
			var p = part("partLight", dp);
			p.x = Cs.CS * Seed.randVfx();
			p.y = Cs.CS * (i / max);
			p.weight = -KadoKadeoManager.S(0.05 + Seed.randVfx() * 0.2);
			p.frict = 0.99;
			p.timer = 10 + Seed.randVfx() * 20;
			p.sleep = Seed.randVfx() * 2;
			p.root.loop = true;
			p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._visible = false;
			p.updatePos();
			Col.setPercentColor(p.root, 80, Col.objToCol(Col.getRainbow(Seed.randVfx())));
			p.root.blendMode = BlendModes.ADD;
		}
	}

	public function fxChaos() {
		fxLight();
	}

	public function fxFlame() {
		var mc = dm.attach("fxFlame", DP_FX);
		mc.removeOnFrame = 9;
		mc.play();
	}

	public function fxSmoke() {
		var max = 20;
		for (i in 0...max) {
			var dp = i / max > 0.5 ? DP_FX : DP_UFX;
			var sens = x < Cs.CS * 0.5 ? 1 : -1;
			var p = part("partSmoke", dp);
			p.root.gotoAndStop(sens == 1 ? 1 : 2);
			p.x = Cs.CS * Seed.randVfx();
			p.y = Cs.CS * (i / max) - KadoKadeoManager.S(Seed.randVfx() * 15);
			p.weight = -KadoKadeoManager.S(0.05 + Seed.randVfx() * 0.15);
			p.frict = 0.99;
			p.timer = 10 + Seed.randVfx() * 15;
			p.fadeType = 0;
			p.root._rotation = Seed.randVfx() * 360;
			p.vr = sens * (10 + Seed.randVfx() * 15);
			p.fr = 0.92;
			p.updatePos();
			p.root.updateState();
		}
	}

	public function fxSleep() {
		var mc = dm.attach("fxSleep", DP_FX);
		mc.removeOnFrame = 27;
		mc.play();
	}

	public function fxGem(col:Int) {
		var max = 20;
		for (i in 0...max) {
			var dp = i / max > 0.5 ? DP_FX : DP_UFX;
			var p = part("partGem", dp);
			p.x = Cs.CS * Seed.randVfx();
			p.y = Cs.CS * (i / max);
			p.weight = -KadoKadeoManager.S(0.05 + Seed.randVfx() * 0.2);
			p.frict = 0.99;
			p.timer = 10 + Seed.randVfx() * 30;
			p.sleep = Seed.randVfx() * 3;
			p.root.loop = true;
			p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._visible = false;
			p.root.blendMode = BlendModes.OVERLAY;
			Filt.glow(p.root, 4, 2, col);
			p.updatePos();
		}
	}

	// "partScore": the score pops (timeline of the text holder) and floats away
	public function fxScore(sc:Int) {
		new ScorePart(dm.empty(DP_FX), sc);
	}

	// TOOLS
	public function isGround() {
		return type == GROUND || type == STAIR_UP || type == STAIR_DOWN;
	}

	public function isDynamic() {
		return type != WALL;
	}

	public function isFree() {
		return type == GROUND && ent == null;
	}

	public function isHeroFree() {
		return isGround() && ent == null;
	}

	public function kill() {
		root.removeMovieClip();
	}
}

class ScorePart extends mt.bumdum.Phys {
	var holder:ASprite;
	var frame:Int;

	public function new(mc:ASprite, sc:Int) {
		super(mc);
		holder = root.createEmptyMovieClip("smc", 1);
		var t = Txt.make(KadoKadeoManager.S(Data.TEXT_SCORE[3]), Txt.IMPACT, "center", 0x000000, 5, false);
		t.y = KadoKadeoManager.S(Data.TEXT_SCORE[1]);
		t.text = Std.string(sc);
		holder.addChild(t);
		x = Cs.CS * 0.5;
		y = -KadoKadeoManager.S(5);
		weight = -KadoKadeoManager.S(0.05);
		frict = 0.95;
		timer = 30;
		setScale(80);
		frame = 0;
		showFrame();
		updatePos();
		root.updateState();
	}

	override function update() {
		if (frame < Data.SCORE.length - 1) {
			frame++;
			showFrame();
		}
		super.update();
	}

	function showFrame() {
		var r = Data.SCORE[frame];
		holder._x = KadoKadeoManager.S(r[0]);
		holder._y = KadoKadeoManager.S(r[1]);
		holder._xscale = r[2] * 100;
		holder._yscale = r[3] * 100;
	}
}
