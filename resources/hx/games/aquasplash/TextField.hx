package aquasplash;

import aquasplash.Data.TextDef;

/**
 * A text field of the original (the level number of levelburn, the "x" + chain of the score), written with the
 * glyphs of the font embedded in the SWF (no browser font: the same on every computer). Each glyph picture carries the
 * matrix of the field's placement (both fields are skewed) and its pivot is the pen position on the baseline. Layout
 * like Flash: 2 px gutter, aligned in the field, first baseline at the ascent, the pen moving along the field's x axis
 * (the glyph of pen position p goes to M * (p, baseline)); a wordWrap field breaks a line too wide between two
 * characters. The filters of the field are layers of pictures: every glyph's bottom layer first, the glyphs themselves
 * last, as Flash draws the filters of a field under its whole text. setBlur: the BlurFilter of the clip holding the
 * field (nextLevel's slides): every glyph with its layers, blurred (Data: pictures kept narrower, drawn texSx wider).
 */
class TextField extends MC {
	var def:TextDef;
	var layers:Array<MC> = [];
	var blurLayer:MC;
	var text:String = "";
	var blur:Int = -1;

	public function new(def:TextDef) {
		super();
		this.def = def;
		for (k in 0...def.layers)
			layers.push(attach(new MC()));
		blurLayer = attach(new MC());
	}

	public function getText():String {
		return text;
	}

	public function setText(s:String):Void {
		if (s == text)
			return;
		text = s;
		layout();
	}

	// -1: no blur, else the blurred variant (Data.TEXT_LEVEL.blurS)
	public function setBlur(i:Int):Void {
		if (i == blur)
			return;
		blur = i;
		layout();
	}

	function layout():Void {
		// lines of [glyph index, pen x] in field units
		var lines:Array<Array<Array<Float>>> = [[]];
		var widths = [0.0];
		var avail = def.x1 - def.x0;
		for (i in 0...text.length) {
			var g = def.chars.indexOf(text.charAt(i));
			if (g < 0)
				continue;
			var adv = def.adv[g];
			var l = lines.length - 1;
			if (def.wrap && lines[l].length > 0 && widths[l] + adv > avail) {
				lines.push([]);
				widths.push(0);
				l++;
			}
			lines[l].push([g, widths[l]]);
			widths[l] += adv;
		}
		var m = def.m;
		var pos = [];
		for (l in 0...lines.length) {
			var pen0 = switch (def.align) {
				case "right": def.x1 - widths[l];
				case "center": def.x0 + (avail - widths[l]) * 0.5;
				default: def.x0;
			}
			var base = def.base + l * def.lineH;
			for (it in lines[l]) {
				var px = pen0 + it[1];
				pos.push([it[0], m[0] * px + m[2] * base + m[4], m[1] * px + m[3] * base + m[5]]);
			}
		}
		for (k in 0...layers.length)
			place(layers[k], blur < 0 ? pos : [], def.anim + "_L" + k, 1);
		place(blurLayer, blur >= 0 ? pos : [], def.anim + "_B" + blur, blur >= 0 ? def.blurS[blur] : 1);
	}

	function place(layer:MC, pos:Array<Array<Float>>, anim:String, sx:Float):Void {
		for (i in 0...pos.length) {
			var g = i < layer.children.length ? layer.children[i] : layer.attach(new MC(anim));
			if (g.anim != anim)
				g.setFrames(anim);
			g.texSx = sx;
			g.showNow = true;
			g._visible = true;
			g.gotoAndStop(Std.int(pos[i][0]) + 1);
			g.teleport(pos[i][1], pos[i][2]);
		}
		for (i in pos.length...layer.children.length)
			layer.children[i]._visible = false;
	}
}
