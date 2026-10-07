package razor;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;

/**
 * The pictures of mcCommentAnim's smc (sprite 6), whose text fields show the variables fxComment sets on the clip:
 *  - smc (sprite 4), scaled by the code to fit the text: sprite 3 twice, its field showing `_txt` in Impact: a red copy
 *    at 50 % (smc) and a copy whose filters are an inner glow and a knockout outer glow (only the light outline
 *    around the letters is drawn: the inner glow never shows). One white picture of each text (anims "comment<i>",
 *    at 2 px per stage pixel once scaled), drawn tinted and through a knockout FlashGlow (Flash filters are in stage
 *    pixels: the outline keeps its size while the text zooms in);
 *  - _field: `_score` ("+" + comboScore) in Impact through the matrix of the field (anim "scoreGlyphs": one picture per
 *    glyph, pivot on its pen position), laid out like Flash's centred text field, with its white glow.
 * The pictures are in the pixels of sprite 6 (Clip.K per Flash pixel).
 */
class Comment {
	static inline var GLYPHS = "+0123456789";

	// fxComment: text i of Data.COMMENT_TEXTS, the score string, the _xscale / _yscale of mc.smc.smc (100 * ratio)
	public static function fill(mc:MC, i:Int, score:String, ratio:Float) {
		var smc = mc.sub("smc");
		if (smc == null)
			return;
		var tex = Tex.get("comment" + i)[0];
		var res = Data.COMMENT_RES[i];
		// sprite 4 (smc.smc): its matrix scale replaced by the code's
		var holder = new Container();
		holder.scale.set(ratio, ratio);
		var red = new PixiSprite(tex);
		red.anchor.copyFrom(tex.defaultAnchor);
		red.scale.set(1 / res, 1 / res);
		red.tint = Data.COMMENT_RED;
		red.alpha = Data.COMMENT_RED_ALPHA;
		holder.addChild(red);
		var ko = new PixiSprite(tex);
		ko.anchor.copyFrom(tex.defaultAnchor);
		ko.scale.set(1 / res, 1 / res);
		var k = Data.COMMENT_KNOCK;
		ko.filters = [new FlashGlow(k[0], k[1], k[2], Data.COMMENT_KNOCK_COLOR, 1, true)];
		holder.addChild(ko);
		smc.addChild(holder);
		smc.addChild(scoreField(score));
	}

	// _field: the glyphs of s on the first line of the centred field, mapped by its matrix
	static function scoreField(s:String):Container {
		var box = new Container();
		var glyphs = Tex.get("scoreGlyphs");
		var m = Data.SCORE_FIELD;
		var idx = [for (i in 0...s.length) GLYPHS.indexOf(s.charAt(i))];
		var width = 0.0;
		for (d in idx)
			if (d >= 0)
				width += Data.SCORE_ADV[d];
		var pen = Data.SCORE_X + (Data.SCORE_W - width) * 0.5;
		var y = Data.SCORE_BASE;
		for (d in idx) {
			if (d < 0)
				continue;
			var sp = new PixiSprite(glyphs[d]);
			sp.anchor.copyFrom(glyphs[d].defaultAnchor);
			sp.x = (m[0] * pen + m[2] * y + m[4]) * Clip.K;
			sp.y = (m[1] * pen + m[3] * y + m[5]) * Clip.K;
			box.addChild(sp);
			pen += Data.SCORE_ADV[d];
		}
		var g = Data.SCORE_GLOW;
		box.filters = [new FlashGlow(g[0], g[1], g[2], Data.SCORE_GLOW_COLOR)];
		return box;
	}
}
