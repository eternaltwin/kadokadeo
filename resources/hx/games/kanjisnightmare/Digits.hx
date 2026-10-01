package kanjisnightmare;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// layout of a text field of the original, in Flash pixels relative to its clip (written by tools/knight_data.py):
// anim: digits 0-9 (white glyphs, anim + "G": their black glow), adv: advance of each digit, x / w: left and width of
// the text area (inside the 2 px gutter), base: first baseline, center: centred text (left aligned otherwise)
typedef DigitsDef = {
	anim:String,
	adv:Array<Float>,
	x:Float,
	w:Float,
	base:Float,
	center:Bool
};

// number written with the digits of a font embedded in the SWF, placed like Flash lays out the text field: every
// glyph is an image whose pivot is its pen position on the baseline, the glows all drawn under the glyphs
class Digits extends Container {
	var def:DigitsDef;
	var ppu:Float;
	var snap:Bool;
	var glyphs:Array<Texture>;
	var glows:Array<Texture>;
	var glowLayer:Container;
	var glyphLayer:Container;
	var text:String;

	// ppu: units of the parent per Flash pixel
	public function new(def:DigitsDef, ?ppu:Float = 1) {
		super();
		this.def = def;
		this.ppu = ppu;
		// parent in texture pixels (a still interface clip): glyphs on whole pixels, like Flash draws its fields
		snap = ppu == Clip.K;
		glyphs = Tex.get(def.anim);
		glows = Tex.get(def.anim + "G");
		glowLayer = new Container();
		glyphLayer = new Container();
		addChild(glowLayer);
		addChild(glyphLayer);
	}

	public function setText(s:String) {
		if (s == text)
			return;
		text = s;
		var width = 0.0;
		for (i in 0...s.length)
			width += def.adv[s.charCodeAt(i) - 48];
		var pen = def.center ? def.x + (def.w - width) * 0.5 : def.x;
		var y = def.base * ppu;
		if (snap)
			y = Math.round(y);
		for (i in 0...s.length) {
			var d = s.charCodeAt(i) - 48;
			var x = pen * ppu;
			if (snap)
				x = Math.round(x);
			place(glowLayer, i, glows[d], x, y);
			place(glyphLayer, i, glyphs[d], x, y);
			pen += def.adv[d];
		}
		for (l in [glowLayer, glyphLayer])
			for (i in s.length...l.children.length)
				l.children[i].visible = false;
	}

	function place(layer:Container, i:Int, t:Texture, x:Float, y:Float) {
		var sp:PixiSprite;
		if (i < layer.children.length) {
			sp = cast layer.children[i];
			sp.texture = t;
			sp.visible = true;
		} else {
			sp = new PixiSprite(t);
			sp.anchor.copyFrom(t.defaultAnchor);
			sp.scale.set(ppu / Clip.K, ppu / Clip.K);
			layer.addChild(sp);
		}
		sp.x = x;
		sp.y = y;
	}
}
