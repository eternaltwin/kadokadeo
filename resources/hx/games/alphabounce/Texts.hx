package alphabounce;

import pixi.filters.blur.BlurFilter;

// text of a Flash field drawn with the glyphs of the font embedded in the SWF (centred fields)
class GlyphText extends ASprite {
	public function new(text:String, anim:String, chars:String, adv:Array<Float>, field:Array<Float>, ?glowColor:Null<Int>) {
		super();
		var x0 = field[0], w = field[1], top = field[2], ascent = field[3], sx = field[4], sy = field[5], space = field[6];
		var width = 0.0;
		for (i in 0...text.length) {
			var k = chars.indexOf(text.charAt(i));
			width += k >= 0 ? adv[k] : space;
		}
		var pen = x0 + (w - width * sx) / 2;
		var base = top + ascent * sy;
		var glows = new ASprite();
		addChild(glows);
		for (i in 0...text.length) {
			var k = chars.indexOf(text.charAt(i));
			if (k < 0) {
				pen += space * sx;
				continue;
			}
			if (glowColor != null) {
				var g = new Mc(anim + "Glow", false);
				g.gotoAndStop(k + 1);
				g.tint = glowColor;
				g._x = pen;
				g._y = base;
				g._xscale = sx * 100;
				g._yscale = sy * 100;
				glows.addChild(g);
			}
			var m = new Mc(anim, false);
			m.gotoAndStop(k + 1);
			m._x = pen;
			m._y = base;
			m._xscale = sx * 100;
			m._yscale = sy * 100;
			addChild(m);
			pen += adv[k] * sx;
		}
	}
}

// mcTitleLevel: a band and "NIVEAU n"
class TitleLevel extends ASprite {
	public var timer:Float;

	public function new(text:String) {
		super();
		addChild(new Mc("titleLevelBack", false));
		addChild(new GlyphText(text, "lvlGlyph", Data.LVL_CHARS, Data.LVL_ADV, Data.LVL_FIELD));
		timer = 0;
	}
}

// mcTitle: mcField (the name of an option with its glow; frames 1-3 shown, 4-5 hidden when it blinks), blurred by the
// code
class Title extends ASprite {
	public var bl:Float;
	public var t:Float;

	var field:Mc;
	var blink:Bool;
	var frame:Int;
	var blur:BlurFilter;

	public function new(id:Int, flBlink:Bool) {
		super();
		field = new Mc("title", false);
		field.gotoAndStop(id + 1);
		addChild(field);
		blink = flBlink;
		frame = 1;
	}

	// timeline of mcField
	public function advance() {
		if (!blink)
			return;
		frame = frame % 5 + 1;
		field._visible = frame <= 3;
	}

	public function setBlur(b:Float) {
		if (b <= 0) {
			filters = null;
			return;
		}
		if (blur == null) {
			blur = new BlurFilter();
			blur.blurY = 0;
		}
		blur.blurX = b * Game.K * 0.5;
		filters = [blur];
	}
}
