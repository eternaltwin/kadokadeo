package kanjisadventure;

import pixi.core.graphics.Graphics;
import pixi.core.math.shapes.Rectangle;
import kanjisadventure.Protocol;
import mt.bumdum.Lib;
import mt.DepthManager;

class Square {
	public static var DP_FX = 4;
	public static var DP_ACTOR = 3;
	public static var DP_ITEM = 2;
	public static var DP_UFX = 1;
	public static var DP_DECOR = 0;

	public var ent:Ent;
	public var floor(default, null):Floor;

	public var rid:Int;
	public var heat:Int;
	public var x:Int;
	public var y:Int;
	public var itemId:Int;
	public var mcItem:ASprite;

	public var type:SquareType;

	var root:ASprite;
	var mcHeat:ASprite;

	public var dm:DepthManager;

	var text:RenderTexture;

	public function new(floor:Floor, px, py, ?t) {
		this.floor = floor;
		x = px;
		y = py;
		setType(t);
	}

	public function setHeat(n) {
		heat = n;
		if (n != null) {
			if (mcHeat == null) {
				mcHeat = dm.empty(DP_DECOR);
				mcHeat.getGraphics().beginFill(0xFF0000).drawRect(0, 0, Cs.CS, Cs.CS).endFill();
			}
			mcHeat._alpha = 60 - n * 5;
		} else {
			mcHeat.removeMovieClip();
			mcHeat = null;
		}
	}

	public function setType(t) {
		if (t == null)
			t = WALL;
		/*
			if(type!=null && type!=WALL ){
				trace("overlap"+Type.enumIndex(type));
				trace("z->"+Type.enumIndex(t));
			}
		 */
		type = t;
	}

	public function draw(floor:Floor) {
		// var tfText = "";
		floor.brush.ground._visible = false;
		floor.brush.shade._visible = false;
		floor.brush.wallLight._visible = false;
		for (w in floor.brush.walls) {
			w._visible = false;
		}
		floor.brush.stairup._visible = false;
		floor.brush.stairdown._visible = false;
		switch (type) {
			case GROUND:
				floor.brush.ground._visible = true;
				floor.brush.shade._visible = false;
				floor.brush.wallLight._visible = false;
				for (w in floor.brush.walls) {
					w._visible = false;
				}
				floor.brush.stairup._visible = false;
				floor.brush.stairdown._visible = false;
			case STAIR_UP:
				floor.brush.stairup._visible = true;
			case STAIR_DOWN:
				floor.brush.stairdown._visible = true;
			case _:
		}
		// var tf = floor.brush.initTextField("tf", {
		// 	font: 'Arial',
		// 	size: 18,
		// 	color: 0xFFFFFF,
		// 	align: 'left',
		// 	stroke: "#000000",
		// 	strokeThickness: 4,
		// 	x: 12,
		// 	y: 12,
		// });
		// POS
		var px = x * Cs.CS;
		var py = y * Cs.CS;
		var m = new Matrix();
		m.translate(px, py);

		// ROOT
		root = floor.dm.empty(Floor.DP_SQUARE);
		root._x = px;
		root._y = py;
		dm = new DepthManager(root);

		// BRUSH
		var br = floor.brush;

		switch (type) {
			case WALL:
				var fr = 1;
				var n = 1;
				for (d in Cs.DIR) {
					var sq = floor.grid[x + d[0]] != null ? floor.grid[x + d[0]][y + d[1]] : null;
					if (sq != null && sq.type != WALL)
						fr += n;
					n *= 2;
				}
				var wall = br.walls[fr - 1];
				// tfText = "W" + fr;
				wall._visible = true;
				//
				var fr2 = Seed.randomVfx(wall._totalframes) + 1;
				wall.gotoAndStop(fr2);
				//
				if (fr == 3) {
					br.wallLight._visible = true;
					var fr3 = Seed.randomVfx(br.wallLight._totalframes) + 1;
					br.wallLight.gotoAndStop(fr3);
				}
			case GROUND:
				if (floor.grid[x][y - 1].type == WALL)
					br.shade._visible = true;
				var fr = Seed.randomVfx(br.ground._totalframes) + 1;
				br.ground.gotoAndStop(fr);
			// tfText = "G" + fr;
			case STAIR_UP:
				br.stairup.gotoAndStop(1);
			// tfText = "UP";
			case STAIR_DOWN:
				br.stairdown.gotoAndStop(1);
				// tfText = "DOWN";
		}
		// tf.text = tfText;
		// UP
		var up = floor.grid[x][y - 1];
		if (up != null && up.isDynamic()) {
			//* DRAW ONLY UP PART
			var r = new Rectangle(px, py, Cs.CS, Cs.CS);
			floor.ground.draw(br, m, r);
			var b = br.getBounds();
			if (b.y < 0) {
				var h = Math.ceil(-b.y);
				text = RenderTexture.create(Cs.CS, h + KadoKadeoManager.I(15));
				var mt = new Matrix();
				mt.translate(0, h);
				text.draw(br, mt);
				var mc = dm.empty(DP_DECOR);
				mc.attachBitmap(text, 0);
				mc._y = -h;
				// Filt.glow(mc, 2, 1, 0xFFFFFF);
			}
		} else {
			floor.ground.draw(br, m);
		}

		// ITEM
		if (itemId != null)
			showItem();
	}

