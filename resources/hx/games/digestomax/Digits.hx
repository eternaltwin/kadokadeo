package digestomax;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// partScore.smc's text field (variable _parent._score): the number written with the glyphs of the Impact font embedded
// in the SWF (anim "digits", pivot on the pen position of the baseline), placed like Flash lays out the centred text
// field (Data.DIGITS_*): no browser font, the same on every computer. A child of the smc picture, in its pixels
// (Data.DIGITS_SMC_RES), the glyphs drawn at Data.DIGITS_RES. White glyphs: tinted with the colour of the text (black,
// or Col.setPercentColor(smc.smc, 70, col) of Game.newScore).
class Digits extends Container {
	static inline var GLYPHS = "0123456789";

	var glyphs:Array<Texture>;
	var text:String;
	var colour:Int = 0x000000;

	public function new() {
		super();
		glyphs = Tex.get("digits");
	}

	public function setColour(c:Int) {
		colour = c;
		for (s in children)
			(cast s : PixiSprite).tint = c;
	}

	public function setText(s:String) {
		if (s == text)
			return;
		text = s;
		var ppu = Clip.K * Data.DIGITS_SMC_RES;
		var gs = Data.DIGITS_SMC_RES / Data.DIGITS_RES;
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
				sp.scale.set(gs, gs);
				sp.tint = colour;
				addChild(sp);
			}
			sp.x = pen * ppu;
			sp.y = Data.DIGITS_BASE * ppu;
			pen += Data.DIGITS_ADV[d];
			n++;
		}
		for (i in n...children.length)
			children[i].visible = false;
	}
}
