package hexile;

import hexile.Data.DigitsDef;

// the text of a field of the original holding a number, written with the digits of the Impact font embedded in the
// SWF (one picture per digit, pivot on its pen position on the baseline: no browser font, the same on every
// computer), laid out like Flash: 2 px gutter, aligned left / right / centred in the field, first baseline at the
// ascent. The pictures carry the scale of the field's placement (Data, hexile_assets.py). The filters of the field
// are layers of pictures: every glyph's bottom layer first, the glyphs themselves last, as Flash draws the filters of
// a field under its whole text.
class Digits extends MC {
	var def:DigitsDef;
	var anims:Array<String>;
	var layers:Array<MC> = [];
	var text:String;

	// anims: the layers drawn, from the bottom (default: the filters of the field, then its glyphs)
	public function new(def:DigitsDef, ?anims:Array<String>) {
		super();
		this.def = def;
		this.anims = anims != null ? anims : [for (i in 0...def.layers) def.anim + "_L" + i];
		for (a in this.anims)
			layers.push(attach(new MC()));
	}

	public function setText(s:String):Void {
		if (s == text)
			return;
		text = s;
		var width = 0.0;
		for (i in 0...s.length)
			width += def.adv[s.charCodeAt(i) - 48];
		var pen0 = switch (def.align) {
			case "right": def.x1 - width;
			case "center": def.x0 + (def.x1 - def.x0 - width) * 0.5;
			default: def.x0;
		}
		for (k in 0...layers.length) {
			var layer = layers[k];
			var pen = pen0;
			for (i in 0...s.length) {
				var d = s.charCodeAt(i) - 48;
				var g = i < layer.children.length ? layer.children[i] : layer.attach(new MC(anims[k]));
				g.showNow = true;
				g._visible = true;
				g.gotoAndStop(d + 1);
				g.teleport(pen, def.base);
				pen += def.adv[d];
			}
			for (i in s.length...layer.children.length)
				layer.children[i]._visible = false;
		}
	}
}