	// ITEM

	public function addItem(id) {
		if (itemId != null)
			trace("addItem ERROR");
		itemId = id;
	}

	public function showItem() {
		mcItem = dm.attach("mcItem", 1);
		mcItem.gotoAndStop(itemId + 1);
	}

	public function removeItem() {
		itemId = null;
		mcItem.removeMovieClip();
	}

	// FX
	public function fxLight() {
		var max = 20;
		for (i in 0...max) {
			var dp = DP_UFX;
			if (i / max > 0.5)
				dp = DP_FX;
			var p = new mt.bumdum.Part(dm.attach("partLight", dp));
			p.x = Cs.CS * Seed.randVfx();
			p.y = Cs.CS * (i / max);
			p.weight = KadoKadeoManager.S(-(0.05 + Seed.randVfx() * 0.2));
			p.frict = 0.99;
			p.timer = 10 + Seed.randVfx() * 20;
			p.sleep = Seed.randVfx() * 2;
			p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._visible = false;
			p.updatePos();

			// Filt.glow(p.root,5,1,0xFFFFFF);
			Col.setPercentColor(p.root, 80, Col.objToCol(Col.getRainbow(Seed.randVfx())));
			p.root.blendMode = BlendModes.ADD;
		}
	}

	public function fxFlame() {
		var mc = dm.attach("fxFlame", DP_FX);
		mc.play();
		mc.removeOnFrame = 9;
	}

	public function fxSmoke() {
		var max = 20;
		for (i in 0...max) {
			var dp = DP_UFX;
			if (i / max > 0.5)
				dp = DP_FX;
			var p = new mt.bumdum.Part(dm.attach("partSmoke", dp));
			p.x = Cs.CS * Seed.randVfx();
			p.y = Cs.CS * (i / max) - Seed.randVfx() * KadoKadeoManager.I(15);
			p.weight = KadoKadeoManager.S(-(0.05 + Seed.randVfx() * 0.15));
			p.frict = 0.99;
			p.timer = 10 + Seed.randVfx() * 15;
			p.fadeType = 0;
			var sens = x < Cs.CS * 0.5 ? 1 : -1;
			p.root._rotation = Seed.randVfx() * 360;
			p.vr = sens * (10 + Seed.randVfx() * 15);
			p.fr = 0.92;
			p.root._xscale = sens * 100;
			p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
			p.updatePos();
			// trace(p.root._visible);

			// Filt.glow(p.root,5,1,0xFFFFFF);
			// Col.setPercentColor(p.root,80,Col.objToCol(Col.getRainbow(Math.random())));
			// p.root.blendMode = "add";
		}
	}

	public function fxChaos() {
		fxLight();
		/*
			var max = 20;
			for( i in 0...max ){
				var dp = DP_UFX;
				if(i/max>0.5)dp = DP_FX;
				var p = new mt.bumdum.Part( dm.attach("partLight",dp) );
				p.x = Cs.CS*Math.random();
				p.y = Cs.CS*(i/max);
				p.weight = -(0.05+Math.random()*0.2);
				p.frict=  0.99;
				p.timer = 10+Math.random()*20;
				p.sleep = Math.random()*2;
				p.root.gotoAndPlay(Std.random(p.root._totalframes)+1);
				p.root._visible = false;
				p.updatePos();

				//Filt.glow(p.root,5,1,0xFFFFFF);
				Col.setPercentColor(p.root,80,Col.objToCol(Col.getRainbow(Math.random())));
				p.root.blendMode = "add";
			}
		 */
	}

