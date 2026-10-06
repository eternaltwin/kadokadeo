package judocommando;

import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

/**
 * A flash.display.BitmapData of the original at 1 px per Flash pixel (the level, the tower, the background tiles):
 * pictures drawn into a render texture (draw), rectangles cleared (fillRect with 0, an exploded square of the level).
 * Drawn on screen without smoothing, like the rest of the pixel art.
 * Nothing of the game reads it back.
 */
class Bitmap {
	public var tex(default, null):RenderTexture;

	var w:Int;
	var h:Int;
	var batch:Container;

	public function new(w:Int, h:Int, ?fill:Null<Int>) {
		this.w = w;
		this.h = h;
		tex = (cast RenderTexture : Dynamic).create({width: w, height: h, resolution: 1});
		untyped tex.baseTexture.scaleMode = 0; // PIXI.SCALE_MODES.NEAREST
		batch = new Container();
		if (fill != null) {
			var g = new Graphics();
			g.beginFill(fill);
			g.drawRect(0, 0, w, h);
			g.endFill();
			batch.addChild(g);
		}
	}

	// bmp.draw(mc, matrix): frame `frame` of the picture `anim` (pivot at the origin of the clip) at (x, y)
	public function draw(anim:String, frame:Int, x:Float, y:Float):Void {
		var t = Tex.get(anim)[frame - 1];
		var s = new PixiSprite(t);
		s.anchor.copyFrom(t.defaultAnchor);
		s.x = x;
		s.y = y;
		batch.addChild(s);
	}

	// the pictures drawn since the last flush, into the texture
	public function flush():Void {
		if (batch.children.length == 0)
			return;
		var r:Dynamic = KadoKadeoManager.kkm.renderer;
		if (r != null)
			r.render(batch, {renderTexture: tex, clear: false});
		for (c in batch.removeChildren())
			c.destroy();
	}

	// fillRect(rect, 0): the pixels of the rectangle cleared
	public function clearRect(x:Float, y:Float, rw:Float, rh:Float):Void {
		flush();
		var g = new Graphics();
		g.beginFill(0xFFFFFF);
		g.drawRect(x, y, rw, rh);
		g.endFill();
		g.blendMode = untyped PIXI.BLEND_MODES.ERASE;
		batch.addChild(g);
		flush();
	}

	// fillRect(rectangle, 0): everything cleared
	public function clear():Void {
		for (c in batch.removeChildren())
			c.destroy();
		var r:Dynamic = KadoKadeoManager.kkm.renderer;
		if (r != null) {
			var e = new Container();
			r.render(e, {renderTexture: tex, clear: true});
			e.destroy();
		}
	}

	public function dispose():Void {
		for (c in batch.removeChildren())
			c.destroy();
		tex.destroy(true);
	}
}
