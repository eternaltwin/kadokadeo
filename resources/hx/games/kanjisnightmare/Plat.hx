package kanjisnightmare;

import pixi.core.math.shapes.Rectangle;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// look of a platform (mcPlat): the bitmap strip shown through a mask of (w - 38) px between two corners;
// the strip stays in place in the world when the platform loses its left part
class PlatGfx {
	var root:ASprite;
	var corner:Clip;
	var strip:PixiSprite;
	var stripTex:Texture;

	public function new(root:ASprite) {
		this.root = root;
		var c0 = new Clip("platCorner");
		root.addChild(c0);
		c0._x = Data.PLAT_CORNER_X;
		c0._xscale = -100;
		strip = new PixiSprite(Texture.EMPTY);
		root.addChild(strip);
		corner = new Clip("platCorner");
		root.addChild(corner);
	}

	// w: width, textX: x of the strip origin (Flash: gfx.text._x)
	public function set(w:Float, textX:Float) {
		corner._x = w - 19;
		var src = Tex.get("platText_0")[0];
		var px = Clip.K * Clip.getDef("platText").r; // texture px per Flash px
		var regX = src.defaultAnchor.x * src.orig.width;
		var regY = src.defaultAnchor.y * src.orig.height;
		var trimX = src.trim != null ? src.trim.x : 0;
		var trimY = src.trim != null ? src.trim.y : 0;
		// visible part: the mask, from PLAT_MASK_X on (w - 38) px
		var x0 = Data.PLAT_MASK_X;
		var x1 = x0 + Math.max(0, w - 38);
		var u0 = (x0 - textX) * px + regX - trimX;
		var u1 = (x1 - textX) * px + regX - trimX;
		var f = src.frame;
		var a = Math.max(0, Math.min(f.width, u0));
		var b = Math.max(0, Math.min(f.width, u1));
		if (stripTex != null)
			stripTex.destroy(false);
		stripTex = null;
		if (b - a < 0.5) {
			strip.visible = false;
			return;
		}
		stripTex = new Texture(src.baseTexture, new Rectangle(f.x + a, f.y, b - a, f.height));
		strip.texture = stripTex;
		strip.visible = true;
		strip.x = x0 + (a - u0) / px;
		strip.y = Data.PLAT_TEXT_Y + (trimY - regY) / px;
		strip.scale.set(1 / px, 1 / px);
	}

	public function destroy() {
		if (stripTex != null)
			stripTex.destroy(false);
		stripTex = null;
	}
}

class Plat extends Sprite {
	public var w:Float;
	public var grap:Grap;

	var gfx:PlatGfx;
	var textX:Float;

	public function new(mc:ASprite) {
		Cs.game.platList.push(this);
		super(mc);
		textX = Data.PLAT_TEXT_X;
		gfx = new PlatGfx(mc);
	}

	public function setPlat(nx:Float, ny:Float, nw:Float) {
		var dx = nx - x;
		x = nx;
		y = ny;
		w = nw;
		textX -= dx;
		gfx.set(w, textX);
		updatePos();
		// the platform loses its left part: no interpolation of the move (the strip inside is not interpolated)
		root.updateState();
	}

	public function explode(sx:Float) {
		var flKill = false;
		var wx = sx - x;
		if (w - wx < 100) {
			flKill = true;
			wx = w;
		}
		// FX
		if (sx + Cs.game.map._x > 0) {
			// PARTS
			var i = 0;
			while (i < wx * 0.1) {
				var p = Cs.game.newPart("partDust");
				p.x = x + Seed.randVfx() * wx;
				p.y = y + Seed.randVfx() * 8;
				p.setScale(100 + Seed.randVfx() * 100);
				p.weight = 0.1 + Seed.randVfx() * 0.3;
				p.timer = 20 + Seed.randVfx() * 10;
				p.fadeType = 0;
				i++;
			}

			// PLAT: falling pieces
			var dig = wx;
			var xd = x;
			while (dig > 30) {
				var ww = Cs.mm(30, Seed.randVfx() * dig, 100);
				var p = new Part(Cs.game.mdm.empty(Game.DP_PLAT));
				p.x = xd + ww * 0.5;
				p.y = y + 5;
				var holder = p.root.createEmptyMovieClip("plat", 0);
				holder._x = -ww * 0.5;
				holder._y = -5;
				var g = new PlatGfx(holder);
				g.set(ww, Data.PLAT_TEXT_X);
				p.onKill = g.destroy;
				p.weight = 0.2 + Seed.randVfx() * 0.2;
				p.vr = (Seed.randomVfx(2) * 2 - 1) * (0.5 + Seed.randVfx() * (Math.max(4 - ww * 0.05, 0)));
				p.timer = 30 + Seed.randVfx() * 10;
				xd += ww;
				dig -= ww;
			}

			// MONS
			for (mons in Cs.game.mList.copy()) {
				if (mons.plat == this && (sx > mons.x || flKill))
					mons.initStep(2);
			}
			// GRAP
			if (grap != null) {
				if (sx > grap.x || flKill)
					Cs.game.hero.releaseGrap();
			}
		}

		if (flKill) {
			if (this == Cs.game.hero.plat)
				Cs.game.hero.initStep(Hero.FLY);
			kill();
		} else {
			setPlat(x + wx, y, w - wx);
		}
	}

	public function isOutX(tx:Float):Bool {
		return tx < x || tx > x + w;
	}

	override public function kill() {
		Cs.game.platList.remove(this);
		gfx.destroy();
		super.kill();
	}
}
