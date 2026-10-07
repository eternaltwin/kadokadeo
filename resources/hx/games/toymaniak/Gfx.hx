package toymaniak;

import pixi.core.graphics.Graphics;
import pixi.core.sprites.Sprite;

// The clips of gfx.swf the code attaches and drives, with the pictures of toymaniak_assets.py and the tables of Data.hx.

// toy (35): 23 frames, no frame script: one picture per frame (frames 12-16 keep the picture of 11, 17-23 have none)
// and the button "but" (alpha 0: never drawn; its rectangle is the hit area of the toys of the rails)
class ToyMC extends MC {
	public var but:MC;

	var pic:MC;

	public function new() {
		super();
		setTimeline(Data.TOY_FRAMES.length);
		but = attach(new MC());
		but.hitRects = [Data.BUT_RECT];
		pic = attach(new MC());
		frameChanged(0);
	}

	override function frameChanged(old:Int):Void {
		var f = Data.TOY_FRAMES[_currentframe - 1];
		if (f == null) {
			pic.setPicture(null, 1);
			return;
		}
		var n = Std.int(f[0]);
		pic.setPicture("toy" + n, Data.TOY_RES[n]);
		pic._x = f[1];
		pic._y = f[2];
		pic._xscale = f[3] * 100;
		pic._yscale = f[4] * 100;
		// (another picture: not slid from where the previous one was)
		pic.jump();
	}

	// getBounds(this): the button counts, invisible or not
	public function getBounds():{xMin:Float, xMax:Float, yMin:Float, yMax:Float} {
		var b = Data.TOY_BOUNDS[_currentframe - 1];
		return {xMin: b[0], xMax: b[1], yMin: b[2], yMax: b[3]};
	}
}

// a slot of the box (41): 23 frames ("fall" 2, "empty" 17; stop on 16, gotoAndStop(1) on 23). The bar and the toy
// (placed on frames 2-16) are moved by the timeline under the slot's mask (shape 38, a rounded square: a sprite mask)
class SlotMC extends MC {
	public static inline var FALL = 2;
	public static inline var EMPTY = 17;

	// Game: the type of the toy in the slot (-1: none)
	public var t:Int = 0;
	public var toy:ToyMC;

	var masked:MC;
	var bar:MC;

	public function new() {
		super();
		setTimeline(Data.SLOT_BAR.length);
		attach(new MC("slot"));
		var mask = new Sprite(Tex.get("slotMask")[0]);
		mask.anchor.copyFrom(mask.texture.defaultAnchor);
		mask.scale.set(1 / Game.K, 1 / Game.K);
		masked = attach(new MC());
		masked.spr.mask = mask;
		spr.addChild(mask);
		bar = masked.attach(new MC("slotBar"));
		bar._x = Data.SLOT_BAR_X;
		hitFn = hit;
		script = function(f) {
			if (f == 16)
				stop();
			else if (f == 23)
				gotoAndStop(1);
		};
		frameChanged(0);
	}

	override function frameChanged(old:Int):Void {
		var f = _currentframe - 1;
		bar._y = Data.SLOT_BAR[f];
		var ty = Data.SLOT_TOY[f];
		if (Math.isNaN(ty)) {
			if (toy != null) {
				toy.removeMovieClip();
				toy = null;
			}
			return;
		}
		if (toy == null) {
			// placed by the timeline: a new toy, which plays (no stop() in it) until the code stops it
			toy = masked.attach(new ToyMC());
			toy._x = Data.SLOT_TOY_X;
			toy.playing = true;
		}
		toy._y = ty;
	}

	// shape 37 (the slot itself: the bar and the toy only count inside the mask, which has the same outline)
	function hit(x:Float, y:Float):Bool {
		var r = Data.SLOT_HIT_RES;
		var row = Data.SLOT_HIT[Math.floor((y - Data.SLOT_HIT_Y) * r)];
		if (row == null)
			return false;
		var c = (x - Data.SLOT_HIT_X) * r;
		var i = 0;
		while (i < row.length) {
			if (c >= row[i] && c < row[i + 1])
				return true;
			i += 2;
		}
		return false;
	}
}