	public function fxSleep() {
		var mc = dm.attach("fxSleep", DP_FX);
		mc.play();
		mc.removeOnFrame = mc._totalframes;
		Filt.glow(mc, KadoKadeoManager.I(2), 4, 0);
	}

	public function fxGem(col) {
		var max = 20;
		for (i in 0...max) {
			var dp = DP_UFX;
			if (i / max > 0.5)
				dp = DP_FX;
			var p = new mt.bumdum.Part(dm.attach("partGem", dp));
			// trace(p.root._visible);
			p.x = Cs.CS * Seed.randVfx();
			p.y = Cs.CS * (i / max);
			p.weight = KadoKadeoManager.S(-(0.05 + Seed.randVfx() * 0.2));
			p.frict = 0.99;
			p.timer = 10 + Seed.randVfx() * 30;
			p.sleep = Seed.randVfx() * 3;
			p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
			p.root._visible = false;
			p.root.blendMode = BlendModes.OVERLAY;
			Filt.glow(p.root, KadoKadeoManager.I(2), 2, col);
			p.updatePos();

			// Filt.glow(p.root,5,1,0xFFFFFF);
			// Col.setPercentColor(p.root,80,Col.objToCol(Col.getRainbow(Math.random())));
			// p.root.blendMode = "add";
		}
	}

	public function fxScore(sc) {
		var p = new mt.bumdum.Phys(dm.empty(DP_FX));
		p.root.anchor.x = 0.5;
		p.root.anchor.y = 0.5;
		var tf = p.root.initTextField("field", {
			font: "impact",
			size: 40,
			color: 0xFFFFFF,
			align: "center",
		});
		p.root._totalframes = 5;
		p.root.onFrame.set(1, () -> p.root._xscale = p.root._yscale = 19.4);
		p.root.onFrame.set(2, () -> p.root._xscale = p.root._yscale = 54.7);
		p.root.onFrame.set(3, () -> p.root._xscale = p.root._yscale = 80);
		p.root.onFrame.set(4, () -> p.root._xscale = p.root._yscale = 95.1);
		p.root.onFrame.set(5, () -> p.root._xscale = p.root._yscale = 100);
		p.root.play();
		p.x = Cs.CS * 0.5;
		p.y = KadoKadeoManager.I(-5);
		p.weight = KadoKadeoManager.S(-0.05);
		p.frict = 0.95;
		p.timer = 30;
		// p.fadeType = 0;
		Filt.glow(p.root, KadoKadeoManager.I(2), 4, 0);
		tf.text = sc;
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

	public function getNextDirectionTo(target:Square):Null<Int> {
		if (target == null || target == this || floor == null || target.floor != floor)
			return null;

		var width = floor.grid.length;
		var height = floor.grid[0].length;
		var size = width * height;
		var infinity = 0x3FFFFFFF;
		var distances = [for (i in 0...size) infinity];
		var firstDirections = [for (i in 0...size) -1];
		var visited = [for (i in 0...size) false];
		var open = [this];
		distances[x + y * width] = 0;

		while (open.length > 0) {
			var best = 0;
			for (i in 1...open.length) {
				var currentIndex = open[i].x + open[i].y * width;
				var bestIndex = open[best].x + open[best].y * width;
				if (distances[currentIndex] < distances[bestIndex])
					best = i;
			}

			var current = open.splice(best, 1)[0];
			var currentIndex = current.x + current.y * width;
			if (visited[currentIndex])
				continue;
			visited[currentIndex] = true;
			if (current == target)
				return firstDirections[currentIndex];

			for (direction in 0...Cs.DIR.length) {
				var delta = Cs.DIR[direction];
				var nx = current.x + delta[0];
				var ny = current.y + delta[1];
				if (nx < 0 || ny < 0 || nx >= width || ny >= height)
					continue;

				var next = floor.grid[nx][ny];
				if (next == target) {
					if (!next.isGround())
						continue;
				} else if (!next.isFree()) {
					continue;
				}

				var nextIndex = nx + ny * width;
				var nextDistance = distances[currentIndex] + 1;
				if (nextDistance >= distances[nextIndex])
					continue;

				if (distances[nextIndex] == infinity)
					open.push(next);
				distances[nextIndex] = nextDistance;
				firstDirections[nextIndex] = current == this ? direction : firstDirections[currentIndex];
			}
		}

		return null;
	}

	public function kill() {
		root.removeMovieClip();
		text.destroy();
	}
}
