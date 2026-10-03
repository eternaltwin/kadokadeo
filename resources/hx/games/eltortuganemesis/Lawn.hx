package eltortuganemesis;

import eltortuganemesis.Cs;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

// MyGrass: the lawn, a blade of grass every 4 px (wild grass, grass mown slow / fast, border), drawn again after
// each cut. The original draws 3 lines of blades per frame (the game waits for the end): the same number of frames
// here, the blades are drawn into a texture at the end, with the soft shadows of the lawn.
class Lawn {
	static inline var LINES_PER_FRAME = 3;
	static inline var STEP = 4;

	public static var view:PixiSprite;

	static var rts:Array<RenderTexture>;
	static var cur:Int;
	static var ready:Bool;
	static var seed:Null<Int>;
	static var line:Int;
	static var done:Bool;
	static var rnd:mt.Rand;
	static var holder:Container;
	static var pool:Array<PixiSprite>;
	static var tex:Map<String, Array<Texture>>;

	public static function init() {
		rts = [
			RenderTexture.create(Game.W * Game.K, Game.H * Game.K),
			RenderTexture.create(Game.W * Game.K, Game.H * Game.K)
		];
		cur = 0;
		ready = false;
		seed = null;
		line = 0;
		done = false;
		view = new PixiSprite(rts[0]);
		view.scale.set(1 / Game.K);
		view.visible = false;
		holder = new Container();
		pool = [];
		tex = new Map();
		for (k in ["wild", "fast", "slow", "border"])
			tex.set(k, Tex.get("grass_" + k));
	}

	public static function isReady():Bool {
		return ready;
	}

	public static function update(clear:Bool = false, newLevel:Bool = false):Bool {
		if (seed == null)
			seed = Seed.randomVfx(9999);
		if (clear) {
			if (newLevel)
				seed = Seed.randomVfx(9999);
			done = false;
			line = 0;
		}
		if (done)
			return true;
		line += LINES_PER_FRAME;
		var max = Std.int(Game.H / STEP) + 3;
		if (line < max)
			return false;
		done = true;
		build();
		return true;
	}

	static function build() {
		rnd = new mt.Rand(seed);
		holder.removeChildren();
		var bg = new Graphics();
		bg.beginFill(Colors.BORDER_GRASS_BG & 0xFFFFFF);
		bg.drawRect(0, 0, Game.W, Game.H);
		bg.endFill();
		var f = Game.field;
		bg.beginFill(Colors.GRASS_BG & 0xFFFFFF);
		bg.drawRect(f.x, f.y, f.width, f.height);
		bg.endFill();
		holder.addChild(bg);
		var used = 0;
		var lines = Std.int(Game.H / STEP) + 3;
		var cols = Std.int(Game.W / STEP) + 3;
		for (y in 0...lines) {
			for (x in 0...cols) {
				var rx = Std.int(x * STEP + rnd.rand() * STEP / 2);
				var ry = Std.int(y * STEP + rnd.rand() * STEP / 2);
				var c = Game.getPixel(rx, ry);
				var kind = "wild";
				if (c == 0 || c == Colors.OUTSIDE)
					kind = "border";
				else if (Colors.isConqueredSlow(c))
					kind = "slow";
				else if (Colors.isConqueredFast(c))
					kind = "fast";
				var list = tex.get(kind);
				var i = rnd.random(list.length);
				var w = switch (kind) {
					case "border": Data.GRASS_W_BORDER[i];
					case "slow": Data.GRASS_W_SLOW[i];
					case "fast": Data.GRASS_W_FAST[i];
					default: Data.GRASS_W_WILD[i];
				}
				if (used == pool.length)
					pool.push(new PixiSprite(list[i]));
				var s = pool[used++];
				s.texture = list[i];
				s.anchor.copyFrom(list[i].defaultAnchor);
				s.scale.set(1 / Game.K);
				// translate(rx + w / 2, ry - h) of the bitmap of the blade (its base at the middle of its bottom)
				s.position.set(rx + w, ry);
				holder.addChild(s);
			}
		}
		// shadows of the lawn (dark ellipses blurred)
		var shadow = Tex.get("shadow")[0];
		var nShad = 5 + rnd.random(7);
		for (i in 0...nShad) {
			var c = 0x1A1A00 | rnd.random(40);
			var w = 70 + 60 * rnd.rand();
			var h = 70 + 60 * rnd.rand();
			var rot = rnd.rand() * Math.PI;
			var tx = rnd.random(Game.W);
			var ty = rnd.random(Game.H);
			var s = new PixiSprite(shadow);
			s.anchor.set(0.5, 0.5);
			s.rotation = rot;
			// the blob image is a disc of 120 px in 200: scaled to the ellipse
			s.scale.set(w / 120 * 0.5, h / 120 * 0.5);
			var cosr = Math.cos(rot), sinr = Math.sin(rot);
			s.position.set(tx + cosr * w / 2 - sinr * h / 2, ty + sinr * w / 2 + cosr * h / 2);
			s.alpha = 0.18;
			holder.addChild(s);
		}
		cur = 1 - cur;
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		renderer.render(holder, {renderTexture: rts[cur], clear: true, transform: new Matrix(Game.K, 0, 0, Game.K, 0, 0)});
		holder.removeChildren();
		view.texture = rts[cur];
		view.visible = true;
		ready = true;
	}

	public static function destroy() {
		if (rts != null)
			for (r in rts)
				r.destroy(true);
		rts = null;
		for (s in pool)
			s.destroy();
		pool = [];
	}
}
