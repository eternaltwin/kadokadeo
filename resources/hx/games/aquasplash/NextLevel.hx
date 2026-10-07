package aquasplash;

import pixi.filters.alpha.AlphaFilter;

/**
 * nextLevel (sprite 65, 59 frames over the whole board, removeMovieClip() on frame 59), played from the table of its
 * timeline (Data.NEXT_LEVEL): a gradient (62) drawn "add" under a grey colour transform (c * m + a: tinted by m,
 * plus a white square tinted a, both added), the levelburn clip (_burn: the plate 57 and the _field of the level
 * number, from frame 3) and the banner "Niveau" (64), both sliding in and out under a horizontal BlurFilter (blurred
 * pictures baked, Data). levelburn has filters: Flash composes it, then applies its alpha (MC.alphaFilter).
 */
class NextLevel extends MC {
	var bg:MC;
	var white:MC;
	var burn:MC;
	var plate:MC;
	var banner:MC;
	var field:TextField;
	var burnShown:Bool = false;

	public function new() {
		super();
		_totalframes = 59;
		playing = true;
		removeAt = 59;
		bg = attach(new MC("nlBg"));
		bg.setAdd();
		white = attach(new MC("white"));
		white.setAdd();
		// a 4 x 4 picture (2 x 2 Flash pixels) over the 300 x 300 square of the gradient
		white._xscale = white._yscale = 15000;
		burn = attach(new MC());
		burn.alphaFilter = new AlphaFilter(1);
		burn.spr.filters = [burn.alphaFilter];
		plate = burn.attach(new MC("nlPlate"));
		field = cast burn.attach(new TextField(Data.TEXT_LEVEL));
		banner = attach(new MC("nlBanner"));
		show(1);
	}

	// mcLevel._burn != null: levelburn is on the frame shown (frames 3-58) and the clip is still there
	public function hasBurn():Bool {
		return !removed && Data.NEXT_LEVEL[_currentframe - 1][1].length > 0;
	}

	// mcLevel._burn._field.text = s
	public function setText(s:String):Void {
		if (hasBurn())
			field.setText(s);
	}

	override function onFrame():Void {
		show(_currentframe);
	}

	function show(f:Int):Void {
		var row = Data.NEXT_LEVEL[f - 1];
		var g = row[0];
		bg._visible = g.length > 0;
		white._visible = g.length > 0 && g[4] > 0;
		if (g.length > 0) {
			bg._x = g[0];
			bg._y = g[1];
			bg._alpha = g[2] * 100;
			bg.tint = grey(g[3] * 255);
			white._x = g[0] - 150;
			white._y = g[1] - 150;
			white._alpha = g[2] * 100;
			white.tint = grey(g[4]);
		}
		var b = row[1];
		burn._visible = b.length > 0;
		if (b.length > 0) {
			if (!burnShown)
				burn.teleport(b[0], b[1]);
			burn._x = b[0];
			burn._y = b[1];
			burn._alpha = b[2] * 100;
			var v = Std.int(b[5]);
			setAnim(plate, v < 0 ? "nlPlate" : "nlPlate_B" + v, v < 0 ? 1 : Data.PLATE_BLUR_S[v]);
			field.setBlur(v);
		}
		burnShown = b.length > 0;
		var n = row[2];
		banner._visible = n.length > 0;
		if (n.length > 0) {
			banner._x = n[0];
			banner._y = n[1];
			banner._alpha = n[2] * 100;
			var v = Std.int(n[5]);
			setAnim(banner, v < 0 ? "nlBanner" : "nlBanner_B" + v, v < 0 ? 1 : Data.BANNER_BLUR_S[v]);
		}
	}

	static function setAnim(mc:MC, anim:String, sx:Float) {
		if (mc.anim != anim)
			mc.setFrames(anim);
		mc.texSx = sx;
	}

	static function grey(v:Float):Int {
		var c = Math.round(v);
		c = c < 0 ? 0 : c > 255 ? 255 : c;
		return c * 0x010101;
	}
}