// box (42): the slots s1 (depth 2), s2 (14), s0 (26)
class BoxMC extends MC {
	public var s0:SlotMC;
	public var s1:SlotMC;
	public var s2:SlotMC;

	public function new() {
		super();
		attachAt(new MC("box"), 1);
		var s = [];
		for (i in 0...3) {
			var d = Data.SLOTS[i];
			var m = new SlotMC();
			m._x = d[0];
			m._y = d[1];
			attachAt(m, Std.int(d[2]));
			s.push(m);
		}
		s0 = s[0];
		s1 = s[1];
		s2 = s[2];
	}
}

// railFront (57), frame 1 (stop): the belt, the treads t0 / t1 (50: stopped by Rail on frames 1 and 2: the two
// pictures), the cruncher under the rectangle of shape 51 (a Graphics mask: drawn with the scissor test, no shader), the
// end of the rail
class RailFrontMC extends MC {
	public var t0:MC;
	public var t1:MC;
	public var cruncher:MC;

	public function new() {
		super();
		attach(new MC("front"));
		t0 = attach(new MC("tread0", 1));
		t0._x = Data.FRONT_T0[0];
		t0._y = Data.FRONT_T0[1];
		t1 = attach(new MC("tread1", 1));
		t1._x = Data.FRONT_T1[0];
		t1._y = Data.FRONT_T1[1];
		// (Rail sets them to int(-300 + delta % 8) and int(-308 - delta % 8): back by 8 px when they wrap)
		t0.wrapX = t1.wrapX = 8;
		var m = Data.FRONT_MASK;
		var mask = new Graphics();
		mask.beginFill(0xFFFFFF);
		mask.drawRect(m[0], m[2], m[1] - m[0], m[3] - m[2]);
		mask.endFill();
		var masked = attach(new MC());
		masked.spr.mask = mask;
		spr.addChild(mask);
		cruncher = masked.attach(new MC("cruncher"));
		cruncher._x = Data.FRONT_CRUNCHER[0];
		cruncher._y = Data.FRONT_CRUNCHER[1];
		attach(new MC("frontEnd"));
	}
}

// panel.green / panel.red (68 / 72): 10 frames, stop on 1, compt = 3 on 2, if (compt-- > 0) gotoAndPlay(3) on 10:
// played by Rail.active, they blink 4 times and stop
class Light extends MC {
	var compt:Float = Math.NaN;

	public function new(anim:String) {
		super(anim);
		script = function(f) {
			switch (f) {
				case 1:
					stop();
				case 2:
					compt = 3;
				case 10:
					if (compt-- > 0)
						gotoAndPlay(3);
			}
		};
	}
}

// panel.field: the counter (font Digital 15, white, left), its digits drawn with the glyphs of the SWF and tinted by
// textColor
class Counter extends MC {
	var digits:Array<MC> = [];

	public var text(default, set):String = "";
	public var textColor(default, set):Int = 0xFFFFFF;

	public function new() {
		super();
	}

	function set_text(s:String):String {
		text = s;
		var x = Data.DIGIT_X;
		for (i in 0...s.length) {
			var d = s.charCodeAt(i) - "0".code;
			var m = digits[i];
			if (m == null) {
				m = attach(new MC("digit"));
				m.tint = textColor;
				digits[i] = m;
			}
			m._visible = true;
			m.gotoAndStop(d + 1);
			m._x = x;
			m._y = Data.DIGIT_BASE;
			m.jump();
			x += Data.DIGIT_ADV[d];
		}
		for (i in s.length...digits.length)
			digits[i]._visible = false;
		return s;
	}

	function set_textColor(c:Int):Int {
		textColor = c;
		for (m in digits)
			m.tint = c;
		return c;
	}
}

// railBack (74): the machine and the panel (one picture), panel.field, panel.green, panel.red
class RailBackMC extends MC {
	public var field:Counter;
	public var green:Light;
	public var red:Light;

	public function new() {
		super();
		attach(new MC("back"));
		field = attach(new Counter());
		green = attach(new Light("green"));
		green._x = Data.GREEN[0];
		green._y = Data.GREEN[1];
		red = attach(new Light("red"));
		red._x = Data.RED[0];
		red._y = Data.RED[1];
	}
}
