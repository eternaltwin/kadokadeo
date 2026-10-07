package phagocytoz;

import common_haxe_avm1.display.ASprite;
import pixi.core.sprites.Sprite as PSprite;

// the text of a text field of the SWF written with the glyphs of its embedded font (anims "G<id>_<res>", pivot on the
// pen position of the baseline): no browser font, the same on every computer. Flash's layout of a single line: 2
// pixels of gutter, the first baseline at the top + 2 + the ascent, centred in the width without the gutters, the
// letter spacing of the field's format added after each glyph. The score is scaled up to x9 by the code: glyphs at
// several resolutions, the one that fits the size on the screen.
class Glyphs {
	public static function resFor(edit:Int, px:Float):Float {
		var E:Dynamic = Reflect.field(Data.get().edits, Std.string(edit));
		var gs:Array<Dynamic> = E.glyphs;
		for (g in gs)
			if ((g.res : Float) >= px * 0.9)
				return g.res;
		return gs[gs.length - 1].res;
	}

	public static function layout(v:ASprite, edit:Int, text:String, res:Float) {
		var E:Dynamic = Reflect.field(Data.get().edits, Std.string(edit));
		v.removeChildren();
		if (text == null)
			return;
		var anim:String = null;
		var gs:Array<Dynamic> = E.glyphs;
		for (g in gs)
			if (g.res == res)
				anim = g.anim;
		var chars:String = E.chars;
		var adv:Array<Float> = E.adv;
		var ls:Float = E.letterSpacing;
		var tex = Tex.get(anim);
		var b:Array<Float> = E.b;
		var idx = [for (i in 0...text.length) chars.indexOf(text.charAt(i))];
		var width = 0.0;
		for (d in idx)
			if (d >= 0)
				width += adv[d] + ls;
		var pen = b[0] + 2;
		if (E.align == "center")
			pen += (b[1] - b[0] - 4 - width) / 2;
		else if (E.align == "right")
			pen += b[1] - b[0] - 4 - width;
		var base = b[2] + 2 + (E.ascent : Float);
		for (d in idx) {
			if (d < 0)
				continue;
			var s = new PSprite(tex[d]);
			s.anchor.copyFrom(tex[d].defaultAnchor);
			s.scale.set(1 / res, 1 / res);
			s.x = pen;
			s.y = base;
			v.addChild(s);
			pen += adv[d] + ls;
		}
	}
}
