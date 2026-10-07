package hypercube;

// the symbols of gfx.swf the code attaches, as MC subclasses drawn with the pictures of hypercube_assets.py

// bg: the decor (stop() on its frame 1), ray (the stripes of the conveyor) and horloge (the time ring ha)
class Bg extends MC {
	public var ray:MC;
	public var horloge:MC;

	public function new() {
		super("bg", 1);
		ray = attachAt(new MC("ray", 1), 2);
		ray._x = Data.RAY_X;
		ray._y = Data.RAY_Y;
		ray._alpha = Data.RAY_ALPHA;
		horloge = attachAt(new MC(), 4);
		horloge._x = Data.HORLOGE_X;
		horloge._y = Data.HORLOGE_Y;
		horloge._xscale = horloge._yscale = Data.HORLOGE_SCALE;
		horloge._alpha = Data.HORLOGE_ALPHA;
		var ha = horloge.attach(new MC("ha", Data.HA_RES));
		ha.gotoAndStop(1);
	}

	public var ha(get, never):MC;

	inline function get_ha():MC {
		return horloge.children[0];
	}
}

// cube: sub (the 16 pictures of a cube, by its neighbours) under the colour of the cube's frame (1-3: green, yellow,
// cyan; 4-6: the same with cubLight, the blinking light of the special cubes). Cs.setPercentColor whitens the whole
// cube: Flash's colour transform c * m + offset is drawn as a tint m on the pictures plus a white silhouette of the sub
// added over them with alpha offset / 255 (exact: the light lies inside the sub)
class Cube extends MC {
	public var sub:MC;
	var light:MC;
	var white:MC;
	// the form the cube belongs to (put / checkSwap)
	public var form:Game.Form;
	// butExt attached: the bigger hit area of the cubes of the conveyor
	var ext:Bool = false;
	var mult:Float = 1;
	var offset:Int = 0;

	public function new() {
		super();
		setTimeline(8);
		sub = attachAt(new MC("cube0"), -16383);
		white = attachAt(new MC("cubeW"), 1000);
		white.add = true;
		white._visible = false;
		setSub(1);
	}

	override function goto(f:Int):Void {
		super.goto(f);
		// frames 7-8 (other pictures) are never shown: n + 1 <= 6
		var c = (_currentframe - 1) % 3;
		sub.setFrames("cube" + c);
		if (_currentframe >= 4 && light == null) {
			light = attachAt(new MC("cubLight"), -16381);
			light._x = Data.CUBLIGHT_X;
			light._y = Data.CUBLIGHT_Y;
			light.play();
		} else if (_currentframe < 4 && light != null) {
			light.removeMovieClip();
			light = null;
		}
		applyColor();
	}

	// sub.gotoAndStop(s)
	public function setSub(s:Int):Void {
		sub.gotoAndStop(s);
		white.gotoAndStop(s);
		updateHit();
	}

	// Std.attachMC(mc, "butExt", 1) (alpha 0: only its hit area)
	public function addExt():Void {
		ext = true;
		updateHit();
	}

	function updateHit():Void {
		hitRects = [Data.CUBE_HIT[sub._currentframe - 1]];
		if (ext)
			hitRects.push(Data.BUT_EXT);
	}

	override public function setColorTransform(m:Float, rb:Int, gb:Int, bb:Int):Void {
		// (only whitening: setPercentColor(mc, prc, 0xFFFFFF))
		mult = m;
		offset = rb;
		applyColor();
	}

	function applyColor():Void {
		var g = Math.round(255 * mult);
		if (g > 255)
			g = 255;
		var t = g << 16 | g << 8 | g;
		sub.tint = t;
		if (light != null)
			light.tint = t;
		white._visible = offset > 0;
		white._alpha = offset / 2.55;
	}
}

// the particles of Game.pList: {>MovieClip, vx, vy, ft, weight, frict, t, scale, flQueue}
class Part extends MC {
	public var vx:Float = 0;
	public var vy:Float = 0;
	public var ft:Null<Int>;
	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var t:Null<Float>;
	public var scale:Null<Float>;
	public var flQueue:Bool = false;
}

