package chakrebouddha;

import chakrebouddha.MC.FilterDef;
import pixi.core.math.Matrix;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

/**
 * mcLotus: its timeline (39 frames, played in a loop) places the lotus bitmap 6 times with a matrix each (two at
 * each size, turning): the matrices of the SWF (Data.LOTUS) applied to 6 pictures of the bitmap, which Flash drew
 * without smoothing.
 */
class Lotus extends MC {
	var parts:Array<PixiSprite> = [];

	public function new() {
		super();
		_totalframes = Data.LOTUS.length;
		playing = true;
		var t = Tex.get("lotus")[0];
		for (_ in 0...6) {
			var s = new PixiSprite(t);
			s.anchor.copyFrom(t.defaultAnchor);
			spr.addChild(s);
			parts.push(s);
		}
		showParts();
	}

	override function display(f:Float):Void {
		super.display(f);
		showParts();
	}

	function showParts():Void {
		var fr = Data.LOTUS[_currentframe - 1];
		for (i in 0...6) {
			var m = fr[i];
			parts[i].transform.setFromMatrix(new Matrix(m[0], m[1], m[2], m[3], m[4], m[5]));
		}
	}
}

/**
 * mcActive: frame 1 the select ring (its smc at 75 %, with a white GlowFilter of 8 in its timeline), frame 2 badselect.
 * The code scales it from 100 % to about 1100 %: the ring is drawn from the picture of the smallest resolution that
 * covers the scale shown (Data.RING_RES); the glow is in stage pixels, drawn at run time.
 */
class Active extends MC {
	public function new() {
		super("ring" + Data.RING_RES[0], Data.RING_RES[0]);
	}

	override function display(f:Float):Void {
		var need = Math.abs(_xscale) / 100 * FlashFilters.scale();
		var r = Data.RING_RES[Data.RING_RES.length - 1];
		for (x in Data.RING_RES)
			if (x >= need) {
				r = x;
				break;
			}
		if (r != res) {
			// the sprite scale is in units of the picture: the scale of the previous step, which the render
			// interpolates from, is put in the new ones (otherwise the ring shrinks or grows for a step)
			var p = spr._prevState;
			if (p != null) {
				p.xscale *= res / r;
				p.yscale *= res / r;
			}
			res = r;
			frames = Tex.get("ring" + r);
		}
		// (the filters of the timeline, not the code's)
		_filters = _currentframe == 1 ? [Glow(8, 1, 0xFFFFFF, 1)] : [];
		super.display(f);
	}
}

/**
 * A text field of Ginko 25, centred (mcPoints.text): the glyphs of the font embedded in the SWF laid out like Flash
 * (text area Data.POINTS_X0..X1, first baseline Data.POINTS_BASE, in the coordinates of mcPoints). `big`: the 0 and 5
 * drawn from bigger pictures (BonusAnim grows its 5000 up to about 900 %).
 */
class Txt extends MC {
	public var text(default, set):String = "";

	var big:Bool;
	var glyphs:Array<PixiSprite> = [];

	public function new(big:Bool) {
		super();
		this.big = big;
		// DropShadowFilter(0, 0, black, 1, 3, 3, 1, 3) of the field in the SWF
		filters = [Glow(3, 1, 0x000000, 3)];
	}

	function set_text(s:String):String {
		text = s;
		for (g in glyphs)
			g.destroy();
		glyphs = [];
		var width = 0.0;
		for (i in 0...s.length) {
			var k = Data.DIGIT_CHARS.indexOf(s.charAt(i));
			if (k >= 0)
				width += Data.DIGIT_ADV[k];
		}
		var pen = Data.POINTS_X0 + (Data.POINTS_X1 - Data.POINTS_X0 - width) / 2;
		for (i in 0...s.length) {
			var c = s.charAt(i);
			var k = Data.DIGIT_CHARS.indexOf(c);
			if (k < 0)
				continue;
			var b = big ? Data.DIGIT_BIG.indexOf(c) : -1;
			var t = b >= 0 ? Tex.get("digitbig")[b] : Tex.get("digit")[k];
			var r = b >= 0 ? Data.DIGIT_BIG_RES : Data.DIGIT_RES;
			var g = new PixiSprite(t);
			g.anchor.copyFrom(t.defaultAnchor);
			g.position.set(pen, Data.POINTS_BASE);
			g.scale.set(1 / r, 1 / r);
			spr.addChild(g);
			glyphs.push(g);
			pen += Data.DIGIT_ADV[k];
		}
		return s;
	}
}

// mcPoints: the field "text" (Txt)
class Points extends MC {
	public var text:Txt;

	public function new(big:Bool = false) {
		super();
		text = attach(new Txt(big));
	}
}

// mcBonus: the two static lines "SUPRA" "CHAKRA" (one picture), with the black GlowFilter of their fields
class Bonus extends MC {
	public function new() {
		super();
		var t = attach(new MC("bonustext", 4));
		t.filters = [Glow(3, 1, 0x000000, 3)];
	}
}

/**
 * mcBg: the dark Buddha (shape 77), then the lit Buddha (shape 79) under the mask "mask" (mcMask: a rectangle and the
 * edge mm1 with its dots, at y = -391; Game moves it down when the energy goes, up when it comes back).
 * The mask is drawn once into a texture (its rectangle and the picture maskedge), a sprite mask of the lit Buddha.
 */
class Energy extends MC {
	public var mask:MC;

	var maskTex:RenderTexture;

	public function new() {
		super();
		attach(new MC("bg", 1));
		mask = attach(new MC());
		mask._y = -391;
		var lit = attach(new MC("lit", 1));

		// the mask in its coordinates: x from MX0, y from 0, 2 pixels per Flash pixel
		var mx0 = -46.0;
		var edge = Tex.get("maskedge")[0];
		var my1 = Data.MASK_Y0 + edge.height / 2 + 1;
		var w = Math.ceil((346 - mx0) * 2);
		var h = Math.ceil(my1 * 2);
		maskTex = (cast RenderTexture : Dynamic).create({width: w, height: h});
		var holder = new pixi.core.display.Container();
		var r = new PixiSprite(Texture.WHITE);
		r.position.set((Data.MASK_RECT[0] - mx0) * 2, Data.MASK_RECT[2] * 2);
		r.width = (Data.MASK_RECT[1] - Data.MASK_RECT[0]) * 2;
		// down into the picture of the edge (which starts at MASK_Y0): no seam
		r.height = (Data.MASK_Y0 + 1 - Data.MASK_RECT[2]) * 2;
		holder.addChild(r);
		var e = new PixiSprite(edge);
		e.anchor.copyFrom(edge.defaultAnchor);
		e.position.set(-mx0 * 2, 0);
		holder.addChild(e);
		KadoKadeoManager.kkm.renderer.render(holder, cast {renderTexture: maskTex, clear: true});
		holder.destroy({children: true});

		var ms = new PixiSprite(maskTex);
		ms.position.set(mx0, 0);
		ms.scale.set(0.5, 0.5);
		mask.spr.addChild(ms);
		lit.spr.mask = ms;
	}

	override function onDestroy():Void {
		if (maskTex != null)
			maskTex.destroy(true);
		maskTex = null;
	}
}
