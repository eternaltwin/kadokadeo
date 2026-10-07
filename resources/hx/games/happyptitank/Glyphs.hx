package happyptitank;

import common_haxe_avm1.display.ASprite;
import pixi.core.sprites.Sprite as PSprite;

// the text of a text field of the SWF written with the glyphs of its embedded font (anim "G<id>", pivot on the pen
// position of the baseline): no browser font, the same on every computer. Flash's layout of a single line: 2 pixels
// of gutter, the first baseline at the top + 2 + the ascent, centred in the width without the gutters.
class Glyphs {
	public static function layout(v:ASprite, edit:Int, text:String) {
		var E:Dynamic = Reflect.field(Data.get().edits, Std.string(edit));
		var g:Dynamic = E.glyphs;
		v.removeChildren();
		if (g == null || text == null)
			return;
		var chars:String = g.chars;
		var adv:Array<Float> = g.adv;
		var tex = Tex.get("G" + edit);
		var b:Array<Float> = E.b;
		var idx = [for (i in 0...text.length) chars.indexOf(text.charAt(i))];
		var width = 0.0;
		for (d in idx)
			if (d >= 0)
				width += adv[d];
		var pen = b[0] + 2;
		if (E.align == "center")
			pen += (b[1] - b[0] - 4 - width) / 2;
		else if (E.align == "right")
			pen += b[1] - b[0] - 4 - width;
		var base = b[2] + 2 + (g.ascent : Float);
		var res:Float = g.res;
		for (d in idx) {
			if (d < 0)
				continue;
			var s = new PSprite(tex[d]);
			s.anchor.copyFrom(tex[d].defaultAnchor);
			s.scale.set(1 / res, 1 / res);
			s.x = pen;
			s.y = base;
			v.addChild(s);
			pen += adv[d];
		}
	}
}