// partQueue: a line fading out over 21 frames; its frame 21 sets t = 0 (Game.updateParts removes it)
class Queue extends Part {
	var line:MC;

	public function new() {
		super();
		setTimeline(Data.QUEUE_ALPHA.length);
		line = attach(new MC("partQueue"));
		line._alpha = Data.QUEUE_ALPHA[0];
		playing = true;
		script = function(f) {
			line._alpha = Data.QUEUE_ALPHA[f - 1];
			if (f == _totalframes)
				t = 0;
		};
	}
}

// scoreSquare: bg (the dotted square, scaled to the square of cubes) and sf (the field showing _parent.score)
class ScoreSquare extends Part {
	public var bg:MC;
	public var sf:MC;
	public var score(default, set):Int;

	public function new() {
		super();
		sf = attachAt(new MC(), 3);
		sf._x = Data.SF_X;
		sf._y = Data.SF_Y;
	}

	// bg._xscale = bg._yscale = s (the big picture above 100 %)
	public function setBgScale(s:Float):Void {
		bg = attachAt(s > 100 ? new MC("squareBgBig", Game.K * Data.SQUARE_BIG / 100) : new MC("squareBg"), 1);
		bg._x = Data.SQUARE_BG_X;
		bg._y = Data.SQUARE_BG_Y;
		bg._xscale = bg._yscale = s;
	}

	// the text field (variable _parent.score): Arcade Classic digits, centred, laid out like Flash (2 px gutters,
	// first baseline at the ascent)
	function set_score(v:Int):Int {
		score = v;
		var s = Std.string(v);
		for (c in sf.children.copy())
			c.removeMovieClip();
		var width = 0.0;
		for (i in 0...s.length)
			width += Data.DIGIT_ADV[s.charCodeAt(i) - 48];
		var pen = Data.DIGIT_X0 + (Data.DIGIT_X1 - Data.DIGIT_X0 - width) * 0.5;
		for (i in 0...s.length) {
			var d = s.charCodeAt(i) - 48;
			var g = sf.attach(new MC("digit"));
			g.gotoAndStop(d + 1);
			g._x = pen;
			g._y = Data.DIGIT_BASE;
			pen += Data.DIGIT_ADV[d];
		}
		return v;
	}
}

// partRound: the ring of grid lines shown where a piece is put (removeMovieClip on its frame 12)
class Round extends MC {
	public function new() {
		super("partRound");
		setTimeline(Data.ROUND_FRAMES);
		playing = true;
		script = function(f) {
			if (f == Data.ROUND_FRAMES)
				removeMovieClip();
		};
	}
}

// mcScore: its score panel ("BICOLOR !" / "MONOCOLOR !") rises from the bottom right corner and goes down again;
// removeMovieClip on frame 22 (the hold of the archive's timeline is broken in the released SWF, hypercube_assets.py)
class ScorePanel extends MC {
	public var score:MC;

	public function new() {
		super();
		setTimeline(Data.SCORE_Y.length + 1);
		score = attach(new MC("scorePanel"));
		score._y = Data.SCORE_Y[0];
		playing = true;
		script = function(f) {
			if (f == _totalframes)
				removeMovieClip();
			else
				score._y = Data.SCORE_Y[f - 1];
		};
	}
}

// butEndGame: smc (a Flash Button: up, over and down pictures, see Buttons) and the text "Terminer la partie" whose
// alpha pulses (21 frames, looping)
class EndButton extends MC {
	public var smc:MC;
	var text:MC;

	public function new() {
		super();
		setTimeline(Data.END_TEXT_ALPHA.length);
		smc = attachAt(new MC("endButton"), 1);
		smc.gotoAndStop(1);
		smc.hitRects = [Data.END_HIT];
		smc.isButton = true;
		text = attachAt(new MC("endText"), 4);
		text._alpha = Data.END_TEXT_ALPHA[0];
		playing = true;
		script = function(f) {
			text._alpha = Data.END_TEXT_ALPHA[f - 1];
		};
	}
}
