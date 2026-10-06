package klinkersurprise;

import pixi.core.Pixi.BlendModes;

/**
 * mcInter: the text field (LEVEL'nn, the embedded Larabiefont as one picture per glyph, laid out like Flash: 2 px
 * gutter, centred, first baseline at the ascent) and the two time bars b0 / b1 scaled by the code.
 * Game: mcInter.blendMode = "add" and Filt.glow(mcInter, 6, 1, 0xFFFFFF): the white glow of the whole clip drawn under
 * it at run time (FlashGlow: the bars change every frame), the result added to the scene.
 */
class Inter extends MC {
	public var b0:MC;
	public var b1:MC;

	var field:MC;
	var text:String;

	public function new() {
		super();
		field = attach(new MC());
		b0 = attach(new MC("bar"));
		b0._x = Data.B0[0];
		b0._y = Data.B0[1];
		b0._xscale = Data.B0[2] * 100;
		b1 = attach(new MC("bar"));
		b1._x = Data.B1[0];
		b1._y = Data.B1[1];
		b1._xscale = Data.B1[2] * 100;
		var glow = new FlashGlow(6, 6, 1, 0xFFFFFF);
		untyped glow.blendMode = BlendModes.ADD;
		spr.filters = [glow];
	}

	// field.text = s
	public function setText(s:String):Void {
		if (s == text)
			return;
		text = s;
		var width = 0.0;
		for (i in 0...s.length)
			width += Data.FIELD_ADV[Data.FIELD_CHARS.indexOf(s.charAt(i))];
		var pen = Data.FIELD_X0 + (Data.FIELD_X1 - Data.FIELD_X0 - width) * 0.5;
		for (i in 0...s.length) {
			var k = Data.FIELD_CHARS.indexOf(s.charAt(i));
			var g = i < field.children.length ? field.children[i] : field.attach(new MC("glyph"));
			g.showNow = true;
			g._visible = true;
			g.gotoAndStop(k + 1);
			g.teleport(pen, Data.FIELD_BASE);
			pen += Data.FIELD_ADV[k];
		}
		for (i in s.length...field.children.length)
			field.children[i]._visible = false;
	}

	// b0._xscale = b1._xscale = c * 100: b1 is placed mirrored (matrix a = -1), which Flash reads as a rotation of 180
	// degrees with _yscale -100: setting _xscale keeps it mirrored
	public function setBars(c:Float):Void {
		b0._xscale = c * 100 * Data.B0[2];
		b1._xscale = c * 100 * Data.B1[2];
	}
}
