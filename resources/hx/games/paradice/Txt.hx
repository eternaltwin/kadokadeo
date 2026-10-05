package paradice;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// layout of a text field of the original, in Flash pixels relative to its clip (written by paradice_data.py):
// anim: one glyph image per character of `chars`, adv: advance of each character, x / w: left and width of the text
// area (inside the 2 px gutter), base: first baseline, center: centred text (left aligned otherwise)
typedef TxtDef = {
	anim:String,
	chars:String,
	adv:Array<Float>,
	x:Float,
	w:Float,
	base:Float,
	center:Bool
};

// a one-line text field written with glyph images of its font (the SWF's embedded font, or the device font drawn
// once): placed like Flash lays out the field, the same on every computer (no browser font)
class Txt extends Container {
	public var textWidth(default, null):Float = 0;

	var def:TxtDef;
	var ppu:Float;
	var glyphs:Array<Texture>;
	var text:String;

	// ppu: units of the parent per Flash pixel
	public function new(def:TxtDef, ppu:Float) {
		super();
		this.def = def;
		this.ppu = ppu;
		glyphs = Tex.get(def.anim);
	}

	// field.textColor (white glyphs tinted)
	public function setColor(c:Int):Void {
		for (s in children)
			(cast s : PixiSprite).tint = c;
		tintColor = c;
	}

	var tintColor:Int = 0xFFFFFF;

	public function setText(s:String):Void {
		if (s == text)
			return;
		text = s;
		var idx = [for (i in 0...s.length) def.chars.indexOf(s.charAt(i))];
		var width = 0.0;
		for (k in idx)
			if (k >= 0)
				width += def.adv[k];
		textWidth = width;
		var pen = def.center ? def.x + (def.w - width) * 0.5 : def.x;
		var n = 0;
		for (k in idx) {
			if (k < 0)
				continue;
			var sp:PixiSprite;
			if (n < children.length) {
				sp = cast children[n];
				sp.texture = glyphs[k];
				sp.visible = true;
			} else {
				sp = new PixiSprite(glyphs[k]);
				sp.anchor.copyFrom(glyphs[k].defaultAnchor);
				sp.scale.set(ppu / Clip.K, ppu / Clip.K);
				sp.tint = tintColor;
				addChild(sp);
			}
			sp.x = pen * ppu;
			sp.y = def.base * ppu;
			pen += def.adv[k];
			n++;
		}
		for (i in n...children.length)
			children[i].visible = false;
	}
}
