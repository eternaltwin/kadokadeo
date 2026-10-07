package memopsy;

// The clips of gfx.swf the code attaches and drives, with the pictures of memopsy_assets.py and the tables of Data.hx.

// card (25): 11 frames (1 the back, 2-11 the face with symbol 0-9), one picture each, no frame script; its shape is
// the hit area of the onPress button (rounded corners: a run-length mask)
class CardMC extends MC {
	public function new() {
		super("card");
		hitFn = hit;
	}

	// shape 2 (the back; the face has the same outline)
	static function hit(x:Float, y:Float):Bool {
		var r = Data.CARD_HIT_RES;
		var row = Data.CARD_HIT[Math.floor((y - Data.CARD_HIT_Y) * r)];
		if (row == null)
			return false;
		var c = (x - Data.CARD_HIT_X) * r;
		var i = 0;
		while (i < row.length) {
			if (c >= row[i] && c < row[i + 1])
				return true;
			i += 2;
		}
		return false;
	}
}

// flip (26): 9 frames moving two nested card clips, "back" (depth 1) squeezed away and "top" (depth 4, the face the
// code sets) growing in its place. No picture of its own: the timeline tables of Data.hx are replayed on two card
// clips (x, y, xscale, a grey multiplier as a tint, shown = the placement's alpha multiplier of 0 or 1). The code
// steps it with nextFrame() / prevFrame() (Card.main): one Flash frame each, interpolated by the display; a goto
// that jumps (gotoAndStop(_totalframes) on a fresh clip to hide a card) is never interpolated (MC `fresh` / jump).
class FlipMC extends MC {
	public var back:CardMC;
	public var top:CardMC;

	public function new() {
		super();
		setTimeline(Data.FLIP_FRAMES);
		back = attach(new CardMC());
		top = attach(new CardMC());
		applyFrame();
	}

	override function frameChanged(old:Int):Void {
		applyFrame();
	}

	function applyFrame():Void {
		apply(back, Data.FLIP_BACK[_currentframe - 1]);
		apply(top, Data.FLIP_TOP[_currentframe - 1]);
	}

	static function apply(c:CardMC, r:Array<Float>):Void {
		c._x = r[0];
		c._y = r[1];
		c._xscale = r[2] * 100;
		var m = Math.round(r[3] * 255);
		c.tint = (m << 16) | (m << 8) | m;
		c._visible = r[4] > 0;
	}
}

// good (32): the white flash over a found pair: plays its 5 pictures on its own, frame 6 is stop() +
// this.removeMovieClip() (never shown: the script runs before the display)
class GoodMC extends MC {
	public function new() {
		super("good");
		// an attached clip plays (the code never stops it)
		playing = true;
		script = function(f) {
			if (f == 6) {
				stop();
				removeMovieClip();
			}
		};
	}
}
