package logico;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.filters.alpha.AlphaFilter;

// mcScore: its text field "field" (Impact embedded in the SWF, right aligned, GlowFilter black 5 x 5 strength 10)
// written with glyph images of that font (the same on every computer), the glow of each glyph under all the glyphs.
// Part fades the clip by its _alpha: Flash applies it to the field drawn with its filter, as one picture; PIXI would
// apply it to each glyph and glow (the glow seen through the glyphs): the alpha is given by a filter on the whole
// clip instead (the AlphaFilter shader of the shadows, already compiled)
class ScoreMC extends MC {
	var glows = new Container();
	var glyphs = new Container();
	var filter:AlphaFilter;

	public function new() {
		super();
		spr.addChild(glows);
		spr.addChild(glyphs);
		filter = new AlphaFilter(1);
	}

	// field.text = s
	public function setText(s:String):Void {
		glows.removeChildren();
		glyphs.removeChildren();
		var gt = Tex.get("glyph");
		var gg = Tex.get("glyphGlow");
		var idx = [for (i in 0...s.length) Data.SCORE_CHARS.indexOf(s.charAt(i))];
		var width = 0.0;
		for (k in idx)
			if (k >= 0)
				width += Data.SCORE_ADV[k];
		var pen = Data.SCORE_RIGHT - width;
		for (k in idx) {
			if (k < 0)
				continue;
			glows.addChild(glyph(gg[k], pen));
			glyphs.addChild(glyph(gt[k], pen));
			pen += Data.SCORE_ADV[k];
		}
	}

	function glyph(t:pixi.core.textures.Texture, pen:Float):PixiSprite {
		var sp = new PixiSprite(t);
		sp.anchor.copyFrom(t.defaultAnchor);
		sp.scale.set(1 / Game.K, 1 / Game.K);
		sp.x = pen;
		sp.y = Data.SCORE_BASE;
		return sp;
	}

	// (the alpha of the step: not interpolated between two steps)
	override function drawn(f:Float):Void {
		var a = spr._alpha;
		if (a < 100) {
			filter.alpha = a / 100;
			spr._alpha = 100;
			if (spr.filters == null || spr.filters.length == 0)
				spr.filters = [filter];
		} else if (spr.filters != null && spr.filters.length > 0) {
			spr.filters = null;
		}
	}
}
