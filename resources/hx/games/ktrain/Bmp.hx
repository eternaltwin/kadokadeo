package ktrain;

import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;
import pixi.core.sprites.Sprite as PixiSprite;

/**
 * flash.display.BitmapData of a scene (SceneManager.makeNextScene: 300 x 300, opaque, black): the ground is drawn into
 * it, then the pebbles, flowers, signs and corpses pasted by the code (SceneManager.paste) and the footprints of the
 * driver (drawOnScene). A render texture at 2 px per Flash pixel.
 *
 * BitmapData.draw(mc, matrix) draws the symbol on its current frame through the matrix alone (the clip's own
 * position, scale and alpha are not used): the draws are queued with the symbol, frame and translation and made
 * before the next picture (Flusher: KadoKadeo draws no picture during a seek), so the game code never waits for the GPU,
 * and a seek only draws the bitmaps still shown, once. Nothing of the gameplay reads these pixels.
 */
class Bmp {
	static var live:Array<Bmp> = [];
	// the frames of mcBg (a ground bitmap, flipped or not), drawn once at their resolution (1 px per Flash pixel) and
	// shown x2 without smoothing like the zoomed Flash player
	static var bgTex:Map<Int, RenderTexture> = new Map();

	public var width(default, null):Int;
	public var height(default, null):Int;

	var rt:RenderTexture;
	var sprite:PixiSprite;
	var queue:Array<Array<Dynamic>> = [];
	var disposed:Bool = false;

	public function new(w:Int, h:Int) {
		width = w;
		height = h;
		rt = (cast RenderTexture : Dynamic).create({width: w, height: h, resolution: Clip.K});
		queue.push(["fill"]);
		live.push(this);
	}

	// bmp.draw(mc, translation): the symbol `name` on frame `frame`
	public function draw(name:String, frame:Int, tx:Float, ty:Float) {
		if (!disposed)
			queue.push([name, frame, tx, ty]);
	}

	// (the scene is disposed and removed when it has gone down past the screen, but its clip is still shown until the
	// picture reaches its removal (MC ghosts): its pixels are freed when it leaves the screen)
	public function dispose() {
		if (disposed)
			return;
		disposed = true;
		queue = [];
		live.remove(this);
		if (sprite == null || sprite.parent == null)
			free();
	}

	function free() {
		if (rt == null)
			return;
		if (sprite != null)
			sprite.texture = Texture.EMPTY;
		rt.destroy(true);
		rt = null;
	}

	// attachBitmap: shown in an empty clip, at its origin
	public function attach(c:common_haxe_avm1.display.ASprite) {
		if (disposed || sprite != null)
			return;
		sprite = new PixiSprite(rt);
		c.addChild(sprite);
	}

	public function detach() {
		if (sprite != null && sprite.parent != null)
			sprite.parent.removeChild(sprite);
		if (disposed)
			free();
	}

	public static function flushAll() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		for (b in live)
			b.flush(renderer);
	}

	function flush(renderer:Dynamic) {
		if (queue.length == 0)
			return;
		var q = queue;
		queue = [];
		for (c in q) {
			if (c[0] == "fill") {
				var s = new PixiSprite(Texture.WHITE);
				s.tint = 0x000000;
				s.width = width;
				s.height = height;
				renderer.render(s, {renderTexture: rt, clear: true});
				s.destroy();
				continue;
			}
			var name:String = c[0];
			var frame:Int = c[1];
			if (name == "mcBg") {
				var s = new PixiSprite(bg(renderer, frame));
				s.position.set(c[2], c[3]);
				renderer.render(s, {renderTexture: rt, clear: false});
				s.destroy();
				continue;
			}
			var cl = new Clip(name);
			cl.gotoAndStop(frame);
			Clip.runLater();
			cl._x = c[2];
			cl._y = c[3];
			cl.updateState();
			cl.updateGraphics(1);
			renderer.render(cl, {renderTexture: rt, clear: false});
			cl.destroy({children: true});
		}
	}

	static function bg(renderer:Dynamic, frame:Int):RenderTexture {
		var t = bgTex.get(frame);
		if (t != null)
			return t;
		t = (cast RenderTexture : Dynamic).create({width: 300, height: 300, resolution: 1});
		untyped t.baseTexture.scaleMode = 0; // PIXI.SCALE_MODES.NEAREST
		var cl = new Clip(Data.BG_FRAMES[frame - 1]);
		cl._x = 150;
		cl._y = 150;
		if (Data.BG_FLIP[frame - 1])
			cl._yscale = -100;
		cl.updateState();
		cl.updateGraphics(1);
		renderer.render(cl, {renderTexture: t, clear: true});
		cl.destroy({children: true});
		bgTex.set(frame, t);
		return t;
	}

	// a new game: the bitmaps of the last one are gone (the ground frames are kept)
	public static function reset() {
		for (b in live.copy())
			b.dispose();
		live = [];
	}
}

// on the stage of the game: the queued draws are made when PIXI prepares a picture (updateGraphics), not at each step
class Flusher extends common_haxe_avm1.display.ASprite {
	override public function updateGraphics(a:Float) {
		Bmp.flushAll();
		super.updateGraphics(a);
	}
}
