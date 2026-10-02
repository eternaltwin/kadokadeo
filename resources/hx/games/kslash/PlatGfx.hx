package kslash;

import pixi.core.math.shapes.Rectangle;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// look of a platform (mcPlat, frame 1 by day, 2 by night): the bitmap strip shown through the mask of (w - 38) px
// between the two corners; the part of the strip under the mask is a piece of its texture (no mask to draw)
class PlatGfx {
	public var root:ASprite;

	var strip:PixiSprite;
	var corner0:PixiSprite;
	var corner:PixiSprite;
	var stripTex:Texture;

	public function new(mc:ASprite) {
		root = mc;
		// depths of mcPlat: strip (3), left corner (9), right corner (11)
		strip = new PixiSprite(Texture.EMPTY);
		corner0 = new PixiSprite(Texture.EMPTY);
		corner = new PixiSprite(Texture.EMPTY);
		root.addChild(strip);
		root.addChild(corner0);
		root.addChild(corner);
	}

	// maskW: mask._xscale (w * SIZE - 38), frame: 1 day / 2 night
	public function set(maskW:Float, frame:Int) {
		var ct = Tex.get("platCorner" + frame + "_0")[0];
		var cpx = Clip.K * Clip.getDef("platCorner" + frame).r; // texture px per Flash px
		for (c in [corner0, corner]) {
			c.texture = ct;
			c.anchor.copyFrom(ct.defaultAnchor);
			c.scale.set(1 / cpx, 1 / cpx);
		}
		// left corner: the same symbol mirrored at x = 19; right corner: corner._x = mask._xscale + 19
		corner0.x = Data.PLAT_CORNER_X;
		corner0.scale.x = -1 / cpx;
		corner.x = maskW + 19;

		var src = Tex.get("platText" + frame + "_0")[0];
		var px = Clip.K * Clip.getDef("platText" + frame).r;
		var regX = src.defaultAnchor.x * src.orig.width - (src.trim != null ? src.trim.x : 0);
		var regY = src.defaultAnchor.y * src.orig.height - (src.trim != null ? src.trim.y : 0);
		// mask rectangle in the texture of the strip
		var x0 = Data.PLAT_MASK_X;
		var y0 = Data.PLAT_MASK_Y;
		var u0 = (x0 - Data.PLAT_TEXT_X) * px + regX;
		var u1 = (x0 + Math.max(0, maskW) - Data.PLAT_TEXT_X) * px + regX;
		var v0 = (y0 - Data.PLAT_TEXT_Y) * px + regY;
		var v1 = (y0 + Data.PLAT_MASK_H - Data.PLAT_TEXT_Y) * px + regY;
		var f = src.frame;
		var a = Math.max(0, Math.min(f.width, u0));
		var b = Math.max(0, Math.min(f.width, u1));
		var c = Math.max(0, Math.min(f.height, v0));
		var d = Math.max(0, Math.min(f.height, v1));
		if (stripTex != null)
			stripTex.destroy(false);
		stripTex = null;
		if (b - a < 0.5 || d - c < 0.5) {
			strip.visible = false;
			return;
		}
		stripTex = new Texture(src.baseTexture, new Rectangle(f.x + a, f.y + c, b - a, d - c));
		strip.texture = stripTex;
		strip.visible = true;
		strip.x = Data.PLAT_TEXT_X + (a - regX) / px;
		strip.y = Data.PLAT_TEXT_Y + (c - regY) / px;
		strip.scale.set(1 / px, 1 / px);
	}
}
