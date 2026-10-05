package schizofuzz;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// arrow.txt of the original: the altitude ("12m") written with the glyphs of the Impact font embedded in the SWF
// (anim "digits": 0-9 then m, pivot on the pen position of the baseline), placed like Flash lays out the centred
// text field (Data.DIGITS_*): no browser font, the same on every computer
class Digits extends Container {
	static inline var GLYPHS = "0123456789m";

	// texture pixels of the parent clip per Flash pixel
	var ppu:Float;
	var glyphs:Array<Texture>;
	var text:String;

	public function new(ppu:Float) {
		super();
		this.ppu = ppu;
		glyphs = Tex.get("digits");
	}

	public function setText(s:String) {
		if (s == text)
			return;
		text = s;
		var idx = [for (i in 0...s.length) GLYPHS.indexOf(s.charAt(i))];
		var width = 0.0;
		for (d in idx)
			if (d >= 0)
				width += Data.DIGITS_ADV[d];
		var pen = Data.DIGITS_X + (Data.DIGITS_W - width) * 0.5;
		var n = 0;
		for (d in idx) {
			if (d < 0)
				continue;
			var sp:PixiSprite;
			if (n < children.length) {
				sp = cast children[n];
				sp.texture = glyphs[d];
				sp.visible = true;
			} else {
				sp = new PixiSprite(glyphs[d]);
				sp.anchor.copyFrom(glyphs[d].defaultAnchor);
				addChild(sp);
			}
			sp.scale.set(ppu / Clip.K, ppu / Clip.K * Data.DIGITS_SY);
			sp.x = pen * ppu;
			sp.y = Data.DIGITS_BASE * ppu;
			pen += Data.DIGITS_ADV[d];
			n++;
		}
		for (i in n...children.length)
			children[i].visible = false;
	}
}
