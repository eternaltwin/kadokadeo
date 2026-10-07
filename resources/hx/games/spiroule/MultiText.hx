package spiroule;

import pixi.core.sprites.Sprite as PixiSprite;

/**
 * mcMulti.smc's text field (variable _parent._val: "x" + combo): the glyphs of the Severina font embedded in the SWF
 * (white pictures, pivot on the pen position of the baseline), laid out like Flash lays out a centred field (2 px
 * gutter, first baseline at the ascent): no browser font. A child of the picture smc (Data.MULTI_SMC_K of its pixels
 * per Flash pixel).
 */
class MultiText extends ASprite {
	static inline var GLYPHS = "x0123456789";

	public function new(text:String) {
		super();
		var tex = Tex.get("multiDig");
		var k = Data.MULTI_SMC_K;
		var sc = k / (Clip.K * Data.MULTI_GLYPH_RES);
		var idx = [for (i in 0...text.length) GLYPHS.indexOf(text.charAt(i))];
		var width = 0.0;
		for (d in idx)
			if (d >= 0)
				width += Data.MULTI_ADV[d];
		var pen = Data.MULTI_X + (Data.MULTI_W - width) * 0.5;
		for (d in idx) {
			if (d < 0)
				continue;
			var sp = new PixiSprite(tex[d]);
			sp.anchor.copyFrom(tex[d].defaultAnchor);
			sp.scale.set(sc, sc);
			sp.x = pen * k;
			sp.y = Data.MULTI_BASE * k;
			addChild(sp);
			pen += Data.MULTI_ADV[d];
		}
	}
}
